import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/runtime_settings.dart';

void main() {
  test('applies queued runtime settings before stopping the core', () async {
    final gateway = _DelayedCoreGateway();
    final container = ProviderContainer.test(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    final updates = StreamIterator(gateway.updates);
    addTearDown(updates.cancel);

    final ready = Completer<void>();
    final subscription = container.listen(coreProvider, (_, state) {
      if (state.lifecycle == CoreLifecycle.stopped) ready.complete();
    });
    await ready.future;
    subscription.close();
    gateway.emit(CoreLifecycle.running);

    final notifier = container.read(coreProvider.notifier);
    const tun = RuntimeSettings(proxyMode: ProxyMode.tun);
    final enablingTun = notifier.updateRuntimeConfig(tun);
    expect(container.read(coreProvider).settings.proxyMode, ProxyMode.mixed);
    expect(container.read(coreProvider).selectedSettings, same(tun));

    expect(await updates.moveNext(), isTrue);
    final (firstSettings, firstResponse) = updates.current;
    expect(firstSettings, same(tun));

    for (final lifecycle in [CoreLifecycle.stopping, CoreLifecycle.starting]) {
      gateway.emit(lifecycle);
      expect(container.read(coreProvider).showStop, isTrue);
    }

    final route = tun.copyWith(routeMode: RouteMode.all);
    final changingRoute = notifier.updateRuntimeConfig(route);
    final latest = route.copyWith(proxyMode: ProxyMode.mixed);
    final disablingTun = notifier.updateRuntimeConfig(latest);
    expect(container.read(coreProvider).selectedSettings, same(latest));

    final stop = notifier.stop();
    expect(gateway.stopCalls, 0);
    firstResponse.complete(tun);
    expect(await updates.moveNext(), isTrue);
    final (nextSettings, nextResponse) = updates.current;
    expect(nextSettings, same(latest));
    expect(container.read(coreProvider).settings, same(tun));
    expect(gateway.stopCalls, 0);

    gateway.emit(CoreLifecycle.running);
    nextResponse.complete(latest);
    await Future.wait([enablingTun, changingRoute, disablingTun, stop]);

    expect(gateway.stopCalls, 1);
    expect(container.read(coreProvider).settings, same(latest));
    expect(container.read(coreProvider).requestedSettings, isNull);
    expect(container.read(coreProvider).showStop, isFalse);
  });
}

class _DelayedCoreGateway extends UnavailableCoreGateway {
  final _snapshots = StreamController<CoreSnapshot>.broadcast(sync: true);
  final _updates =
      StreamController<(RuntimeSettings, Completer<RuntimeSettings>)>();
  Stream<(RuntimeSettings, Completer<RuntimeSettings>)> get updates =>
      _updates.stream;
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
    _updates.add((settings, response));
    return response.future;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    emit(CoreLifecycle.stopped);
  }

  @override
  Future<void> dispose() async {
    await _updates.close();
    await _snapshots.close();
  }
}
