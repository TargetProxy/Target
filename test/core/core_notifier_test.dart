import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/runtime_settings.dart';

void main() {
  test('publishes runtime settings after the core applies them', () async {
    final gateway = _DelayedCoreGateway();
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);

    await _waitUntil(
      () => container.read(coreProvider).lifecycle == CoreLifecycle.stopped,
    );

    final update = container
        .read(coreProvider.notifier)
        .updateRuntimeConfig(const RuntimeSettings(proxyMode: ProxyMode.tun));

    expect(container.read(coreProvider).settings.proxyMode, ProxyMode.mixed);
    expect(
      container.read(coreProvider).selectedSettings.proxyMode,
      ProxyMode.tun,
    );
    expect(container.read(coreProvider).busy, isFalse);

    await _waitUntil(() => gateway.updates.isNotEmpty);
    gateway.updates.single.complete(
      const RuntimeSettings(proxyMode: ProxyMode.tun),
    );
    await update;
    expect(container.read(coreProvider).settings.proxyMode, ProxyMode.tun);
  });

  test('mode updates accept new selections and keep Stop available', () async {
    final gateway = _DelayedCoreGateway();
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    await _waitUntil(
      () => container.read(coreProvider).lifecycle == CoreLifecycle.stopped,
    );
    gateway.emit(CoreLifecycle.running);

    final notifier = container.read(coreProvider.notifier);
    const tun = RuntimeSettings(proxyMode: ProxyMode.tun);
    final enablingTun = notifier.updateRuntimeConfig(tun);
    await _waitUntil(() => gateway.updates.isNotEmpty);

    for (final lifecycle in [CoreLifecycle.stopping, CoreLifecycle.starting]) {
      gateway.emit(lifecycle);
      expect(container.read(coreProvider).busy, isFalse);
      expect(container.read(coreProvider).showStop, isTrue);
    }

    final route = container
        .read(coreProvider)
        .selectedSettings
        .copyWith(routeMode: RouteMode.all);
    final changingRoute = notifier.updateRuntimeConfig(route);
    final latest = container
        .read(coreProvider)
        .selectedSettings
        .copyWith(proxyMode: ProxyMode.mixed);
    final disablingTun = notifier.updateRuntimeConfig(latest);
    expect(container.read(coreProvider).selectedSettings, same(latest));

    final stop = notifier.stop();
    expect(gateway.stopCalls, 0);
    gateway.updates.first.complete(tun);
    await _waitUntil(() => gateway.updates.length == 2);
    expect(gateway.requests, [tun, latest]);
    expect(gateway.stopCalls, 0);
    gateway.emit(CoreLifecycle.running);
    gateway.updates.last.complete(latest);
    await Future.wait([enablingTun, changingRoute, disablingTun, stop]);

    expect(gateway.stopCalls, 1);
    expect(container.read(coreProvider).settings, same(latest));
    expect(container.read(coreProvider).requestedSettings, isNull);
    expect(container.read(coreProvider).showStop, isFalse);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _DelayedCoreGateway extends UnavailableCoreGateway {
  final _snapshots = StreamController<CoreSnapshot>.broadcast(sync: true);
  final requests = <RuntimeSettings>[];
  final updates = <Completer<RuntimeSettings>>[];
  var stopCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<RuntimeSettings> getRuntimeConfig() async => const RuntimeSettings();

  @override
  Future<CoreSnapshot> current() async =>
      const CoreSnapshot(lifecycle: CoreLifecycle.stopped);

  @override
  Stream<CoreSnapshot> get snapshots => _snapshots.stream;

  void emit(CoreLifecycle lifecycle) {
    _snapshots.add(CoreSnapshot(lifecycle: lifecycle));
  }

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) async {
    final response = Completer<RuntimeSettings>();
    requests.add(settings);
    updates.add(response);
    return response.future;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    emit(CoreLifecycle.stopped);
  }

  @override
  Future<void> dispose() => _snapshots.close();
}
