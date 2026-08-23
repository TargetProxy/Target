// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/ip_info.dart';
import '../../data/models/proxy_group.dart';
import '../../data/models/proxy_node.dart';
import '../../data/storage/app_storage_paths.dart';
import '../logging/ansi_escape.dart';
import '../logging/app_logger.dart';
import 'core_gateway.dart';
import 'core_models.dart';
import 'grpc/generated/started_service.pb.dart' as daemon_pb;
import 'grpc/generated/started_service.pbgrpc.dart' hide LogLevel;
import 'grpc/generated/api/TargetLib/targetlib.pb.dart' as targetlib_pb;
import 'grpc/generated/api/TargetLib/targetlib.pbgrpc.dart' hide ProxyMode;
import 'subscription_gateway.dart';
import 'target_lib_service_manager.dart';

class TargetLibGateway implements CoreGateway, SubscriptionGateway {
  TargetLibGateway({AppStoragePaths? storagePaths, Directory? workingDirectory})
    : _injectedPaths = storagePaths,
      _workingDirectory = workingDirectory;

  /// Test-only override. When provided, this directory is used as the
  /// isolated AppStoragePaths root so tests never touch the real
  /// platform support directory.
  final AppStoragePaths? _injectedPaths;
  final Directory? _workingDirectory;

  AppStoragePaths? _resolvedPaths;
  Future<AppStoragePaths>? _pathsFuture;

