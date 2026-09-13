import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/runtime/core_notifier.dart';
import '../../settings/application/settings_notifier.dart';
import '../data/smart_connect_repository.dart';
import '../domain/smart_connect_models.dart';
import '../domain/smart_runtime_models.dart';
import 'smart_policy_notifier.dart';
export '../domain/smart_runtime_models.dart' show SmartBinding;

final smartRepositoryProvider = Provider<SmartConnectRepository>(
  (ref) => TargetSmartConnectRepository(
    ref.read(coreGatewayProvider),
    store: ref.read(smartPolicyStoreProvider),
  ),
);

class SmartConnectState {
  const SmartConnectState({
    this.snapshot = const SmartRuntimeSnapshot(),
    this.assessments = const {},
    this.evaluating = false,
    this.busy = false,
    this.error,
    this.message = '',
    this.activeService,
    this.logs = const [],
  });
  final SmartRuntimeSnapshot snapshot;
  final Map<String, SmartAssessment> assessments;
  final bool evaluating, busy;
  final String? error, activeService;
  final String message;
  final List<Map<String, Object>> logs;
  Map<String, SmartBinding> get bindings => snapshot.bindings;
  SmartConnectState copyWith({
    SmartRuntimeSnapshot? snapshot,
    Map<String, SmartAssessment>? assessments,
    bool? evaluating,
    bool? busy,
    String? error,
    bool clearError = false,
    String? message,
    String? activeService,
    List<Map<String, Object>>? logs,
  }) => SmartConnectState(
    snapshot: snapshot ?? this.snapshot,
    assessments: assessments ?? this.assessments,
    evaluating: evaluating ?? this.evaluating,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    message: message ?? this.message,
    activeService: activeService ?? this.activeService,
    logs: logs ?? this.logs,
  );
}

class SmartConnectNotifier extends Notifier<SmartConnectState> {
  SmartCancellation? _cancellation;
  StreamSubscription<void>? _events;
  bool _refreshing = false;
  bool _auditLoaded = false;
  bool _refreshAgain = false;
  int _epoch = 0;
  @override
  SmartConnectState build() {
    ref.onDispose(() {
      _epoch++;
      unawaited(_cancellation?.cancel());
      unawaited(_events?.cancel());
    });
    ref.listen(smartPoliciesProvider, (previous, next) {
      if (next.value == null) return;
      final policies = {for (final p in next.value!) p.id: p.revision};
      state = state.copyWith(
        assessments: {
          for (final e in state.assessments.entries)
            if (policies[e.key] == e.value.policy.revision) e.key: e.value,
        },
      );
    });
    return const SmartConnectState();
  }

  bool get enabled => ref.read(settingsProvider).settings.smartConnectEnabled;
  SmartConnectRepository get repository => ref.read(smartRepositoryProvider);

  /// Also used before core start: a failed flag save cannot revive owned routes
  /// while the persisted user setting says the feature is disabled.
  Future<void> prepareForStart() async {
    if (!enabled &&
        await ref.read(smartPolicyStoreProvider).hasManagedRuntime()) {
      await repository.disable();
    }
  }

  Future<void> initialize() async {
    try {
      await prepareForStart();
      if (enabled) await refresh();
    } on Object catch (error) {
      if (ref.mounted) state = state.copyWith(error: _safeError(error));
    }
  }

