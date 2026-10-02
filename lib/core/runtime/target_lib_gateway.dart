// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import '../../data/models/ip_info.dart';
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

class TargetLibGateway implements CoreGateway {
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

  TargetLibClient? _manager;
  ClientChannel? _channel;
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
    final lifecycle = _lifecycle(state.state);
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
  Future<RuntimeSettings> getRuntimeConfig() async {
    await _ensureConnected();
    final result = await _manager!.getRuntimeConfig(
      Empty(),
      options: _callOptions,
    );
    return _runtimeSettings(result);
  }

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) async {
    await _ensureConnected();
    final result = await _manager!.updateRuntimeConfig(
      targetlib_pb.UpdateRuntimeConfigRequest(
        settings: _protoRuntimeSettings(settings),
      ),
      options: _withTimeout(const Duration(seconds: 30)),
    );
    return _runtimeSettings(result);
  }

  @override
  Future<void> restart() async {
    await _ensureConnected();
    await _manager!.restart(Empty(), options: _callOptions);
  }

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
  Future<void> start() async {
    _ensureAvailable();
    _publish(
      _copyCurrent(
        lifecycle: CoreLifecycle.starting,
        message: 'Starting TargetLib...',
      ),
    );
    if (_capabilities.platform == AppPlatform.android) {
      final granted = await const AndroidTargetLibHostBridge()
          .requestPermission();
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
  }

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() async {
    await _ensureConnected();
    final result = await _manager!.listSubscriptions(
      Empty(),
      options: _callOptions,
    );
    return RuntimeSubscriptionSnapshot(
      subscriptions: result.subscriptions.map(_runtimeSubscription).toList(),
    );
  }

  @override
  Future<RuntimeSubscription> getSubscription(String id) async {
    await _ensureConnected();
    return _runtimeSubscription(
      await _manager!.getSubscription(
        targetlib_pb.SubscriptionId(id: id),
        options: _callOptions,
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
    bool updateNow = false,
  }) async {
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
        updateNow: updateNow,
      ),
      options: updateNow
          ? _withTimeout(const Duration(seconds: 45))
          : _callOptions,
    );
    return _runtimeSubscription(view);
  }

  @override
  Future<void> removeSubscription(String id) async {
    await _ensureConnected();
    await _manager!.removeSubscription(
      targetlib_pb.SubscriptionId(id: id),
      options: _callOptions,
    );
  }

  @override
  Future<RuntimeSubscription> renameSubscription(String id, String name) async {
    await _ensureConnected();
    final view = await _manager!.renameSubscription(
      targetlib_pb.RenameSubscriptionRequest(id: id, name: name),
      options: _callOptions,
    );
    return _runtimeSubscription(view);
  }

  @override
  Future<RuntimeSubscription> setSubscriptionEnabled(
    String id,
    bool enabled,
  ) async {
    await _ensureConnected();
    final view = await _manager!.setSubscriptionEnabled(
      targetlib_pb.SetSubscriptionEnabledRequest(id: id, enabled: enabled),
      options: _callOptions,
    );
    return _runtimeSubscription(view);
  }

  @override
  Future<RuntimeSubscription> configureSubscriptionUpdates({
    required String id,
    required bool enabled,
    required int updateIntervalSeconds,
  }) async {
    await _ensureConnected();
    final view = await _manager!.configureSubscriptionUpdates(
      targetlib_pb.ConfigureSubscriptionUpdatesRequest(
        id: id,
        enabled: enabled,
        updateIntervalSeconds: Int64(updateIntervalSeconds),
      ),
      options: _callOptions,
    );
    return _runtimeSubscription(view);
  }

  @override
  Future<targetlib_pb.ResolvedEndpoints> getResolvedEndpoints({
    bool enabledOnly = false,
  }) => _coreCall(
    () => _manager!.getResolvedEndpoints(
      targetlib_pb.ResolvedEndpointsRequest(enabledOnly: enabledOnly),
      options: _callOptions,
    ),
  );

  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) async {
    await _ensureConnected();
    final result = await _manager!.updateSubscription(
      targetlib_pb.SubscriptionId(id: id),
      options: _withTimeout(const Duration(seconds: 45)),
    );
    return RuntimeSubscriptionUpdate(
      subscription: _runtimeSubscription(result.subscription),
      notModified: result.notModified,
      duration: Duration(milliseconds: result.durationMilliseconds.toInt()),
      originalConfig: utf8.decode(result.originalConfig, allowMalformed: true),
      generatedConfig: utf8.decode(
        result.generatedConfig,
        allowMalformed: true,
      ),
    );
  }

  /// Queries the egress IP geolocation through the TargetLib backend.
  @override
  Future<IpInfo> fetchIpInfo() async {
    await _ensureConnected();
    final response = await _manager!.getIpInfo(Empty(), options: _callOptions);
    return IpInfo(
      ip: response.ip,
      country: response.country,
      countryCode: response.countryCode,
      city: response.city,
      isp: response.isp,
      asName: response.asName,
    );
  }

  @override
  Future<targetlib_pb.NodePool> getNodePool() =>
      _coreCall(() => _manager!.getNodePool(Empty(), options: _callOptions));

  @override
  Future<targetlib_pb.SelectNodeResponse> selectNode(String nodeId) =>
      _coreCall(
        () => _manager!.selectNode(
          targetlib_pb.SelectNodeRequest(nodeId: nodeId),
          options: _callOptions,
        ),
      );

  @override
  Future<targetlib_pb.ProxyStatus> getProxyStatus() =>
      _coreCall(() => _manager!.getProxyStatus(Empty(), options: _callOptions));

  @override
  Future<targetlib_pb.RouteInfo> upsertRoute(
    targetlib_pb.UpsertRouteRequest request,
  ) => _coreCall(() => _manager!.upsertRoute(request, options: _callOptions));

  @override
  Future<void> deleteRoute(String serviceId) async {
    await _coreCall(
      () => _manager!.deleteRoute(
        targetlib_pb.DeleteRouteRequest(serviceId: serviceId),
        options: _callOptions,
      ),
    );
  }

  @override
  Future<targetlib_pb.RouteList> listRoutes() =>
      _coreCall(() => _manager!.listRoutes(Empty(), options: _callOptions));

  @override
  Future<targetlib_pb.SelectNodeResponse> selectRouteNode(
    String serviceId,
    String nodeId,
  ) => _coreCall(
    () => _manager!.selectRouteNode(
      targetlib_pb.SelectRouteNodeRequest(serviceId: serviceId, nodeId: nodeId),
      options: _callOptions,
    ),
  );

  @override
  Stream<targetlib_pb.ServiceState> subscribeState() {
    if (_manager == null) return const Stream.empty();
    return _manager!.subscribeState(Empty(), options: _callOptions);
  }

  @override
  Stream<targetlib_pb.TrafficStatus> subscribeTraffic({
    Duration interval = const Duration(seconds: 1),
  }) {
    if (_manager == null) return const Stream.empty();
    return _manager!.subscribeTraffic(
      targetlib_pb.TrafficRequest(
        intervalMilliseconds: interval.inMilliseconds,
      ),
      options: _callOptions,
    );
  }

  @override
  Stream<targetlib_pb.SubscriptionEvent> subscribeSubscriptionEvents() {
    if (_manager == null) return const Stream.empty();
    return _manager!.subscribeSubscriptionEvents(
      Empty(),
      options: _callOptions,
    );
  }

  Future<T> _coreCall<T>(Future<T> Function() operation) async {
    await _ensureConnected();
    return operation();
  }

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
      nodeCount: view.profile.nodes.length,
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

  DateTime? _dateFromUnixMilliseconds(int value) => value <= 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  @override
  Future<void> stop() => _stopLocked();

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
    await selectNode(outboundId);
  }

  @override
  Future<int?> testLatency(String outboundId) async {
    throw const CoreUnavailableException(
      'TargetLib does not expose node latency testing in this API version.',
    );
  }

  @override
  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) async* {
    throw const CoreUnavailableException(
      'TargetLib does not expose node latency testing in this API version.',
    );
  }

  @override
  Future<void> closeConnection(String connectionId) async {
    final manager = _requireManager('closing a connection');
    await manager.closeConnection(
      targetlib_pb.CloseConnectionRequest(id: connectionId),
      options: _callOptions,
    );
    _connections.remove(connectionId);
    _publish(_copyCurrent(connections: List.of(_connections.values)));
  }

  @override
  Future<int> closeAllConnections() async {
    final manager = _requireManager('closing connections');
    final count = _current.traffic.activeConnections;
    await manager.closeAllConnections(Empty(), options: _callOptions);
    _connections.clear();
    _publish(_copyCurrent(connections: const []));
    return count;
  }

  @override
  Future<int> refreshRuleSets() async => 0;

  @override
  Future<void> clearLogs() async {
    AppLogger.clear();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await _stopLocked();
    await _shutdownTransport();
    _disposed = true;
    await _snapshots.close();
    await _subscriptionChanges.close();
  }

  TargetLibClient _requireManager(String action) {
    final manager = _manager;
    if (manager == null) {
      throw CoreUnavailableException('Start TargetLib before $action.');
    }
    return manager;
  }

  CallOptions _withTimeout(Duration timeout) =>
      (_callOptions ?? CallOptions()).mergedWith(CallOptions(timeout: timeout));

  Future<Directory> _resolveBaseDirectory() async {
    final runtime = TargetLibRuntime();
    final path = await runtime.resolveBasePath(
      rootOverride: _workingDirectory?.path,
    );
    return Directory(path);
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
    final baseDir = await _resolveBaseDirectory();
    final runtime = TargetLibRuntime();
    final connection = await runtime.ensureConnected(basePath: baseDir.path);
    _manager = connection.client;
    _channel = connection.channel;
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
    _listen(
      manager.subscribeTraffic(
        targetlib_pb.TrafficRequest(intervalMilliseconds: 1000),
        options: options,
      ),
      _applyTraffic,
      label: 'SubscribeTraffic',
    );
  }

  void _listen<T>(
    Stream<T> stream,
    void Function(T) onData, {
    required String label,
  }) {
    final subscription = stream.listen(
      onData,
      onError: (Object error, StackTrace stackTrace) {
        if (_manager != null && !_disposed) {
          AppLogger.error(
            'TargetLib gRPC stream failed: $label',
            source: 'gRPC',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );
    _subscriptions.add(subscription as StreamSubscription<Object?>);
  }

  static CoreLifecycle _lifecycle(targetlib_pb.ServiceStateType state) =>
      switch (state) {
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

  void _applyManagerState(targetlib_pb.ServiceState status) {
    final lifecycle = _lifecycle(status.state);
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

  void _applyTraffic(targetlib_pb.TrafficStatus status) {
    _publish(_copyCurrent(traffic: _trafficSnapshot(status)));
  }

  static TrafficSnapshot _trafficSnapshot(targetlib_pb.TrafficStatus status) {
    final sampledAt = status.sampledAtUnixMs.toInt();
    return TrafficSnapshot(
      uploadBytes: status.uploadBytesPerSecond.toInt(),
      downloadBytes: status.downloadBytesPerSecond.toInt(),
      // The app exposes one active count while TargetLib reports both sides.
      activeConnections: status.inboundConnections + status.outboundConnections,
      uploadTotalBytes: status.uploadTotalBytes.toInt(),
      downloadTotalBytes: status.downloadTotalBytes.toInt(),
      inboundConnections: status.inboundConnections,
      outboundConnections: status.outboundConnections,
      available: status.available,
      sampledAt: sampledAt <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(sampledAt, isUtc: true),
      intervalMilliseconds: status.intervalMilliseconds,
    );
  }

  Future<void> _shutdownTransport() async {
    final subscriptions = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _manager = null;
    await _channel?.shutdown();
    _channel = null;
    _callOptions = null;
  }

  CoreSnapshot _copyCurrent({
    CoreLifecycle? lifecycle,
    String? message,
    TrafficSnapshot? traffic,
    List<CoreConnection>? connections,
  }) {
    return CoreSnapshot(
      lifecycle: lifecycle ?? _current.lifecycle,
      message: message ?? _current.message,
      traffic: traffic ?? _current.traffic,
      connections: connections ?? _current.connections,
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
}
