// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import '../../data/models/ip_info.dart';
import '../../data/models/proxy_group.dart';
import '../../data/models/proxy_node.dart';
import '../../data/models/runtime_settings.dart';
import '../logging/ansi_escape.dart';
import '../logging/app_logger.dart';
import '../platform/app_platform.dart';
import 'core_gateway.dart';
import 'core_models.dart';
import 'package:targetlib/targetlib.dart' as targetlib_pb;
import 'package:targetlib/targetlib.dart'
    hide ProxyMode, RouteMode, RuntimeSettings, LogLevel;
import 'subscription_gateway.dart';

class TargetLibGateway implements CoreGateway, SubscriptionGateway {
  TargetLibGateway({Directory? workingDirectory, AppCapabilities? capabilities})
    : _workingDirectory = workingDirectory,
      _capabilities = capabilities ?? AppCapabilities.current() {
    TargetLibLog.sink = _forwardTargetLibLog;
  }

  /// Test-only override for the TargetLib runtime root.
  final Directory? _workingDirectory;
  final AppCapabilities _capabilities;

  final StreamController<CoreSnapshot> _snapshots =
      StreamController<CoreSnapshot>.broadcast();
  final StreamController<void> _subscriptionChanges =
      StreamController<void>.broadcast();
  final Map<String, CoreConnection> _connections = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<StreamSubscription<Object?>> _runtimeSubscriptions = [];
  Future<void> _runtimeStreamTail = Future<void>.value();

  TargetLibClient? _manager;
  final TargetLibRuntime _runtime = TargetLibRuntime();
  CallOptions? _callOptions;
  Future<void>? _connectionTask;
  CoreSnapshot _current = const CoreSnapshot(
    lifecycle: CoreLifecycle.stopped,
    message: 'TargetLib is ready.',
  );
  bool _disposed = false;

  @override
  String get name => 'TargetLib';

  @override
  bool get isAvailable => !_disposed && TargetLibRuntime.isSupported;

  @override
  Stream<CoreSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<void> get subscriptionChanges => _subscriptionChanges.stream;

  @override
  Future<CoreSnapshot> current() async {
    final manager = _manager;
    if (manager == null) return _current;
    final state = await manager.getState(Empty(), options: _callOptions);
    final lifecycle = switch (state.state) {
      targetlib_pb.ServiceStateType.SERVICE_STATE_RUNNING =>
        CoreLifecycle.running,
      targetlib_pb.ServiceStateType.SERVICE_STATE_STARTING =>
        CoreLifecycle.starting,
      targetlib_pb.ServiceStateType.SERVICE_STATE_STOPPING =>
        CoreLifecycle.stopping,
      targetlib_pb.ServiceStateType.SERVICE_STATE_FAILED =>
        CoreLifecycle.failed,
      _ => CoreLifecycle.stopped,
    };
    _publish(
      _copyCurrent(
        lifecycle: lifecycle,
        message: state.errorMessage.isNotEmpty
            ? state.errorMessage
            : lifecycle == CoreLifecycle.running
            ? 'TargetLib is running.'
            : 'TargetLib is stopped.',
      ),
    );
    return _current;
  }

