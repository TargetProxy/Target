import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/proxy_node.dart';
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
    container.read(proxyCatalogProvider.notifier).replaceNodes(const [
      ProxyNode(id: 'node-1', name: 'Singapore', type: 'vmess'),
    ]);
    container.read(proxiesProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(proxiesProvider.notifier).selectNode('node-1');
    expect(gateway.selections, isEmpty);

    gateway.emit(const CoreSnapshot(lifecycle: CoreLifecycle.running));
    await Future<void>.delayed(Duration.zero);
    expect(gateway.selections, [('all', 'node-1')]);

    await container.read(proxiesProvider.notifier).selectNode('node-1');
    expect(gateway.selections, hasLength(1));
  });
}

class _RecordingCoreGateway extends UnavailableCoreGateway {
  final _snapshots = StreamController<CoreSnapshot>.broadcast(sync: true);
  final List<(String, String)> selections = [];

  @override
  bool get isAvailable => true;

  @override
  Stream<CoreSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot();

  void emit(CoreSnapshot snapshot) => _snapshots.add(snapshot);

  @override
  Future<void> selectOutbound(String groupId, String outboundId) async {
    selections.add((groupId, outboundId));
  }

  @override
  Future<void> dispose() => _snapshots.close();
}
