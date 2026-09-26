import 'dart:async';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:target/features/smart_connect/application/smart_connect_notifier.dart';
import 'package:target/features/smart_connect/application/smart_policy_notifier.dart';
import 'package:target/features/smart_connect/data/smart_connect_repository.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/domain/smart_runtime_models.dart';

class RecordingSmartRepository extends SmartConnectRepository {
  RecordingSmartRepository() : super(UnavailableCoreGateway());
  int reads = 0, evaluations = 0, writes = 0;
  Completer<SmartAssessment>? pending;
  final binding = SmartBinding(
    serviceId: 'x',
    nodeId: 'original',
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
    selection: const SmartSelection(direct: true, reason: 'direct'),
    poolRevision: 'p1',
  );
  @override
  Future<void> apply(SmartAssessment assessment, {String? manualNodeId}) async {
    writes++;
  }

  @override
  Future<void> remove(String policyId) async {
    writes++;
  }

  @override
  Future<List<ProxyNode>> history(SmartPolicy policy, String nodeId) async =>
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
  test('evaluation reads the runtime but never writes a binding', () async {
    await container.read(smartPoliciesProvider.notifier).savePolicy(policy);
    final notifier = container.read(smartConnectProvider.notifier);
    await notifier.refresh();
    expect(repository.reads, greaterThan(0));
    await notifier.evaluate(policy);
    expect(repository.evaluations, 1);
    expect(repository.writes, 0);
    expect(
      container.read(smartConnectProvider).bindings['x']!.nodeId,
      'original',
    );
    await notifier.apply('x');
    expect(repository.writes, 1);
  });
  test(
    'late completion after cancellation cannot create an applicable result',
    () async {
      await container.read(smartPoliciesProvider.notifier).savePolicy(policy);
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.refresh();
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
    'policy edits invalidate the pending result without switching a binding',
    () async {
      final policies = container.read(smartPoliciesProvider.notifier);
      await policies.savePolicy(policy);
      final notifier = container.read(smartConnectProvider.notifier);
      await notifier.refresh();
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
  test('a manual policy refuses to apply without an explicit node', () async {
    const manual = SmartPolicy(
      id: 'x',
      domains: {'example.com'},
      selectionMode: SmartSelectionMode.manual,
      probeTargets: [SmartProbeTarget(url: 'https://example.com/')],
    );
    await container.read(smartPoliciesProvider.notifier).savePolicy(manual);
    final notifier = container.read(smartConnectProvider.notifier);
    await notifier.evaluate(manual);
    await notifier.apply('x');
    expect(repository.writes, 0);
    expect(container.read(smartConnectProvider).error, isNotNull);
  });
}
