import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/proxy_node.dart';
import '../../proxies/application/proxy_catalog.dart';
import '../data/smart_connect_repository.dart';
import '../domain/smart_connect_models.dart';
import '../domain/smart_runtime_models.dart';
import 'smart_policy_notifier.dart';
export '../domain/smart_runtime_models.dart' show SmartBinding;

final smartRepositoryProvider = Provider<SmartConnectRepository>(
  (ref) => SmartConnectRepository(ref.read(coreGatewayProvider)),
);

enum SmartConnectActivity { idle, evaluating, applying }

class SmartConnectState {
  const SmartConnectState({
    this.snapshot = const SmartRuntimeSnapshot(),
    this.assessments = const {},
    this.activity = SmartConnectActivity.idle,
    this.error,
    this.message = '',
    this.activeService,
    this.logs = const [],
  });
  final SmartRuntimeSnapshot snapshot;
  final Map<String, SmartAssessment> assessments;
  final SmartConnectActivity activity;
  final String? error, activeService;
  final String message;
  final List<Map<String, Object>> logs;

  Map<String, SmartBinding> get bindings => snapshot.bindings;
  bool get busy => activity != SmartConnectActivity.idle;
  bool get evaluating => activity == SmartConnectActivity.evaluating;

  SmartConnectState copyWith({
    SmartRuntimeSnapshot? snapshot,
    Map<String, SmartAssessment>? assessments,
    SmartConnectActivity? activity,
    String? error,
    bool clearError = false,
    String? message,
    String? activeService,
    List<Map<String, Object>>? logs,
  }) => SmartConnectState(
    snapshot: snapshot ?? this.snapshot,
    assessments: assessments ?? this.assessments,
    activity: activity ?? this.activity,
    error: clearError ? null : error ?? this.error,
    message: message ?? this.message,
    activeService: activeService ?? this.activeService,
    logs: logs ?? this.logs,
  );
}

class SmartConnectNotifier extends Notifier<SmartConnectState> {
  SmartCancellation? _cancellation;
  StreamSubscription<void>? _events;
  Future<void> _tail = Future.value();
  bool _auditLoaded = false;
  int _epoch = 0;

  @override
  SmartConnectState build() {
    ref.onDispose(() {
      _epoch++;
      _cancellation?.cancel();
      unawaited(_events?.cancel());
    });
    ref.listen(proxyCatalogProvider, (_, _) => unawaited(refresh()));
    ref.listen(smartPoliciesProvider, (previous, next) {
      if (previous?.value == next.value) return;
      ++_epoch;
      _cancellation?.cancel();
      _cancellation = null;
      state = state.copyWith(
        assessments: const {},
        activity: state.evaluating ? SmartConnectActivity.idle : state.activity,
      );
    });
    return const SmartConnectState();
  }

  SmartConnectRepository get repository => ref.read(smartRepositoryProvider);

  /// Serializes refreshes so a burst of runtime events cannot interleave reads.
  Future<void> refresh() {
    final task = _tail.then((_) => _refreshOnce());
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> _refreshOnce() async {
    try {
      final snapshot = await repository.load();
      if (!ref.mounted) return;
      state = state.copyWith(snapshot: snapshot, clearError: true);
      if (!_auditLoaded) {
        _auditLoaded = true;
        final logs = await ref.read(smartPolicyStoreProvider).loadAudit();
        if (ref.mounted) state = state.copyWith(logs: logs);
      }
      if (snapshot.eventsSupported && _events == null) {
        _events = repository.events().listen(
          (_) => unawaited(refresh()),
          onError: (Object _) {
            if (ref.mounted) {
              state = state.copyWith(
                error: 'Runtime event stream failed; refresh to reconnect.',
              );
            }
            unawaited(_events?.cancel());
            _events = null;
          },
          onDone: () => _events = null,
        );
      }
    } on Object catch (error) {
      if (ref.mounted) state = state.copyWith(error: _safeError(error));
    }
  }

  Future<void> evaluate(SmartPolicy policy) async {
    if (state.busy) return;
    final cancellation = SmartCancellation();
    _cancellation = cancellation;
    final epoch = ++_epoch;
    state = state.copyWith(
      activity: SmartConnectActivity.evaluating,
      activeService: policy.id,
      clearError: true,
      assessments: {...state.assessments}..remove(policy.id),
    );
    try {
      final assessment = await repository.evaluate(policy, cancellation);
      if (!ref.mounted || epoch != _epoch) return;
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
        state = state.copyWith(activity: SmartConnectActivity.idle);
      }
    }
  }

