import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:target/features/smart_connect/application/smart_policy_notifier.dart';
import 'package:target/features/smart_connect/data/smart_policy_store.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';

class FailingPolicyStore extends SmartPolicyStore {
  @override
  Future<void> save(Iterable<SmartPolicy> policies) async =>
      throw StateError('disk failure');
}

void main() {
  const a = SmartPolicy(
    id: 'a',
    domains: {'a.com'},
    selectionMode: SmartSelectionMode.direct,
  );
  const b = SmartPolicy(
    id: 'b',
    domains: {'b.com'},
    selectionMode: SmartSelectionMode.direct,
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'concurrent edits serialize without dropping policies and survive a new container',
    () async {
      final container = ProviderContainer();
      final notifier = container.read(smartPoliciesProvider.notifier);
      await Future.wait([notifier.savePolicy(a), notifier.savePolicy(b)]);
      container.dispose();
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      expect(
        (await restored.read(smartPoliciesProvider.future)).map((p) => p.id),
        ['a', 'b'],
      );
    },
  );
  test('persistence failure never publishes an unsaved policy', () async {
    final container = ProviderContainer(
      overrides: [
        smartPolicyStoreProvider.overrideWithValue(FailingPolicyStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(smartPoliciesProvider.future);
    await expectLater(
      container.read(smartPoliciesProvider.notifier).savePolicy(a),
      throwsStateError,
    );
    expect(container.read(smartPoliciesProvider).value, isEmpty);
  });
  test('invalid import is atomic and preserves saved policies', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(smartPoliciesProvider.notifier);
    await notifier.savePolicy(a);
    await expectLater(
      notifier.importPolicies([
        b,
        const SmartPolicy(id: 'invalid', domains: {'https://bad/'}),
      ]),
      throwsFormatException,
    );
    expect((await SmartPolicyStore().load()).map((p) => p.id), ['a']);
  });
  test(
    'node preferences, priorities and safe structured audit survive store recreation',
    () async {
      final store = SmartPolicyStore();
      await store.saveNodePreference(
        'stable-id',
        const SmartNodePreference(
          favorite: true,
          excluded: true,
          tags: {'work'},
        ),
      );
      await store.saveSubscriptionPriority('source', 5);
      await store.saveAudit([
        {
          'action': 'evaluation',
          'serviceId': 'a',
          'outcome': 'ready',
          'scores': {'stable-id': 90.0},
        },
      ]);
      final restored = SmartPolicyStore();
      expect((await restored.nodePreferences())['stable-id']!.favorite, true);
      expect((await restored.nodePreferences())['stable-id']!.tags, {'work'});
      expect((await restored.subscriptionPriorities())['source'], 5);
      expect((await restored.loadAudit()).single['action'], 'evaluation');
    },
  );
}
