import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/runtime_settings.dart';
import '../logging/app_logger.dart';
import '../platform/app_platform.dart';
import 'core_gateway.dart';
import 'core_models.dart';
import 'target_lib_gateway.dart';

/// The native proxy core used by the application.
final coreGatewayProvider = Provider<CoreGateway>(
  (ref) => TargetLibGateway(capabilities: ref.watch(appCapabilitiesProvider)),
);

/// Immutable snapshot of the proxy core runtime.
@immutable
class CoreState {
  const CoreState({
    this.lifecycle = CoreLifecycle.unavailable,
    this.message = 'TargetLib is not initialized yet.',
    this.settings = const RuntimeSettings(),
    this.requestedSettings,
    this.traffic = TrafficSnapshot.zero,
    this.connections = const [],
    this.requestedRunning,
    this.available = false,
    this.backendName = 'TargetLib',
  });

  final CoreLifecycle lifecycle;
  final String message;
  final RuntimeSettings settings;
  final RuntimeSettings? requestedSettings;
  final TrafficSnapshot traffic;
  final List<CoreConnection> connections;
  final bool? requestedRunning;
  final bool available;
  final String backendName;

  bool get running => lifecycle == CoreLifecycle.running;

  // A reload's intermediate lifecycle events keep the Stop action available.
  bool get showStop =>
      requestedRunning ??
      (running ||
          lifecycle == CoreLifecycle.starting ||
          lifecycle == CoreLifecycle.stopping);

  RuntimeSettings get selectedSettings => requestedSettings ?? settings;

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
    RuntimeSettings? settings,
    RuntimeSettings? requestedSettings,
    TrafficSnapshot? traffic,
    List<CoreConnection>? connections,
    bool? requestedRunning,
    bool clearMessage = false,
    bool clearRequestedSettings = false,
    bool clearRequestedRunning = false,
  }) {
    return CoreState(
      lifecycle: lifecycle ?? this.lifecycle,
      message: clearMessage ? '' : message ?? this.message,
      settings: settings ?? this.settings,
      requestedSettings: clearRequestedSettings
          ? null
          : requestedSettings ?? this.requestedSettings,
      traffic: traffic ?? this.traffic,
      connections: connections ?? this.connections,
      requestedRunning: clearRequestedRunning
          ? null
          : requestedRunning ?? this.requestedRunning,
      available: available,
      backendName: backendName,
    );
  }
}

