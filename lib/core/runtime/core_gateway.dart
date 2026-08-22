import '../../data/models/app_settings.dart';
import '../../data/models/ip_info.dart';
import '../../data/models/proxy_node.dart';
import 'core_models.dart';

/// Stable app-facing boundary for the native proxy core.
///
/// Widgets and feature controllers must not import libbox directly.
abstract class CoreGateway {
  String get name;
  bool get isAvailable;
  Stream<CoreSnapshot> get snapshots;

  Future<CoreSnapshot> current();
  Future<void> configure(AppSettings settings);
  Future<void> setProxyNodes(List<ProxyNode> nodes);
  Future<void> setRawConfig(String? config) async {}
  Future<void> start();
  Future<void> stop();
  Future<void> selectOutbound(String groupId, String outboundId);
  Future<int?> testLatency(String outboundId);
  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds);
  Future<void> closeConnection(String connectionId);
  Future<int> closeAllConnections();
  Future<int> refreshRuleSets();
  Future<void> clearLogs();

  /// Queries the egress IP geolocation through the backend.
  Future<IpInfo> fetchIpInfo();

  Future<void> dispose();
}

class CoreUnavailableException implements Exception {
  const CoreUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Explicit placeholder used when the libbox bridge is unavailable.
class UnavailableCoreGateway implements CoreGateway {
  const UnavailableCoreGateway();

  static const _message = 'Libbox is not available.';

  @override
  String get name => 'Libbox';

  @override
  bool get isAvailable => false;

  @override
  Stream<CoreSnapshot> get snapshots => const Stream.empty();

  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot(
    lifecycle: CoreLifecycle.unavailable,
    message: _message,
  );

  @override
  Future<void> configure(AppSettings settings) => _unavailable();

  @override
  Future<void> setProxyNodes(List<ProxyNode> nodes) => _unavailable();

  @override
  Future<void> setRawConfig(String? config) => _unavailable();

  @override
  Future<void> start() => _unavailable();

  @override
  Future<void> stop() => _unavailable();

  @override
  Future<void> selectOutbound(String groupId, String outboundId) =>
      _unavailable();

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
  Future<void> dispose() async {}

  Future<T> _unavailable<T>() =>
      Future.error(const CoreUnavailableException(_message));
}
