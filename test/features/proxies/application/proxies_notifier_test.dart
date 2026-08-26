import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/data/models/proxy_group.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/proxies/application/proxies_notifier.dart';
import 'package:target/features/proxies/application/proxy_catalog.dart';

void main() {
  test('syncs a saved selection only while the core is running', () async {
    final gateway = _RecordingCoreGateway();
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    container.read(coreProvider);
    container.read(proxyCatalogProvider.notifier).replaceGroups(const [
      ProxyGroup(
        id: 'regional-auto',
        name: 'regional-auto',
        type: 'selector',
        nodes: [ProxyNode(id: 'node-1', name: 'Singapore', type: 'vmess')],
      ),
    ]);
    container.read(proxiesProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(proxiesProvider.notifier).selectNode('node-1');
    expect(gateway.selections, isEmpty);

    gateway.emit(const CoreSnapshot(lifecycle: CoreLifecycle.running));
    await Future<void>.delayed(Duration.zero);
    expect(gateway.selections, [('regional-auto', 'node-1')]);

    await container.read(proxiesProvider.notifier).selectNode('node-1');
    expect(gateway.selections, hasLength(1));
  });

  test('core route mode changes without changing the selected node', () async {
    final gateway = _RecordingCoreGateway();
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    container.read(proxyCatalogProvider.notifier).replaceGroups(const [
      ProxyGroup(
        id: 'proxy',
        name: 'proxy',
        type: 'selector',
        nodes: [
          ProxyNode(id: 'node-1', name: 'Singapore', type: 'vmess'),
          ProxyNode(id: 'node-2', name: 'Tokyo', type: 'vmess'),
        ],
      ),
    ]);
    container.read(proxiesProvider);
    await container.read(proxiesProvider.notifier).selectNode('node-2');
    final groupIndex = container.read(proxiesProvider).selectedGroupIndex;

    await container
        .read(coreProvider.notifier)
        .updateRuntimeConfig(
          container
              .read(coreProvider)
              .settings
              .copyWith(routeMode: RouteMode.direct),
        );
    await Future<void>.delayed(Duration.zero);

    final proxies = container.read(proxiesProvider);
    expect(proxies.selectedGroupIndex, groupIndex);
    expect(proxies.selectedGroup?.selectedNodeId, 'node-2');
    expect(container.read(coreProvider).settings.routeMode, RouteMode.direct);
    expect(gateway.configurations.last.routeMode, RouteMode.direct);
  });
}

class _RecordingCoreGateway extends UnavailableCoreGateway {
  final _snapshots = StreamController<CoreSnapshot>.broadcast(sync: true);
  final List<(String, String)> selections = [];
  final List<RuntimeSettings> configurations = [];
  RuntimeSettings runtimeSettings = const RuntimeSettings();

  @override
  bool get isAvailable => true;

  @override
  Stream<CoreSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot();

  void emit(CoreSnapshot snapshot) => _snapshots.add(snapshot);

  @override
  Future<void> configureHost(AppSettings settings) async {}

  @override
  Future<RuntimeSettings> getRuntimeConfig() async => runtimeSettings;

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) async {
    runtimeSettings = settings;
    configurations.add(runtimeSettings);
    return runtimeSettings;
  }

  @override
  Future<void> selectOutbound(String groupId, String outboundId) async {
    selections.add((groupId, outboundId));
  }

  @override
  Future<void> dispose() => _snapshots.close();
}