class CoreNotifier extends Notifier<CoreState> {
  CoreGateway? _gateway;
  StreamSubscription<CoreSnapshot>? _subscription;
  Future<void> Function()? _startupBarrier;
  Future<void>? _configurationTask;
  Future<void>? _connectionTask;
  int _configurationRevision = 0;

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
    return CoreState(available: gateway.isAvailable, backendName: gateway.name);
  }

  void setStartupBarrier(Future<void> Function() barrier) {
    _startupBarrier = barrier;
  }

  Future<void> updateRuntimeConfig(RuntimeSettings settings) async {
    if (!state.available) return;
    _configurationRevision++;
    final connectionTask = _connectionTask;
    final task = _configurationTask ??= Future<void>.microtask(() async {
      await connectionTask;
      await _applyPendingRuntimeConfig();
    });
    state = state.copyWith(requestedSettings: settings);
    await task;
  }

  Future<void> _applyPendingRuntimeConfig() async {
    try {
      int revision;
      do {
        revision = _configurationRevision;
        await _applyRuntimeConfig(state.selectedSettings);
      } while (revision != _configurationRevision);
    } finally {
      _configurationTask = null;
      state = state.copyWith(clearRequestedSettings: true);
    }
  }

  Future<void> _applyRuntimeConfig(RuntimeSettings settings) async {
    try {
      final applied = await _gateway!.updateRuntimeConfig(settings);
      state = state.copyWith(settings: applied, clearMessage: true);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Core update runtime config failed',
        source: 'core',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        final actual = await _gateway!.getRuntimeConfig();
        final snapshot = await _gateway!.current();
        state = state.copyWith(
          lifecycle: snapshot.lifecycle,
          message: error.toString(),
          traffic: snapshot.traffic,
          connections: snapshot.connections,
          settings: actual,
        );
      } on Object catch (refreshError, refreshStackTrace) {
        _setFailure(
          refreshError,
          refreshStackTrace,
          operationName: 'refresh runtime config after update failure',
        );
      }
    }
  }

  Future<void> start() => _changeConnection(
    () async {
      AppLogger.info('Connect requested using ${state.backendName}');
      await _startupBarrier?.call();
      await _gateway!.start();
    },
    'connect',
    running: true,
  );

  Future<void> stop() =>
      _changeConnection(() => _gateway!.stop(), 'disconnect', running: false);

  Future<void> selectNode(String nodeId) async {
    if (!state.available) return;
    try {
      await _gateway!.selectNode(nodeId);
    } on Object catch (error, stackTrace) {
      _setFailure(
        error,
        stackTrace,
        operationName: 'select node',
        affectsLifecycle: false,
      );
      rethrow;
    }
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
      ),
    );
  }

  Future<void> _refresh() async {
    // build() schedules this method before Riverpod publishes the initial
    // notifier state. Yield once before reading state.
    await Future<void>.value();
    if (!state.available) {
      _applySnapshot(await _gateway!.current());
      return;
    }
    final configurationRevision = _configurationRevision;
    final settings = await _gateway!.getRuntimeConfig();
    final snapshot = await _gateway!.current();
    _applySnapshot(
      CoreSnapshot(
        lifecycle: snapshot.lifecycle,
        message: snapshot.message,
        traffic: snapshot.traffic,
        connections: snapshot.connections,
        runtimeSettings: configurationRevision == _configurationRevision
            ? settings
            : null,
      ),
    );
  }

  Future<void> _changeConnection(
    Future<void> Function() operation,
    String operationName, {
    required bool running,
  }) async {
    if (!state.available) return;
    final connectionTask = _connectionTask;
    final configurationTask = _configurationTask;
    // Each operation waits only for work that was queued before it.
    final task = _connectionTask = Future<void>.microtask(() async {
      try {
        await connectionTask;
        await configurationTask;
        await operation();
        AppLogger.info('Core $operationName completed');
      } on Object catch (error, stackTrace) {
        _setFailure(error, stackTrace, operationName: operationName);
      }
    });
    state = state.copyWith(requestedRunning: running);
    try {
      await task;
    } finally {
      if (identical(_connectionTask, task)) {
        _connectionTask = null;
        state = state.copyWith(clearRequestedRunning: true);
      }
    }
  }

  Future<T?> _runValue<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    try {
      final value = await operation();
      AppLogger.info('Core $operationName completed');
      return value;
    } on Object catch (error, stackTrace) {
      _setFailure(
        error,
        stackTrace,
        operationName: operationName,
        affectsLifecycle: false,
      );
      return null;
    }
  }

  void _setFailure(
    Object error,
    StackTrace stackTrace, {
    required String operationName,
    bool affectsLifecycle = true,
  }) {
    AppLogger.error(
      'Core $operationName failed',
      source: 'core',
      error: error,
      stackTrace: stackTrace,
    );
    state = state.copyWith(
      lifecycle: affectsLifecycle ? CoreLifecycle.failed : null,
      message: error.toString(),
    );
  }

  void _applySnapshot(CoreSnapshot snapshot) {
    state = state.copyWith(
      lifecycle: snapshot.lifecycle,
      message: snapshot.message,
      traffic: snapshot.traffic,
      connections: snapshot.connections,
      settings: snapshot.runtimeSettings,
    );
  }
}

final coreProvider = NotifierProvider<CoreNotifier, CoreState>(
  CoreNotifier.new,
);
