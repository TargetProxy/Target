import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/proxy_group.dart';
import '../../data/models/proxy_node.dart';
import '../../features/settings/application/settings_notifier.dart';
import '../logging/app_logger.dart';
import 'core_gateway.dart';
import 'core_models.dart';
import 'libbox_gateway.dart';

/// The native proxy core used by the application.
final coreGatewayProvider = Provider<CoreGateway>((ref) => LibboxGateway());

/// Immutable snapshot of the proxy core runtime.
@immutable
class CoreState {
  const CoreState({
    this.lifecycle = CoreLifecycle.unavailable,
    this.message = 'Libbox is not initialized yet.',
    this.settings = const AppSettings(),
    this.traffic = TrafficSnapshot.zero,
    this.connections = const [],
    this.proxyGroups = const [],
    this.busy = false,
    this.available = false,
    this.backendName = 'Libbox',
  });

  final CoreLifecycle lifecycle;
  final String message;
  final AppSettings settings;
  final TrafficSnapshot traffic;
  final List<CoreConnection> connections;
  final List<ProxyGroup> proxyGroups;
  final bool busy;
  final bool available;
  final String backendName;

  bool get running => lifecycle == CoreLifecycle.running;

  String get status => switch (lifecycle) {
    CoreLifecycle.unavailable => 'Core unavailable',
    CoreLifecycle.stopped => 'Stopped',
    CoreLifecycle.starting => 'Starting',
    CoreLifecycle.running => 'Connected',
    CoreLifecycle.stopping => 'Stopping',
    CoreLifecycle.failed => 'Error',
  };

  CoreState copyWith({
    CoreLifecycle? lifecycle,
    String? message,
    AppSettings? settings,
    TrafficSnapshot? traffic,
    List<CoreConnection>? connections,
    List<ProxyGroup>? proxyGroups,
    bool? busy,
  }) {
    return CoreState(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      settings: settings ?? this.settings,
      traffic: traffic ?? this.traffic,
      connections: connections ?? this.connections,
      proxyGroups: proxyGroups ?? this.proxyGroups,
      busy: busy ?? this.busy,
      available: available,
      backendName: backendName,
    );
  }
}

class CoreNotifier extends Notifier<CoreState> {
  CoreGateway? _gateway;
  StreamSubscription<CoreSnapshot>? _subscription;
  Future<void> Function()? _startupBarrier;

  @override
  CoreState build() {
    final gateway = ref.read(coreGatewayProvider);
    _gateway = gateway;
    _subscription = gateway.snapshots.listen(_applySnapshot);
    unawaited(_refresh());
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      unawaited(gateway.dispose());
    });
    return CoreState(
      available: gateway.isAvailable,
      backendName: gateway.name,
      settings: ref.read(settingsProvider).settings,
    );
  }

  void setStartupBarrier(Future<void> Function() barrier) {
    _startupBarrier = barrier;
  }

  Future<void> configure(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    if (!state.available) {
      return;
    }
    await _run(() => _gateway!.configure(settings));
  }

  Future<void> setProxyNodes(List<ProxyNode> nodes) async {
    if (!state.available) return;
    await _run(() => _gateway!.setProxyNodes(nodes));
  }

  Future<void> setRawConfig(String? config) async {
    if (!state.available) return;
    await _run(() => _gateway!.setRawConfig(config));
  }

  Future<void> start() async {
    if (!state.available) return;
    AppLogger.info('Connect requested using ${state.backendName}');
    await _run(() async {
      await _startupBarrier?.call();
      await _gateway!.configure(state.settings);
      await _gateway!.start();
    }, operationName: 'connect');
  }

  Future<void> stop() async {
    if (!state.available) return;
    await _run(_gateway!.stop, operationName: 'disconnect');
  }

  Future<void> selectOutbound(String groupId, String outboundId) async {
    if (!state.available) return;
    await _run(() => _gateway!.selectOutbound(groupId, outboundId));
  }

  Future<int?> testLatency(String outboundId) async {
    if (!state.available) return null;
    try {
      return await _gateway!.testLatency(outboundId);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Core latency test failed for `$outboundId`',
        source: 'core',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) async* {
    if (!state.available) return;
    try {
      yield* _gateway!.testLatencies(outboundIds);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Core batch latency test failed',
        source: 'core',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> closeConnection(String connectionId) async {
    if (!state.available) return false;
    final result = await _runValue(() async {
      await _gateway!.closeConnection(connectionId);
      return true;
    }, operationName: 'close connection');
    return result ?? false;
  }

  Future<int?> closeAllConnections() {
    if (!state.available) return Future.value();
    return _runValue(
      _gateway!.closeAllConnections,
      operationName: 'close all connections',
    );
  }

  Future<int?> refreshRuleSets() {
    if (!state.available) return Future.value();
    return _runValue(
      _gateway!.refreshRuleSets,
      operationName: 'refresh rule sets',
    );
  }

  Future<void> clearLogs() async {
    await _gateway?.clearLogs();
    _applySnapshot(
      CoreSnapshot(
        lifecycle: state.lifecycle,
        message: state.message,
        traffic: state.traffic,
        connections: state.connections,
        proxyGroups: state.proxyGroups,
      ),
    );
  }

  Future<void> _refresh() async {
    _applySnapshot(await _gateway!.current());
  }

  Future<void> _run(
    Future<void> Function() operation, {
    String operationName = 'core operation',
  }) async {
    state = state.copyWith(busy: true);
    try {
      await operation();
      _applySnapshot(await _gateway!.current());
      AppLogger.info('Core $operationName completed');
    } on Object catch (error, stackTrace) {
      _setFailure(error, stackTrace, operationName: operationName);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<T?> _runValue<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    state = state.copyWith(busy: true);
    try {
      final value = await operation();
      _applySnapshot(await _gateway!.current());
      AppLogger.info('Core $operationName completed');
      return value;
    } on Object catch (error, stackTrace) {
      _setFailure(error, stackTrace, operationName: operationName);
      return null;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  void _setFailure(
    Object error,
    StackTrace stackTrace, {
    required String operationName,
  }) {
    AppLogger.error(
      'Core $operationName failed',
      source: 'core',
      error: error,
      stackTrace: stackTrace,
    );
    _applySnapshot(
      CoreSnapshot(
        lifecycle: CoreLifecycle.failed,
        message: error.toString(),
        traffic: state.traffic,
        connections: state.connections,
        proxyGroups: state.proxyGroups,
      ),
    );
  }

  void _applySnapshot(CoreSnapshot snapshot) {
    state = state.copyWith(
      lifecycle: snapshot.lifecycle,
      message: snapshot.message,
      traffic: snapshot.traffic,
      connections: snapshot.connections,
      proxyGroups: snapshot.proxyGroups,
    );
  }
}

final coreProvider = NotifierProvider<CoreNotifier, CoreState>(
  CoreNotifier.new,
);
