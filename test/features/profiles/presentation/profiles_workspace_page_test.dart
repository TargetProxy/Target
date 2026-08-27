import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/core/runtime/subscription_gateway.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/data/models/proxy_group.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/profiles/presentation/profiles_workspace_page.dart';
import 'package:target/features/proxies/application/proxies_notifier.dart';
import 'package:target/features/subscriptions/application/subscriptions_notifier.dart';

void main() {
  testWidgets('selecting a profile activates its nodes for the proxies page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final gateway = _ProfilesGateway();
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ProfilesWorkspacePage())),
      ),
    );

    await container.read(subscriptionsProvider.notifier).load();
    await tester.pumpAndSettle();

    expect(
      container.read(proxiesProvider).selectedGroup?.nodes.single.name,
      'Singapore',
    );

    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();

    expect(gateway.activeId, 'backup');
    expect(
      container.read(proxiesProvider).selectedGroup?.nodes.single.name,
      'Tokyo',
    );
  });
}

class _ProfilesGateway extends UnavailableCoreGateway
    implements SubscriptionGateway {
  final _subscriptionChanges = StreamController<void>.broadcast(sync: true);
  String activeId = 'primary';

  @override
  bool get isAvailable => true;

  @override
  Stream<void> get subscriptionChanges => _subscriptionChanges.stream;

  @override
  Future<void> configureHost(AppSettings settings) async {}

  @override
  Future<RuntimeSettings> getRuntimeConfig() async => const RuntimeSettings();

  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot();

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() async {
    return RuntimeSubscriptionSnapshot(
      subscriptions: [
        _subscription(
          id: 'primary',
          name: 'Primary',
          enabled: activeId == 'primary',
          node: const ProxyNode(
            id: 'sg-1',
            name: 'Singapore',
            type: 'vmess',
            countryCode: 'SG',
          ),
        ),
        _subscription(
          id: 'backup',
          name: 'Backup',
          enabled: activeId == 'backup',
          node: const ProxyNode(
            id: 'jp-1',
            name: 'Tokyo',
            type: 'vmess',
            countryCode: 'JP',
          ),
        ),
      ],
      activeId: activeId,
    );
  }

  @override
  Future<void> activateSubscription(String? id) async {
    activeId = id ?? '';
    _subscriptionChanges.add(null);
  }

  RuntimeSubscription _subscription({
    required String id,
    required String name,
    required bool enabled,
    required ProxyNode node,
  }) {
    return RuntimeSubscription(
      id: id,
      name: name,
      source: '$id.example.test',
      enabled: enabled,
      autoUpdate: false,
      updateIntervalSeconds: 86400,
      status: RuntimeSubscriptionStatus.ready,
      profile: RuntimeProfile(
        nodes: [node],
        groups: [
          ProxyGroup(
            id: ProxyGroup.runtimeSelectorGroupId,
            name: 'proxy',
            type: 'selector',
            nodes: [node],
          ),
        ],
      ),
    );
  }

  @override
  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
    bool activate = false,
    bool updateNow = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeSubscription(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RuntimeSubscription> renameSubscription(String id, String name) {
    throw UnimplementedError();
  }

  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() => _subscriptionChanges.close();
}
