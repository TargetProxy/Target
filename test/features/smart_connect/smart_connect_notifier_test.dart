import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/features/settings/application/settings_notifier.dart';
import 'package:target/features/smart_connect/application/smart_connect_notifier.dart';
import 'package:target/features/smart_connect/application/smart_policy_notifier.dart';
import 'package:target/features/smart_connect/data/smart_connect_repository.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/domain/smart_runtime_models.dart';

class RecordingSmartRepository implements SmartConnectRepository {
  int reads = 0, evaluations = 0, writes = 0, disables = 0;
  bool failDisable = false;
  Completer<SmartAssessment>? pending;
  final binding = SmartBinding(
    serviceId: 'x',
    nodeId: 'original',
    selectedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    reason: 'existing binding',
    effective: true,
  );
  @override
  Future<SmartRuntimeSnapshot> load() async {
    reads++;
    return SmartRuntimeSnapshot(bindings: {'x': binding});
  }

  @override
  Stream<void> events() => const Stream.empty();
  @override
  Future<SmartAssessment> evaluate(
    SmartPolicy policy,
    SmartCancellation cancellation,
  ) async {
    evaluations++;
    if (pending != null) return pending!.future;
    return assessment(policy);
  }

  SmartAssessment assessment(SmartPolicy policy) => SmartAssessment(
    policy: policy,
    nodes: [],
    selection: const SmartSelection(direct: true, reason: 'direct'),
    runtimeRevision: 'r1',
    poolRevision: 'p1',
    evaluatedAt: DateTime.now(),
  );
  @override
  Future<void> apply(SmartAssessment assessment, {String? manualNodeId}) async {
    writes++;
  }

  @override
  Future<void> disable() async {
    disables++;
    if (failDisable) throw StateError('disable rejected');
  }

  @override
  Future<void> remove(String policyId) async {
    writes++;
  }

  @override
  Future<List<SmartNode>> history(SmartPolicy policy, String nodeId) async =>
      [];
}

void main() {
  const policy = SmartPolicy(
    id: 'x',
    domains: {'example.com'},
    selectionMode: SmartSelectionMode.direct,
  );
  late ProviderContainer container;
  late RecordingSmartRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = RecordingSmartRepository();
    container = ProviderContainer(
      overrides: [smartRepositoryProvider.overrideWithValue(repository)],
    );
  });
  tearDown(() => container.dispose());
  test('default-off operations never access runtime or evaluate', () async {
    final notifier = container.read(smartConnectProvider.notifier);
    await notifier.refresh();
    await notifier.evaluate(policy);
    await notifier.apply('x');
    expect(repository.reads, 0);
    expect(repository.evaluations, 0);
    expect(repository.writes, 0);
    expect(
      container.read(settingsProvider).settings.smartConnectEnabled,
      false,
    );
  });
  test(
    'enable is read-only and evaluation preserves sticky bindings',
    () async {
      await container.read(smartPoliciesProvider.notifier).savePolicy(policy);
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.setEnabled(true);
      expect(repository.writes, 0);
      await notifier.evaluate(policy);
      expect(
        container.read(smartConnectProvider).bindings['x']!.nodeId,
        'original',
      );
      expect(repository.writes, 0);
      await notifier.apply('x');
      expect(repository.writes, 1);
    },
  );
  test(
    'late completion after cancellation cannot create an applicable result',
    () async {
      await container.read(smartPoliciesProvider.notifier).savePolicy(policy);
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.setEnabled(true);
      repository.pending = Completer();
      final evaluating = notifier.evaluate(policy);
      await notifier.cancel();
      repository.pending!.complete(repository.assessment(policy));
      await evaluating;
      expect(container.read(smartConnectProvider).assessments, isEmpty);
      expect(
        container.read(smartConnectProvider).bindings['x']!.nodeId,
        'original',
      );
      await notifier.apply('x');
      expect(repository.writes, 0);
    },
  );
  test(
    'disabled switch only commits after native routes are disabled',
    () async {
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.setEnabled(true);
      repository.failDisable = true;
      await notifier.setEnabled(false);
      expect(
        container.read(settingsProvider).settings.smartConnectEnabled,
        true,
      );
      expect(
        container.read(smartConnectProvider).error,
        contains('disable rejected'),
      );
      repository.failDisable = false;
      await notifier.setEnabled(false);
      expect(
        container.read(settingsProvider).settings.smartConnectEnabled,
        false,
      );
    },
  );
  test(
    'policy edits invalidate the pending result without switching a binding',
    () async {
      final policies = container.read(smartPoliciesProvider.notifier);
      await policies.savePolicy(policy);
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.setEnabled(true);
      await notifier.evaluate(policy);
      await policies.savePolicy(
        const SmartPolicy(
          id: 'x',
          domains: {'changed.com'},
          selectionMode: SmartSelectionMode.direct,
        ),
      );
      expect(container.read(smartConnectProvider).assessments, isEmpty);
      expect(
        container.read(smartConnectProvider).bindings['x']!.nodeId,
        'original',
      );
      await notifier.apply('x');
      expect(repository.writes, 0);
    },
  );
  test(
    'startup cleanup is inert until feature ownership was persisted',
    () async {
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.prepareForStart();
      expect(repository.disables, 0);
      await container.read(smartPolicyStoreProvider).markManagedRuntime();
      await notifier.prepareForStart();
      expect(repository.disables, 1);
      repository.failDisable = true;
      await expectLater(notifier.prepareForStart(), throwsStateError);
    },
  );
  test('saved feature flag does not change normal proxy settings', () {
    const defaults = AppSettings();
    final enabled = defaults.copyWith(smartConnectEnabled: true);
    expect(enabled.systemProxy, defaults.systemProxy);
    expect(enabled.smartConnectEnabled, true);
  });
}
