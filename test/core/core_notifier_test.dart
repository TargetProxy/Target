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
    expect(container.read(coreProvider).busy, isTrue);

    gateway.response.complete(const RuntimeSettings(proxyMode: ProxyMode.tun));
    await update;
    await _waitUntil(() => !container.read(coreProvider).busy);

    expect(container.read(coreProvider).settings.proxyMode, ProxyMode.tun);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  while (!condition()) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _DelayedCoreGateway extends UnavailableCoreGateway {
  final response = Completer<RuntimeSettings>();

  @override
  bool get isAvailable => true;

  @override
  Future<RuntimeSettings> getRuntimeConfig() async => const RuntimeSettings();

  @override
  Future<CoreSnapshot> current() async =>
      const CoreSnapshot(lifecycle: CoreLifecycle.stopped);

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) async {
    return response.future;
  }
}
