import 'package:flutter_test/flutter_test.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/features/smart_connect/data/smart_connect_repository.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'fake_intent_core.dart';

void main() {
  test('direct route binds only the requested service', () async {
    final core = FakeIntentCore();
    final repository = SmartConnectRepository(core);
    const policy = SmartPolicy(
      id: 'direct',
      domains: {'example.com'},
      selectionMode: SmartSelectionMode.direct,
    );
    await repository.applyRoute(policy);
    expect(core.forced.single.nodeId, 'direct');
    expect(core.forced.single.serviceId, 'target.smart.direct');
    expect(core.selections, isEmpty);
  });
  test(
    'following Default removes service rules without copying its node',
    () async {
      final core = FakeIntentCore();
      final repository = SmartConnectRepository(core);
      const policy = SmartPolicy(
        id: 'service',
        domains: {'example.com'},
        selectionMode: SmartSelectionMode.direct,
      );
      await repository.applyRoute(policy);
      await repository.applyRoute(
        policy.copyWith(selectionMode: SmartSelectionMode.followDefault),
      );
      expect(core.snapshot.policies, isEmpty);
      expect(core.config.serviceBindings, isEmpty);
      expect(core.bindingWrites, 1);
      expect(core.selections, isEmpty);
    },
  );
  test(
    'manual selection rejects a node outside service constraints before syncing',
    () async {
      final core = FakeIntentCore()
        ..pool = pb.NodePool(
          nodes: [pb.ProfileNode(tag: 'jp', countryCode: 'JP')],
        );
      final repository = SmartConnectRepository(core);
      const policy = SmartPolicy(
        id: 'disney',
        domains: {'disneyplus.com'},
        selectionMode: SmartSelectionMode.manual,
        allowedRegions: {'US'},
      );
      await expectLater(
        repository.applyRoute(policy, nodeId: 'jp'),
        throwsStateError,
      );
      expect(core.snapshot.policies, isEmpty);
      expect(core.bindingWrites, 0);
    },
  );
  test('stopped runtime still saves default selection via the core', () async {
    final core = FakeIntentCore()..running = false;
    await SmartConnectRepository(core).selectDefault('direct');
    final loaded = await SmartConnectRepository(core).load();
    expect(loaded.defaultNodeId, 'direct');
    expect(loaded.running, false);
    expect(loaded.defaultEffective, false);
  });
  test(
    'recommendation is not applied automatically and stale settings are rejected',
    () async {
      final core = FakeIntentCore()
        ..pool = pb.NodePool(
          revision: 'pool1',
          nodes: [pb.ProfileNode(tag: 'us', countryCode: 'US')],
        );
      final repository = SmartConnectRepository(core);
      const policy = SmartPolicy(
        id: 'service',
        domains: {'example.com'},
        probeTargets: [SmartProbeTarget(url: 'https://example.com/')],
      );
      final assessment = await repository.evaluate(policy, SmartCancellation());
      expect(core.bindingWrites, 0);
      final changed = SmartPolicy.fromJson({
        ...policy.toJson(),
        'allowedRegions': ['JP'],
      });
      await expectLater(
        repository.applyRoute(changed, assessment: assessment),
        throwsStateError,
      );
      expect(core.bindingWrites, 0);
      await repository.applyRoute(policy, assessment: assessment);
      expect(core.bindingWrites, 1);
    },
  );
}
