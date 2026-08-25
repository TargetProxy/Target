// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:path/path.dart' as p;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/ip_info.dart';
import '../../data/models/proxy_group.dart';
import '../../data/models/proxy_node.dart';
import '../logging/ansi_escape.dart';
import '../logging/app_logger.dart';
import 'core_gateway.dart';
import 'core_models.dart';
import 'package:targetlib/targetlib.dart' as targetlib_pb;
import 'package:targetlib/targetlib.dart' hide ProxyMode, LogLevel;
import 'subscription_gateway.dart';

class TargetLibGateway implements CoreGateway, SubscriptionGateway {
  TargetLibGateway({Directory? workingDirectory})
    : _workingDirectory = workingDirectory {
    TargetLibLog.sink = _forwardTargetLibLog;
  }

  /// Test-only override for the TargetLib runtime root.
  final Directory? _workingDirectory;

  final StreamController<CoreSnapshot> _snapshots =
      StreamController<CoreSnapshot>.broadcast();
  final StreamController<void> _subscriptionChanges =
      StreamController<void>.broadcast();
  final Map<String, ProxyGroup> _groups = {};
  final Map<String, CoreConnection> _connections = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final List<StreamSubscription<Object?>> _runtimeSubscriptions = [];
  Future<void> _runtimeStreamTail = Future<void>.value();

  AppSettings _settings = const AppSettings();
  String? _rawConfig;
  TargetLibClient? _manager;
  final TargetLibRuntime _runtime = TargetLibRuntime();
  CallOptions? _callOptions;
  Future<void> _lifecycleTail = Future<void>.value();
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
  Future<void> configure(AppSettings settings) => _serialize(() async {
    _settings = settings;
    await _reloadIfRunning();
  });

  @override
  @override
  Future<void> setRawConfig(String? config) => _serialize(() async {
    _rawConfig = config?.trim().isEmpty == true ? null : config?.trim();
    if (_rawConfig != null) await _clearActiveSubscription();
    await _reloadIfRunning();
  });

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
      if (Platform.isAndroid) {
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
      await manager.applyRuntimeSettings(
        await _buildConfigRequest(),
        options: _callOptions,
      );
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

  Future<targetlib_pb.BuildConfigRequest> _buildConfigRequest() async {
    final manager = _manager;
    if (manager == null) {
      throw const CoreUnavailableException('TargetLib is not connected.');
    }
    final cacheFilePath = await _resolveCacheFilePath();
    final request = targetlib_pb.BuildConfigRequest(
      settings: targetlib_pb.BuildConfigSettings(
        listenAddress: _settings.listenAddress,
        mixedPort: _settings.mixedPort,
        proxyMode: Platform.isAndroid || _settings.proxyMode == ProxyMode.tun
            ? targetlib_pb.ProxyMode.PROXY_MODE_TUN
            : targetlib_pb.ProxyMode.PROXY_MODE_MIXED,
        ipv6: _settings.ipv6,
        cacheFilePath: cacheFilePath,
      ),
    );
    final rawConfig = _rawConfig;
    if (rawConfig != null) {
      request.rawConfig = utf8.encode(rawConfig);
    }
    // Without an explicit source the backend builds from its persisted
    // active subscription and falls back to a default direct-only config.
    return request;
  }

  Future<void> _reloadIfRunning() async {
    final manager = _manager;
    if (manager == null) return;
    final state = await manager.getState(Empty(), options: _callOptions);
    if (state.state != targetlib_pb.ServiceStateType.SERVICE_STATE_RUNNING) {
      return;
    }
    await manager.applyRuntimeSettings(
      await _buildConfigRequest(),
      options: _callOptions,
    );
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
      options: _callOptions,
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
    if (normalized != null) _rawConfig = null;
  });