  final StreamController<CoreSnapshot> _snapshots =
      StreamController<CoreSnapshot>.broadcast();
  final StreamController<void> _subscriptionChanges =
      StreamController<void>.broadcast();
  final Map<String, ProxyGroup> _groups = {};
  final Map<String, CoreConnection> _connections = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];

  AppSettings _settings = const AppSettings();
  String? _rawConfig;
  final TargetLibServiceManager _serviceManager = TargetLibServiceManager();
  TargetLibClient? _manager;
  Process? _daemonProcess;
  ClientChannel? _channel;
  StartedServiceClient? _daemon;
  CallOptions? _callOptions;
  String? _socketPath;
  Future<void> _lifecycleTail = Future<void>.value();
  CoreSnapshot _current = const CoreSnapshot(
    lifecycle: CoreLifecycle.stopped,
    message: 'TargetLib is ready.',
  );
  bool _disposed = false;

  @override
  String get name => 'TargetLib';

  @override
  bool get isAvailable =>
      !_disposed &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

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
        proxyMode: _settings.proxyMode == ProxyMode.tun
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
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() => _serialize(() async {
    await _ensureConnected();
    final result = await _manager!.listSubscriptions(
      Empty(),
      options: _callOptions,
    );
    return RuntimeSubscriptionSnapshot(
      subscriptions: result.subscriptions.map(_runtimeSubscription).toList(),
      activeId: result.activeId.isEmpty ? null : result.activeId,
    );
  });

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
          options: _callOptions,
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
    _publish(
      const CoreSnapshot(
        lifecycle: CoreLifecycle.stopped,
        message: 'TargetLib is stopped.',
      ),
    );
  }

  @override
  Future<void> selectOutbound(String groupId, String outboundId) async {
    final daemon = _requireDaemon('selecting an outbound');
    await daemon.selectOutbound(
      daemon_pb.SelectOutboundRequest(
        groupTag: groupId,
        outboundTag: outboundId,
      ),
      options: _callOptions,
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
    await _requireDaemon('closing a connection').closeConnection(
      daemon_pb.CloseConnectionRequest(id: connectionId),
      options: _callOptions,
    );
  }

  @override
  Future<int> closeAllConnections() async {
    final count = _connections.length;
    await _requireDaemon(
      'closing connections',
    ).closeAllConnections(Empty(), options: _callOptions);
    return count;
  }

  @override
  Future<int> refreshRuleSets() async => 0;

  @override
  Future<void> clearLogs() async {
    final daemon = _daemon;
    if (daemon != null) {
      await daemon.clearLogs(Empty(), options: _callOptions);
    }
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

  // ---------------------------------------------------------------------------
  // path_provider-aware storage resolution
  // ---------------------------------------------------------------------------

  /// Returns the canonical [AppStoragePaths], lazily resolved via
  /// `path_provider` on first use.  Tests can inject an isolated
  /// `workingDirectory` which is wrapped as a synthetic [AppStoragePaths]
  /// so they never touch the real platform support directory.
  Future<AppStoragePaths> _resolveStoragePaths() async {
    if (_resolvedPaths != null) return _resolvedPaths!;
    if (_pathsFuture != null) return await _pathsFuture!;
    final future = () async {
      final injected = _injectedPaths;
      if (injected != null) return injected;
      final working = _workingDirectory;
      if (working != null) {
        return AppStoragePaths.fromRoot(working);
      }
      // Primary: let AppStoragePaths use path_provider's
      // getApplicationSupportDirectory internally.
      return AppStoragePaths.resolve();
    }();
    _pathsFuture = future;
    try {
      _resolvedPaths = await future;
      return _resolvedPaths!;
    } finally {
      _pathsFuture = null;
    }
  }

  Future<Directory> _resolveBaseDirectory() async {
    final override = _settings.serviceBasePath.trim();
    if (override.isNotEmpty) return Directory(override);
    final paths = await _resolveStoragePaths();
    return paths.coreDirectory;
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
    return '${base.path}${Platform.pathSeparator}cache.db';
  }

  Future<String> _resolveWorkingPath() async {
    final override = _settings.serviceWorkingPath.trim();
    if (override.isNotEmpty) return override;
    // When no override is set, let TargetLib default to basePath.
    // Return empty so TargetLibServiceManager skips the flag.
    return '';
  }

  Future<String> _resolveTempPath() async {
    final override = _settings.serviceTempPath.trim();
    if (override.isNotEmpty) return override;
    // Prefer path_provider's cache/temp directory as TargetLib scratch space.
    try {
      final cacheDir = await getApplicationCacheDirectory();
      if (cacheDir.path.trim().isNotEmpty) {
        final targetCache = Directory(
          '${cacheDir.path}${Platform.pathSeparator}Target',
        );
        await targetCache.create(recursive: true);
        return targetCache.path;
      }
    } on Object catch (_) {}
    try {
      final tmp = await getTemporaryDirectory();
      if (tmp.path.trim().isNotEmpty) {
        final targetTmp = Directory(
          '${tmp.path}${Platform.pathSeparator}Target',
        );
        await targetTmp.create(recursive: true);
        return targetTmp.path;
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'path_provider temp resolve failed',
        source: 'TargetLib',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return '';
  }

  Future<void> _ensureCore() async {
    if (_daemonProcess != null) return;
    final baseDir = await _resolveBaseDirectory();
    await baseDir.create(recursive: true);
    _socketPath = '${baseDir.path}${Platform.pathSeparator}command.sock';
    if (await File(_socketPath!).exists()) return;
    final workingPath = await _resolveWorkingPath();
    final tempPath = await _resolveTempPath();
    AppLogger.info(
      'Launching TargetLib base=$baseDir working=$workingPath temp=$tempPath',
      source: 'TargetLib',
    );
    _daemonProcess = await _serviceManager.launch(
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
    await _connectCommandServer();
  }

  Future<void> _connectCommandServer() async {
    final channel = ClientChannel(
      InternetAddress(_socketPath!, type: InternetAddressType.unix),
      port: 0,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _channel = channel;
    _daemon = StartedServiceClient(channel);
    _manager = TargetLibClient(channel);
    _callOptions = CallOptions();
    Object? lastError;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      try {
        await _manager!
            .getVersion(Empty(), options: _callOptions)
            .timeout(const Duration(seconds: 1));
        _subscribeCommandStreams();
        return;
      } on Object catch (error) {
        lastError = error;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    _channel = null;
    _daemon = null;
    _manager = null;
    _callOptions = null;
    try {
      await channel.shutdown();
    } on Object {
      // Preserve the handshake error, which is the useful failure here.
    }
    throw StateError('TargetLib command server did not become ready: $lastError');
  }

  void _subscribeCommandStreams() {
    final daemon = _daemon!;
    final manager = _manager!;
    final options = _callOptions;
    _listen(
      manager.subscribeState(Empty(), options: options),
      _applyManagerState,
    );
    _listen(
      manager.subscribeSubscriptionEvents(Empty(), options: options),
      (_) => _subscriptionChanges.add(null),
    );
    _listen(daemon.subscribeLog(Empty(), options: options), _applyLogs);
    _listen(
      daemon.subscribeStatus(
        daemon_pb.SubscribeStatusRequest(interval: Int64(1000)),
        options: options,
      ),
      _applyStatus,
    );
    _listen(daemon.subscribeGroups(Empty(), options: options), _applyGroups);
    _listen(
      daemon.subscribeConnections(
        daemon_pb.SubscribeConnectionsRequest(interval: Int64(1000)),
        options: options,
      ),
      _applyConnections,
    );
  }

  void _listen<T>(Stream<T> stream, void Function(T) onData) {
    final subscription = stream.listen(
      onData,
      onError: (Object error, StackTrace stackTrace) {
        if (_manager != null && !_disposed) {
          AppLogger.warning(
            'TargetLib gRPC stream failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
    );
    _subscriptions.add(subscription as StreamSubscription<Object?>);
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

  void _applyLogs(daemon_pb.Log batch) {
    if (batch.reset) AppLogger.clear();
    for (final message in batch.messages) {
      AppLogger.log(
        _logLevel(message.level),
        stripAnsiEscapeSequences(message.message),
        source: 'gRPC',
      );
    }
  }

  void _applyStatus(daemon_pb.Status status) {
    _publish(
      _copyCurrent(
        traffic: TrafficSnapshot(
          uploadBytes: status.uplinkTotal.toInt(),
          downloadBytes: status.downlinkTotal.toInt(),
          activeConnections: _connections.length,
        ),
      ),
    );
  }

  void _applyGroups(daemon_pb.Groups value) {
    _groups
      ..clear()
      ..addEntries(
        value.group.map((group) {
          final nodes = group.items
              .map((item) {
                final latency = item.urlTestDelay > 0
                    ? item.urlTestDelay
                    : null;
                return ProxyNode(
                  id: item.tag,
                  name: item.tag,
                  type: item.type,
                  latencyMs: latency,
                  isSelected: item.tag == group.selected,
                );
              })
              .toList(growable: false);
          return MapEntry(
            group.tag,
            ProxyGroup(
              id: group.tag,
              name: group.tag,
              type: group.type,
              selectedNodeId: group.selected,
              nodes: nodes,
            ),
          );
        }),
      );
    _publish(_copyCurrent(proxyGroups: _groups.values.toList()));
  }

  void _applyConnections(daemon_pb.ConnectionEvents batch) {
    if (batch.reset) _connections.clear();
    for (final event in batch.events) {
      final id = event.id.isNotEmpty ? event.id : event.connection.id;
      if (event.type == daemon_pb.ConnectionEventType.CONNECTION_EVENT_CLOSED) {
        _connections.remove(id);
        continue;
      }
      final value = event.connection;
      _connections[id] = CoreConnection(
        id: id,
        destination: value.destination,
        domain: value.domain,
        outbound: value.outbound,
        network: value.network,
        protocol: value.protocol,
        uplinkTotal: value.uplinkTotal.toInt(),
        downlinkTotal: value.downlinkTotal.toInt(),
        createdAt: value.createdAt.toInt(),
        closedAt: value.closedAt.toInt(),
      );
    }
    _publish(
      _copyCurrent(
        connections: _connections.values.toList(),
        traffic: TrafficSnapshot(
          uploadBytes: _current.traffic.uploadBytes,
          downloadBytes: _current.traffic.downloadBytes,
          activeConnections: _connections.length,
        ),
      ),
    );
  }

  Future<void> _shutdownTransport() async {
    final subscriptions = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    final channel = _channel;
    _channel = null;
    _daemon = null;
    _manager = null;
    _callOptions = null;
    await channel?.shutdown();
    final process = _daemonProcess;
    _daemonProcess = null;
    if (process != null) {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () => -1,
      );
    }
  }

  StartedServiceClient _requireDaemon(String operation) {
    final daemon = _daemon;
    if (daemon == null) {
      throw CoreUnavailableException('Start TargetLib before $operation.');
    }
    return daemon;
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

  static LogLevel _logLevel(daemon_pb.LogLevel level) => switch (level) {
    daemon_pb.LogLevel.TRACE => LogLevel.verbose,
    daemon_pb.LogLevel.DEBUG => LogLevel.debug,
    daemon_pb.LogLevel.WARN => LogLevel.warning,
    daemon_pb.LogLevel.ERROR ||
    daemon_pb.LogLevel.FATAL ||
    daemon_pb.LogLevel.PANIC => LogLevel.error,
    _ => LogLevel.info,
  };

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