  /// Runs the common path users expect: find a node and apply it immediately.
  Future<void> connect(SmartPolicy policy) async {
    if (state.busy) return;
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      activeService: policy.id,
      clearError: true,
    );
    try {
      await repository.connectDefault(policy);
      state = state.copyWith(
        message:
            '${policy.name.isEmpty ? policy.id : policy.name} connected. Quality optimization runs when needed.',
        assessments: {...state.assessments}..remove(policy.id),
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<void> cancel() async {
    ++_epoch;
    _cancellation?.cancel();
    _cancellation = null;
    if (ref.mounted) {
      state = state.copyWith(
        activity: SmartConnectActivity.idle,
        message: 'Evaluation cancelled; existing bindings preserved.',
      );
    }
  }

  Future<void> apply(String policyId, {String? manualNodeId}) async {
    if (state.busy) return;
    final assessment = state.assessments[policyId];
    if (assessment == null) return;
    if (assessment.policy.selectionMode == SmartSelectionMode.manual &&
        manualNodeId == null) {
      state = state.copyWith(
        error: 'Choose a node explicitly for a manual policy.',
      );
      return;
    }
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      clearError: true,
    );
    try {
      await repository.apply(assessment, manualNodeId: manualNodeId);
      await _log(
        'apply',
        policyId,
        'submitted',
        details: {
          'selectedNode':
              manualNodeId ?? assessment.selection.node?.id ?? 'direct',
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
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<void> removePolicy(String policyId) async {
    if (state.busy) return;
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      clearError: true,
    );
    try {
      await repository.remove(policyId);
      await ref.read(smartPoliciesProvider.notifier).removePolicy(policyId);
      state = state.copyWith(
        assessments: {...state.assessments}..remove(policyId),
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<void> savePreference(String nodeId, NodePreference preference) async {
    await repository.setPreference(nodeId, preference);
    await refresh();
  }

  Future<void> selectNode(SmartPolicy policy, String nodeId) async {
    if (state.busy) return;
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      clearError: true,
    );
    try {
      await repository.forceNode(policy, nodeId);
      state = state.copyWith(
        message:
            '${policy.name.isEmpty ? policy.id : policy.name} now uses the selected node.',
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<void> selectDefault(String nodeId) async {
    if (state.busy) return;
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      clearError: true,
    );
    try {
      await repository.selectDefault(nodeId);
      ref.read(proxyCatalogProvider.notifier).selectNode('proxy', nodeId);
      state = state.copyWith(
        message: 'Default route now uses the selected node.',
      );
      await refresh();
    } on Object catch (error) {
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<void> applyRoute(SmartPolicy policy, {String? nodeId}) async {
    if (state.busy) return;
    final assessment = state.assessments[policy.id];
    state = state.copyWith(
      activity: SmartConnectActivity.applying,
      clearError: true,
    );
    SmartPolicy? previous;
    var saved = false;
    try {
      previous = (await ref.read(
        smartPoliciesProvider.future,
      )).where((item) => item.id == policy.id).firstOrNull;
      await ref.read(smartPoliciesProvider.notifier).savePolicy(policy);
      saved = true;
      await repository.applyRoute(
        policy,
        nodeId: nodeId,
        assessment: assessment,
      );
      state = state.copyWith(
        assessments: {...state.assessments}..remove(policy.id),
        message:
            '${policy.name.isEmpty ? policy.id : policy.name} route saved.',
      );
      await refresh();
    } on Object catch (error) {
      if (saved && previous != null) {
        await ref.read(smartPoliciesProvider.notifier).savePolicy(previous);
      }
      await refresh();
      state = state.copyWith(error: _safeError(error));
    } finally {
      state = state.copyWith(activity: SmartConnectActivity.idle);
    }
  }

  Future<List<ProxyNode>> history(SmartPolicy policy, String nodeId) =>
      repository.history(policy, nodeId);

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