  @override
  Future<RuntimeSettings> getRuntimeConfig() => _serialize(() async {
    await _ensureConnected();
    final result = await _manager!.getRuntimeConfig(
      Empty(),
      options: _callOptions,
    );
    return _runtimeSettings(result);
  });

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) =>
      _serialize(() async {
        await _ensureConnected();
        final result = await _manager!.updateRuntimeConfig(
          targetlib_pb.UpdateRuntimeConfigRequest(
            settings: _protoRuntimeSettings(settings),
          ),
          options: (_callOptions ?? CallOptions()).mergedWith(
            CallOptions(timeout: const Duration(seconds: 30)),
          ),
        );
        return _runtimeSettings(result);
      });

  targetlib_pb.RuntimeSettings _protoRuntimeSettings(
    RuntimeSettings settings,
  ) => targetlib_pb.RuntimeSettings(
    listenAddress: settings.listenAddress,
    mixedPort: settings.mixedPort,
    proxyMode: switch (settings.proxyMode) {
      ProxyMode.mixed => targetlib_pb.ProxyMode.PROXY_MODE_MIXED,
      ProxyMode.tun => targetlib_pb.ProxyMode.PROXY_MODE_TUN,
    },
    routeMode: switch (settings.routeMode) {
      RouteMode.all => targetlib_pb.RouteMode.ROUTE_MODE_ALL,
      RouteMode.rule => targetlib_pb.RouteMode.ROUTE_MODE_RULE,
      RouteMode.direct => targetlib_pb.RouteMode.ROUTE_MODE_DIRECT,
    },
    ipv6: settings.ipv6,
  );

  RuntimeSettings _runtimeSettings(targetlib_pb.RuntimeConfig source) {
    final settings = source.settings;
    return RuntimeSettings(
      listenAddress: settings.listenAddress,
      mixedPort: settings.mixedPort,
      proxyMode: settings.proxyMode == targetlib_pb.ProxyMode.PROXY_MODE_TUN
          ? ProxyMode.tun
          : ProxyMode.mixed,
      routeMode: switch (settings.routeMode) {
        targetlib_pb.RouteMode.ROUTE_MODE_ALL => RouteMode.all,
        targetlib_pb.RouteMode.ROUTE_MODE_DIRECT => RouteMode.direct,
        _ => RouteMode.rule,
      },
      ipv6: settings.ipv6,
    );
  }

  @override
  Future<void> start() => _serialize(_startLocked);

  Future<void> _startLocked() async {
    _ensureAvailable();
    _publish(
      _copyCurrent(
        lifecycle: CoreLifecycle.starting,
        message: 'Starting TargetLib...',
      ),
    );
    try {
      if (_capabilities.platform == AppPlatform.android) {
        final granted = await Targetlib().requestVpnPermission();
        if (!granted) {
          throw const CoreUnavailableException(
            'Android VPN permission was not granted.',
          );
        }
      }
      await _ensureConnected();
      final manager = _manager!;
      final state = await manager.getState(Empty(), options: _callOptions);
      if (state.state == targetlib_pb.ServiceStateType.SERVICE_STATE_RUNNING) {
        return;
      }
      await manager.start(Empty(), options: _callOptions);
      _publish(
        _copyCurrent(
          lifecycle: CoreLifecycle.running,
          message: 'TargetLib is running.',
        ),
      );
    } on Object {
      rethrow;
    }
  }

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() => _serialize(
    () async {
      await _ensureConnected();
      final result = await _manager!.listSubscriptions(
        Empty(),
        options: _callOptions,
      );
      return RuntimeSubscriptionSnapshot(
        subscriptions: result.subscriptions.map(_runtimeSubscription).toList(),
        activeId: result.activeId.isEmpty ? null : result.activeId,
      );
    },
  );

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
  }) => _serialize(() async {
    await _ensureConnected();
    final view = await _manager!.addSubscription(
      targetlib_pb.AddSubscriptionRequest(
        id: id,
        name: name,
        url: url,
        enabled: enabled,
        autoUpdate: autoUpdate,
        updateIntervalSeconds: Int64(updateIntervalSeconds),
        headers: headers.entries,
        activate: activate,
        updateNow: updateNow,
      ),
      options: updateNow
          ? (_callOptions ?? CallOptions()).mergedWith(
              CallOptions(timeout: const Duration(seconds: 45)),
            )
          : _callOptions,
    );
    return _runtimeSubscription(view);
  });

  @override
  Future<void> removeSubscription(String id) => _serialize(() async {
    await _ensureConnected();
    await _manager!.removeSubscription(
      targetlib_pb.SubscriptionId(id: id),
      options: _callOptions,
    );
  });

  @override
  Future<RuntimeSubscription> renameSubscription(String id, String name) =>
      _serialize(() async {
        await _ensureConnected();
        final view = await _manager!.renameSubscription(
          targetlib_pb.RenameSubscriptionRequest(id: id, name: name),
          options: _callOptions,
        );
        return _runtimeSubscription(view);
      });

  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) =>
      _serialize(() async {
        await _ensureConnected();
        final result = await _manager!.updateSubscription(
          targetlib_pb.SubscriptionId(id: id),
          options: (_callOptions ?? CallOptions()).mergedWith(
            CallOptions(timeout: const Duration(seconds: 45)),
          ),
        );
        return RuntimeSubscriptionUpdate(
          subscription: _runtimeSubscription(result.subscription),
          changed: result.changed,
          notModified: result.notModified,
          duration: Duration(milliseconds: result.durationMilliseconds.toInt()),
          originalConfig: utf8.decode(
            result.originalConfig,
            allowMalformed: true,
          ),
          generatedConfig: utf8.decode(
            result.generatedConfig,
            allowMalformed: true,
          ),
        );
      });

  @override
  Future<void> activateSubscription(String? id) => _serialize(() async {
    await _ensureConnected();
    final normalized = id?.trim().isEmpty == true ? null : id?.trim();
    await _manager!.setActiveSubscription(
      targetlib_pb.SetActiveSubscriptionRequest(id: normalized ?? ''),
      options: _callOptions,
    );
  });

  /// Queries the egress IP geolocation through the TargetLib backend.
  @override
  Future<IpInfo> fetchIpInfo() => _serialize(() async {
    await _ensureConnected();
    final response = await _manager!.getIpInfo(Empty(), options: _callOptions);
    return IpInfo(
      ip: response.ip,
      country: response.country,
      countryCode: response.countryCode,
      city: response.city,
      isp: response.isp,
      org: response.org,
      asName: response.asName,
    );
  });

  RuntimeSubscription _runtimeSubscription(targetlib_pb.SubscriptionView view) {
    return RuntimeSubscription(
      id: view.id,
      name: view.name,
      source: view.source,
      enabled: view.enabled,
      autoUpdate: view.autoUpdate,
      updateIntervalSeconds: view.updateIntervalSeconds.toInt(),
      status: switch (view.status) {
        targetlib_pb.SubscriptionStatus.SUBSCRIPTION_STATUS_UPDATING =>
          RuntimeSubscriptionStatus.updating,
        targetlib_pb.SubscriptionStatus.SUBSCRIPTION_STATUS_READY =>
          RuntimeSubscriptionStatus.ready,
        targetlib_pb.SubscriptionStatus.SUBSCRIPTION_STATUS_FAILED =>
          RuntimeSubscriptionStatus.failed,
        _ => RuntimeSubscriptionStatus.idle,
      },
      profile: _runtimeProfile(view.profile),
      errorCode: view.errorCode.isEmpty ? null : view.errorCode,
      errorMessage: view.errorMessage.isEmpty ? null : view.errorMessage,
      updatedAt: _dateFromUnixMilliseconds(view.updatedAtUnixMs.toInt()),
      expiresAt: _dateFromUnixMilliseconds(view.expiresAtUnixMs.toInt()),
      uploadBytes: view.uploadBytes.toInt(),
      downloadBytes: view.downloadBytes.toInt(),
      totalBytes: view.totalBytes > Int64.ZERO ? view.totalBytes.toInt() : null,
      title: view.title.isEmpty ? null : view.title,
      webPageUrl: view.webPageUrl.isEmpty ? null : view.webPageUrl,
      supportUrl: view.supportUrl.isEmpty ? null : view.supportUrl,
      movedPermanentlyTo: view.movedPermanentlyTo.isEmpty
          ? null
          : view.movedPermanentlyTo,
    );
  }

  RuntimeProfile _runtimeProfile(targetlib_pb.ProfileView source) {
    final nodes = <ProxyNode>[
      for (final node in source.nodes)
        ProxyNode(
          id: node.tag,
          name: node.name.isEmpty ? node.tag : node.name,
          type: node.type,
          countryCode: node.countryCode.isEmpty ? null : node.countryCode,
          // Only nodes that explicitly failed normalization are excluded;
          // discovered/normalized phases stay selectable so exits can be
          // chosen before the core reports READY.
          isAvailable:
              node.phase !=
              targetlib_pb.ProfileNodePhase.PROFILE_NODE_PHASE_FAILED,
          metadata: {
            'server': node.server,
            'port': node.port,
            if (node.errorMessage.isNotEmpty) 'error': node.errorMessage,
          },
        ),
    ];
    final exitNodes = [
      for (final node in nodes)
        if (_isSelectableExit(node) && node.isAvailable) node,
    ];
    return RuntimeProfile(
      nodes: nodes,
      groups: exitNodes.isEmpty
          ? const []
          : [
              ProxyGroup(
                id: ProxyGroup.runtimeSelectorGroupId,
                name: ProxyGroup.runtimeSelectorGroupId,
                type: 'selector',
                nodes: exitNodes,
              ),
            ],
    );
  }

  static bool _isSelectableExit(ProxyNode node) {
    final type = node.type.toLowerCase();
    return type != 'direct' && type != 'block' && type != 'dns';
  }

  DateTime? _dateFromUnixMilliseconds(int value) => value <= 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  @override
  Future<void> stop() => _serialize(_stopLocked);

  Future<void> _stopLocked() async {
    final manager = _manager;
    if (manager == null) {
      _publish(
        _copyCurrent(
          lifecycle: CoreLifecycle.stopped,
          message: 'TargetLib is stopped.',
        ),
      );
      return;
    }
    _publish(
      _copyCurrent(
        lifecycle: CoreLifecycle.stopping,
        message: 'Stopping TargetLib...',
      ),
    );
    await manager.stop(Empty(), options: _callOptions);
    _connections.clear();
    if (_capabilities.platform == AppPlatform.android) {
      // The Android daemon lives inside TargetlibVpnService, which hands the
      // core a one-shot TUN fd per session. Tear the service down with the
      // core so the next start re-establishes a fresh tunnel.
      await _shutdownTransport();
    }
    _publish(
      const CoreSnapshot(
        lifecycle: CoreLifecycle.stopped,
        message: 'TargetLib is stopped.',
      ),
    );
  }

  @override
  Future<void> selectOutbound(String groupId, String outboundId) async {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException(
        'Start TargetLib before selecting an outbound.',
      );
    }
    await manager.selectOutbound(
      targetlib_pb.SelectOutboundRequest(
        groupTag: groupId,
        outboundTag: outboundId,
      ),
      options: (_callOptions ?? CallOptions()).mergedWith(
        CallOptions(timeout: const Duration(seconds: 5)),
      ),
    );
  }

  @override
  Future<int?> testLatency(String outboundId) async {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException(
        'Start TargetLib before testing latency.',
      );
    }
    final result = _coreLatencyResult(
      await manager.testOutbound(
        targetlib_pb.TestOutboundRequest(
          outboundTag: outboundId,
          timeoutMilliseconds: 15000,
        ),
        options: _callOptions,
      ),
    );
    if (!result.succeeded) {
      throw CoreUnavailableException(result.errorMessage);
    }
    return result.delayMilliseconds;
  }

  @override
  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) async* {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException(
        'Start TargetLib before testing latency.',
      );
    }
    final stream = manager.testOutbounds(
      targetlib_pb.TestOutboundsRequest(
        outboundTags: outboundIds,
        timeoutMilliseconds: 15000,
        maxConcurrency: 4,
      ),
      options: _callOptions,
    );
    await for (final result in stream) {
      yield _coreLatencyResult(result);
    }
  }

  @override
  Future<void> closeConnection(String connectionId) async {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException(
        'Start TargetLib before closing a connection.',
      );
    }
    await manager.closeConnection(
      targetlib_pb.CloseConnectionRequest(id: connectionId),
      options: _callOptions,
    );
  }

  @override
  Future<int> closeAllConnections() async {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException(
        'Start TargetLib before closing connections.',
      );
    }
    final count = _connections.length;
    await manager.closeAllConnections(Empty(), options: _callOptions);
    return count;
  }

  @override
  Future<int> refreshRuleSets() async => 0;

  @override
  Future<void> clearLogs() async {
    AppLogger.clear();
  }

  @override
  Future<void> dispose() => _serialize(() async {
    if (_disposed) return;
    await _stopLocked();
    await _shutdownTransport();
    _disposed = true;
    await _snapshots.close();
    await _subscriptionChanges.close();
  });

  Future<Directory> _resolveBaseDirectory() async {
    final path = await _runtime.resolveBasePath(
      rootOverride: _workingDirectory?.path,
    );
    return Directory(path);
  }

  Future<void> _ensureCore() async {
    final baseDir = await _resolveBaseDirectory();
    await _runtime.ensureConnected(basePath: baseDir.path);
  }

  Future<void> _ensureConnected() async {
    if (_manager != null) return;
    final activeTask = _connectionTask;
    if (activeTask != null) {
      await activeTask;
      return;
    }

    final task = _connectAndSubscribe();
    _connectionTask = task;
    try {
      await task;
    } finally {
      if (identical(_connectionTask, task)) {
        _connectionTask = null;
      }
    }
  }

  Future<void> _connectAndSubscribe() async {
    _ensureAvailable();
    await _ensureCore();
    await _connectCommandServer();
  }

  Future<void> _connectCommandServer() async {
    final connection = _runtime.connection;
    if (connection == null) {
      throw StateError('TargetLib runtime is not connected.');
    }
    _manager = connection.client;
    _callOptions = connection.options;
    _subscribeCommandStreams();
  }

  void _subscribeCommandStreams() {
    final manager = _manager!;
    final options = _callOptions;
    _listen(
      manager.subscribeState(Empty(), options: options),
      _applyManagerState,
      label: 'SubscribeState',
    );
    _listen(
      manager.subscribeSubscriptionEvents(Empty(), options: options),
      (_) => _subscriptionChanges.add(null),
      label: 'SubscribeSubscriptionEvents',
    );
    _listen(
      manager.subscribeLogs(Empty(), options: options),
      _applyLogs,
      label: 'SubscribeLogs',
    );
  }

  void _setRuntimeStreamsEnabled(bool enabled) {
    _runtimeStreamTail = _runtimeStreamTail.then<void>((_) async {
      final previous = List<StreamSubscription<Object?>>.of(
        _runtimeSubscriptions,
      );
      _runtimeSubscriptions.clear();
      for (final subscription in previous) {
        _subscriptions.remove(subscription);
        await subscription.cancel();
      }
      if (!enabled || _manager == null || _disposed) return;
    });
  }

  StreamSubscription<Object?> _listen<T>(
    Stream<T> stream,
    void Function(T) onData, {
    required String label,
  }) {
    final subscription = stream.listen(
      onData,
      onError: (Object error, StackTrace stackTrace) {
        if (_manager != null && !_disposed) {
          AppLogger.warning(
            'TargetLib gRPC stream failed: $label',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );
    final tracked = subscription as StreamSubscription<Object?>;
    _subscriptions.add(tracked);
    return tracked;
  }

  void _applyManagerState(targetlib_pb.ServiceState status) {
    final lifecycle = switch (status.state) {
      targetlib_pb.ServiceStateType.SERVICE_STATE_STARTING =>
        CoreLifecycle.starting,
      targetlib_pb.ServiceStateType.SERVICE_STATE_RUNNING =>
        CoreLifecycle.running,
      targetlib_pb.ServiceStateType.SERVICE_STATE_STOPPING =>
        CoreLifecycle.stopping,
      targetlib_pb.ServiceStateType.SERVICE_STATE_FAILED =>
        CoreLifecycle.failed,
      _ => CoreLifecycle.stopped,
    };
    _setRuntimeStreamsEnabled(lifecycle == CoreLifecycle.running);
    _publish(
      _copyCurrent(
        lifecycle: lifecycle,
        message: status.errorMessage.isNotEmpty
            ? status.errorMessage
            : lifecycle == CoreLifecycle.running
            ? 'TargetLib is running.'
            : _current.message,
      ),
    );
  }

  void _applyLogs(targetlib_pb.LogBatch batch) {
    if (batch.reset) AppLogger.clear();
    for (final message in batch.messages) {
      if (message.level == targetlib_pb.LogLevel.LOG_LEVEL_DEBUG ||
          message.level == targetlib_pb.LogLevel.LOG_LEVEL_TRACE) {
        continue;
      }
      AppLogger.log(
        _logLevel(message.level),
        stripAnsiEscapeSequences(message.message),
        source: 'gRPC',
      );
    }
  }

  Future<void> _shutdownTransport() async {
    _runtimeSubscriptions.clear();
    final subscriptions = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _manager = null;
    _callOptions = null;
    await _runtime.close();
  }

  /// Starts each RPC immediately. The returned future represents only this
  /// operation; unrelated requests must not wait behind a slow RPC such as
  /// IP geolocation.
  Future<T> _serialize<T>(Future<T> Function() operation) => operation();

  CoreSnapshot _copyCurrent({
    CoreLifecycle? lifecycle,
    String? message,
    TrafficSnapshot? traffic,
    List<CoreConnection>? connections,
    List<ProxyGroup>? proxyGroups,
  }) {
    return CoreSnapshot(
      lifecycle: lifecycle ?? _current.lifecycle,
      message: message ?? _current.message,
      traffic: traffic ?? _current.traffic,
      connections: connections ?? _current.connections,
      proxyGroups: proxyGroups ?? _current.proxyGroups,
    );
  }

  void _publish(CoreSnapshot snapshot) {
    _current = snapshot;
    if (!_snapshots.isClosed) _snapshots.add(snapshot);
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw const CoreUnavailableException(
        'TargetLib is supported on Windows, Linux, and macOS.',
      );
    }
  }

  static LogLevel _logLevel(targetlib_pb.LogLevel level) => switch (level) {
    targetlib_pb.LogLevel.LOG_LEVEL_WARN => LogLevel.warning,
    targetlib_pb.LogLevel.LOG_LEVEL_ERROR ||
    targetlib_pb.LogLevel.LOG_LEVEL_FATAL ||
    targetlib_pb.LogLevel.LOG_LEVEL_PANIC => LogLevel.error,
    _ => LogLevel.info,
  };

  static void _forwardTargetLibLog(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? source,
  }) {
    final origin = source ?? 'TargetLib';
    switch (level) {
      case 'DEBUG':
        AppLogger.debug(message, source: origin);
      case 'WARN':
        AppLogger.warning(
          message,
          source: origin,
          error: error,
          stackTrace: stackTrace,
        );
      case 'ERROR':
        AppLogger.error(
          message,
          source: origin,
          error: error,
          stackTrace: stackTrace,
        );
      default:
        AppLogger.info(message, source: origin);
    }
  }

  static CoreLatencyResult _coreLatencyResult(
    targetlib_pb.LatencyTestResult result,
  ) {
    final testedAt = result.testedAtUnixMs.toInt();
    return CoreLatencyResult(
      outboundId: result.outboundTag,
      status: switch (result.status) {
        targetlib_pb.LatencyTestStatus.LATENCY_TEST_STATUS_SUCCESS =>
          CoreLatencyStatus.success,
        targetlib_pb.LatencyTestStatus.LATENCY_TEST_STATUS_TIMEOUT =>
          CoreLatencyStatus.timeout,
        targetlib_pb.LatencyTestStatus.LATENCY_TEST_STATUS_NOT_FOUND =>
          CoreLatencyStatus.notFound,
        _ => CoreLatencyStatus.failed,
      },
      delayMilliseconds:
          result.status ==
              targetlib_pb.LatencyTestStatus.LATENCY_TEST_STATUS_SUCCESS
          ? result.delayMilliseconds
          : null,
      testedAt: testedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(testedAt, isUtc: true)
          : null,
      errorMessage: result.errorMessage,
    );
  }
}