  Future<void> setEnabled(bool value) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (!value) {
        await cancel();
        // Keep the switch on if the core rejects disabling its routes.
        await repository.disable();
        final actual = await repository.load();
        state = state.copyWith(snapshot: actual);
        await _events?.cancel();
        _events = null;
      } else {
        final snapshot = await repository.load();
        state = state.copyWith(snapshot: snapshot);
      }
      ref
          .read(settingsProvider.notifier)
          .updateSettings((s) => s.copyWith(smartConnectEnabled: value));
      state = state.copyWith(
        message: value
            ? 'Enabled. Evaluate and apply a service explicitly.'
            : 'Smart service routes disabled. Normal proxy mode is active.',
        assessments: value ? null : {},
      );
      if (value) await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> refresh() async {
    if (!enabled) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        final snapshot = await repository.load();
        if (!_auditLoaded) {
          final logs = await ref.read(smartPolicyStoreProvider).loadAudit();
          if (ref.mounted) state = state.copyWith(logs: logs);
          _auditLoaded = true;
        }
        if (!ref.mounted || !enabled) return;
        state = state.copyWith(snapshot: snapshot, clearError: true);
        if (snapshot.eventsSupported && _events == null) {
          _events = repository.events().listen(
            (_) {
              unawaited(refresh());
            },
            onError: (Object error) {
              if (ref.mounted) {
                state = state.copyWith(
                  error: 'Runtime event stream failed; refresh to reconnect.',
                );
              }
              unawaited(_events?.cancel());
              _events = null;
            },
            onDone: () {
              _events = null;
            },
          );
        }
      } while (_refreshAgain);
    } on Object catch (error) {
      if (ref.mounted) state = state.copyWith(error: _safeError(error));
    } finally {
      _refreshing = false;
    }
  }

  Future<void> evaluate(SmartPolicy policy) async {
    if (!enabled || state.busy || state.evaluating) return;
    final cancellation = SmartCancellation();
    _cancellation = cancellation;
    final epoch = ++_epoch;
    state = state.copyWith(
      evaluating: true,
      activeService: policy.id,
      clearError: true,
      assessments: {...state.assessments}..remove(policy.id),
    );
    try {
      final assessment = await repository.evaluate(policy, cancellation);
      if (!ref.mounted || epoch != _epoch || !enabled) return;
      final latest = await ref.read(smartPoliciesProvider.future);
      if (!latest.any(
        (p) => p.id == policy.id && p.revision == policy.revision,
      )) {
        throw StateError('Policy changed; re-evaluate');
      }
      if (epoch != _epoch || !enabled) return;
      state = state.copyWith(
        assessments: {...state.assessments, policy.id: assessment},
        message: assessment.selection.reason,
      );
      await _log(
        'evaluation',
        policy.id,
        assessment.selection.succeeded ? 'ready' : 'no_candidate',
        details: {
          'selectedNode':
              assessment.selection.node?.id ??
              (assessment.selection.direct ? 'direct' : ''),
          'scores': assessment.selection.scores,
          'excluded': assessment.selection.excluded,
          'policyRevision': policy.revision,
          'poolRevision': assessment.poolRevision,
        },
      );
    } on Object catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = state.copyWith(error: _safeError(error));
      }
    } finally {
      if (ref.mounted && epoch == _epoch) {
        _cancellation = null;
        state = state.copyWith(evaluating: false);
      }
    }
  }

  Future<void> cancel() async {
    ++_epoch;
    await _cancellation?.cancel();
    _cancellation = null;
    if (ref.mounted) {
      state = state.copyWith(
        evaluating: false,
        message: 'Evaluation cancelled; existing bindings preserved.',
      );
    }
  }

  Future<void> apply(String policyId, {String? manualNodeId}) async {
    if (!enabled || state.busy || state.evaluating) return;
    final assessment = state.assessments[policyId];
    if (assessment == null) return;
    if (assessment.policy.selectionMode == SmartSelectionMode.manual &&
        manualNodeId == null) {
      state = state.copyWith(
        error: 'Choose a node explicitly for a manual policy.',
      );
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final policies = await ref.read(smartPoliciesProvider.future);
      if (!policies.any(
        (p) => p.id == policyId && p.revision == assessment.policy.revision,
      )) {
        throw StateError('Policy changed; re-evaluate');
      }
      await ref.read(smartPolicyStoreProvider).markManagedRuntime();
      await repository.apply(assessment, manualNodeId: manualNodeId);
      await refresh();
      await _log(
        'apply',
        policyId,
        'submitted',
        details: {
          'selectedNode':
              manualNodeId ?? assessment.selection.node?.id ?? 'direct',
          'policyRevision': assessment.policy.revision,
        },
      );
      state = state.copyWith(
        assessments: {...state.assessments}..remove(policyId),
        message:
            'Configuration saved. Effective status is reported by TargetLib; it is not a health guarantee.',
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> removePolicy(String policyId) async {
    if (state.busy || state.evaluating) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (state.bindings.containsKey(policyId)) {
        await repository.remove(policyId);
      }
      await ref.read(smartPoliciesProvider.notifier).removePolicy(policyId);
      state = state.copyWith(
        assessments: {...state.assessments}..remove(policyId),
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> _log(
    String action,
    String serviceId,
    String outcome, {
    Map<String, Object> details = const {},
  }) async {
    final rows = [
      ...state.logs,
      <String, Object>{
        'time': DateTime.now().toUtc().toIso8601String(),
        'action': action,
        'serviceId': serviceId,
        'outcome': outcome,
        ...details,
      },
    ];
    final retained = rows
        .skip(rows.length > 200 ? rows.length - 200 : 0)
        .toList();
    await ref.read(smartPolicyStoreProvider).saveAudit(retained);
    if (ref.mounted) state = state.copyWith(logs: retained);
  }

  String _safeError(Object error) => error
      .toString()
      .replaceAll(RegExp(r'https?://[^\s]+'), '[URL redacted]')
      .replaceAll(
        RegExp(r'bearer\s+\S+', caseSensitive: false),
        'Bearer [redacted]',
      );
}

final smartConnectProvider =
    NotifierProvider<SmartConnectNotifier, SmartConnectState>(
      SmartConnectNotifier.new,
    );
