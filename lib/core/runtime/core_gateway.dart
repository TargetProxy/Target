import 'package:targetlib/targetlib.dart' as pb;

import '../../data/models/ip_info.dart';
import '../../data/models/runtime_settings.dart';
import 'core_models.dart';
import 'subscription_gateway.dart';

/// Stable app-facing boundary for the native proxy core.
///
/// One interface for one implementation: widgets and feature controllers use
/// this boundary without importing TargetLib directly.
abstract class CoreGateway {
  String get name;

  bool get isAvailable;

  Stream<CoreSnapshot> get snapshots;

  Future<CoreSnapshot> current();

  Future<RuntimeSettings> getRuntimeConfig();

  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings);

  Future<void> start();

  Future<void> stop();

  Future<int?> testLatency(String outboundId) => Future.value();

  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) async* {}

  Future<void> closeConnection(String connectionId) => Future.error(
    const CoreUnavailableException('Connection control is not supported.'),
  );

  Future<int> closeAllConnections() => Future.value(0);

  Future<int> refreshRuleSets() => Future.value(0);

  Future<void> clearLogs();

  /// Queries the egress IP geolocation through the backend.
  Future<IpInfo> fetchIpInfo() => Future.error(
    const CoreUnavailableException('IP information is not supported.'),
  );

  Stream<void> get subscriptionChanges;

  Future<RuntimeSubscriptionSnapshot> listSubscriptions() => Future.error(
    const CoreUnavailableException('Subscriptions are not supported.'),
  );

  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
    bool updateNow = false,
  }) => Future.error(const CoreUnavailableException('Subscriptions are not supported.'));

  Future<RuntimeSubscription> setSubscriptionEnabled(String id, bool enabled) =>
      Future.error(const CoreUnavailableException('Subscriptions are not supported.'));

  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) => Future.error(
    const CoreUnavailableException('Subscriptions are not supported.'),
  );

  Future<pb.NodePool> getNodePool();

  Future<pb.SelectNodeResponse> selectNode(String nodeId) => Future.error(
    const CoreUnavailableException('Node selection is not supported.'),
  );

  Future<pb.RouteInfo> upsertRoute(pb.UpsertRouteRequest request) =>
      Future.error(const CoreUnavailableException('Routes are not supported.'));

  Future<void> deleteRoute(String serviceId) => Future.error(
    const CoreUnavailableException('Routes are not supported.'),
  );

  Future<pb.RouteList> listRoutes() => Future.error(
    const CoreUnavailableException('Routes are not supported.'),
  );

  Future<pb.SelectNodeResponse> selectRouteNode(
    String serviceId,
    String nodeId,
  ) => Future.error(const CoreUnavailableException('Routes are not supported.'));

  Future<void> dispose();
}

class CoreUnavailableException implements Exception {
  const CoreUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Explicit placeholder used when the TargetLib bridge is unavailable.
class UnavailableCoreGateway implements CoreGateway {
  const UnavailableCoreGateway();

  static const _message = 'TargetLib is not available.';

  @override
  String get name => 'TargetLib';

  @override
  bool get isAvailable => false;

  @override
  Stream<CoreSnapshot> get snapshots => const Stream.empty();

  @override
  Stream<void> get subscriptionChanges => const Stream.empty();

  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot(
    lifecycle: CoreLifecycle.unavailable,
    message: _message,
  );

  @override
  Future<RuntimeSettings> getRuntimeConfig() => _unavailable();

  @override
  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings) =>
      _unavailable();

  @override
  Future<void> start() => _unavailable();

  @override
  Future<void> stop() => _unavailable();

  @override
  Future<int?> testLatency(String outboundId) => _unavailable();

  @override
  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) async* {
    throw const CoreUnavailableException(_message);
  }

  @override
  Future<void> closeConnection(String connectionId) => _unavailable();

  @override
  Future<int> closeAllConnections() => _unavailable();

  @override
  Future<int> refreshRuleSets() => _unavailable();

  @override
  Future<void> clearLogs() async {}

  @override
  Future<IpInfo> fetchIpInfo() => _unavailable();

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() => _unavailable();

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
  }) => _unavailable();

  @override
  Future<RuntimeSubscription> setSubscriptionEnabled(String id, bool enabled) =>
      _unavailable();

  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) =>
      _unavailable();

  @override
  Future<pb.NodePool> getNodePool() => _unavailable();

  @override
  Future<pb.SelectNodeResponse> selectNode(String nodeId) => _unavailable();

  @override
  Future<pb.RouteInfo> upsertRoute(pb.UpsertRouteRequest request) =>
      _unavailable();

  @override
  Future<void> deleteRoute(String serviceId) => _unavailable();

  @override
  Future<pb.RouteList> listRoutes() => _unavailable();

  @override
  Future<pb.SelectNodeResponse> selectRouteNode(
    String serviceId,
    String nodeId,
  ) => _unavailable();

  @override
  Future<void> dispose() async {}

  Future<T> _unavailable<T>() =>
      Future.error(const CoreUnavailableException(_message));
}