  Future<void> _clearActiveSubscription() async {
    final manager = _manager;
    if (manager == null) return;
    await manager.setActiveSubscription(
      targetlib_pb.SetActiveSubscriptionRequest(),
      options: _callOptions,
    );
  }

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
      nodes: [
        for (final node in view.nodes)
          ProxyNode(
            id: node.id,
            name: node.name,
            type: node.type,
            isAvailable:
                node.phase ==
                targetlib_pb
                    .SubscriptionNodePhase
                    .SUBSCRIPTION_NODE_PHASE_READY,
            metadata: {
              'server': node.server,
              'port': node.port,
              'group': node.group,
              'groups': node.groups.toList(),
              if (node.errorMessage.isNotEmpty) 'error': node.errorMessage,
            },
          ),
      ],
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
    _groups.clear();
    _connections.clear();
    if (Platform.isAndroid) {
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
    final daemonGroup = _groups.containsKey(groupId) ? groupId : 'proxy';
    await manager.selectOutbound(
      targetlib_pb.SelectOutboundRequest(
        groupTag: daemonGroup,
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
  Future<void> reinstallService() => _serialize(() async {
    final basePath = (await _resolveBaseDirectory()).path;
    final workingPath = await _resolveWorkingPath();
    final tempPath = await _resolveTempPath();

    // Release the in-process daemon before replacing its registered binary.
    await _shutdownTransport();
    try {
      await _runtime.serviceManager.run(
        'stop',
        basePath: basePath,
        workingPath: workingPath,
        tempPath: tempPath,
        locale: _settings.serviceLocale,
        refreshExecutable: false,
      );
    } on Object catch (error) {
      // The service may not be installed or may already be stopped.
      AppLogger.info('Service stop skipped: $error', source: 'TargetLib');
    }
    try {
      await _runtime.serviceManager.run(
        'uninstall',
        basePath: basePath,
        workingPath: workingPath,
        tempPath: tempPath,
        locale: _settings.serviceLocale,
        refreshExecutable: false,
      );
    } on Object catch (error) {
      // Uninstall is intentionally best effort: a missing service should not
      // prevent the subsequent install from repairing the installation.
      AppLogger.info('Service uninstall skipped: $error', source: 'TargetLib');
    }
    await _runtime.serviceManager.installAndStart(
      basePath: basePath,
      workingPath: workingPath,
      tempPath: tempPath,
      locale: _settings.serviceLocale,
    );
  });

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
      override: _settings.serviceBasePath,
      rootOverride: _workingDirectory?.path,
    );
    return Directory(path);
  }

  Future<String> _resolveCacheFilePath() async {
    // Cache lives alongside the base directory so it survives re-installs
    // and follows the user's custom basePath when set.
    final base = await _resolveBaseDirectory();
    // Ensure the base exists so the cache file's parent is ready.
    try {
      await base.create(recursive: true);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to create TargetLib base directory',
        source: 'TargetLib',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return p.join(base.path, 'cache.db');
  }

  Future<String> _resolveWorkingPath() async {
    final override = _settings.serviceWorkingPath.trim();
    if (override.isNotEmpty) return override;
    // When no override is set, let TargetLib default to basePath.
    // Return empty so the TargetLib runtime uses its default working path.
    return '';
  }

  Future<String> _resolveTempPath() async {
    final override = _settings.serviceTempPath.trim();
    if (override.isNotEmpty) return override;
    // Resolve the TargetLib scratch directory through the plugin runtime.
    return _runtime.resolveTempPath(override);
  }

  Future<void> _ensureCore() async {
    final baseDir = await _resolveBaseDirectory();
    final workingPath = await _resolveWorkingPath();
    final tempPath = await _resolveTempPath();
    await _runtime.ensureConnected(
      basePath: baseDir.path,
      workingPath: workingPath,
      tempPath: tempPath,
      locale: _settings.serviceLocale,
    );
  }

  Future<void> _ensureConnected() async {
    if (_manager != null) return;
    _ensureAvailable();
    await _ensureCore();
    try {
      await _connectCommandServer();
    } on Object catch (firstError, stackTrace) {
      // A daemon terminated outside the app can leave its Unix socket file
      // behind. _ensureCore treats an existing socket as a service-owned
      // endpoint, so recover once by removing the stale endpoint and starting
      // the bundled daemon ourselves.
      if (_runtime.connection != null || _runtime.socketPath == null) rethrow;
      AppLogger.warning(
        'Existing TargetLib command socket is unreachable; restarting daemon',
        source: 'TargetLib',
        error: firstError,
        stackTrace: stackTrace,
      );
      await _ensureCore();
    }
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

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    Future<void> run() async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }

    _lifecycleTail = _lifecycleTail.then<void>(
      (_) => run(),
      onError: (_, _) => run(),
    );
    return completer.future;
  }

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
