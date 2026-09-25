import 'package:targetlib/targetlib.dart' as pb;

import '../../data/models/ip_info.dart';
import '../../data/models/runtime_settings.dart';
import 'core_models.dart';
import 'subscription_gateway.dart';

/// Stable app-facing boundary for the native proxy core.
///
/// One interface for one implementation: widgets and feature controllers must
/// not import TargetLib directly, but they also must not have to ask which of
/// several gateway roles an object happens to satisfy. Capability differences
/// are runtime facts, reported by [smartCapabilities], not static types.
abstract class CoreGateway {
  String get name;

  bool get isAvailable;

  Stream<CoreSnapshot> get snapshots;

  Future<CoreSnapshot> current();

  Future<RuntimeSettings> getRuntimeConfig();

  Future<RuntimeSettings> updateRuntimeConfig(RuntimeSettings settings);

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

  Stream<void> get subscriptionChanges;

  Future<RuntimeSubscriptionSnapshot> listSubscriptions();

  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
    bool updateNow = false,
  });

  Future<void> removeSubscription(String id);

  Future<RuntimeSubscription> renameSubscription(String id, String name);

  Future<RuntimeSubscription> setSubscriptionEnabled(String id, bool enabled);

  Future<RuntimeSubscriptionUpdate> updateSubscription(String id);

  Future<pb.NodePool> getNodePool();

  Future<pb.CapabilitiesResponse> smartCapabilities();

  Future<pb.RuntimeConfig> smartConfig();

  Future<pb.RuntimeState> getSmartConnectRuntimeState();

  Future<pb.SmartConnectSnapshot> smartSnapshot();

  Future<pb.Operation> upsertSmartPolicy(pb.UpsertServicePolicyRequest request);

  Future<pb.Operation> deleteSmartPolicy(pb.DeleteServicePolicyRequest request);

  Future<pb.Operation> setSmartPreference(pb.SetNodePreferenceRequest request);

  Future<pb.Operation> requestSmartEvaluation(
    pb.RequestServiceEvaluationRequest request,
  );

  Future<pb.Operation> approveSmartProposal(pb.ProposalCommandRequest request);

  Future<pb.Operation> rejectSmartProposal(pb.ProposalCommandRequest request);

  Future<pb.Operation> forceSmartBinding(pb.ForceServiceBindingRequest request);

  Future<pb.Operation> smartOperation(String id);

  Stream<pb.SmartConnectEvent> smartIntentEvents();

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
  Future<void> removeSubscription(String id) => _unavailable();

  @override
  Future<RuntimeSubscription> renameSubscription(String id, String name) =>
      _unavailable();

  @override
  Future<RuntimeSubscription> setSubscriptionEnabled(String id, bool enabled) =>
      _unavailable();

  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) =>
      _unavailable();

  @override
  Future<pb.NodePool> getNodePool() => _unavailable();

  @override
  Future<pb.CapabilitiesResponse> smartCapabilities() => _unavailable();

  @override
  Future<pb.RuntimeConfig> smartConfig() => _unavailable();

  @override
  Future<pb.RuntimeState> getSmartConnectRuntimeState() => _unavailable();

  @override
  Future<pb.SmartConnectSnapshot> smartSnapshot() => _unavailable();

  @override
  Future<pb.Operation> upsertSmartPolicy(
    pb.UpsertServicePolicyRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> deleteSmartPolicy(
    pb.DeleteServicePolicyRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> setSmartPreference(
    pb.SetNodePreferenceRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> requestSmartEvaluation(
    pb.RequestServiceEvaluationRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> approveSmartProposal(
    pb.ProposalCommandRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> rejectSmartProposal(pb.ProposalCommandRequest request) =>
      _unavailable();

  @override
  Future<pb.Operation> forceSmartBinding(
    pb.ForceServiceBindingRequest request,
  ) => _unavailable();

  @override
  Future<pb.Operation> smartOperation(String id) => _unavailable();

  @override
  Stream<pb.SmartConnectEvent> smartIntentEvents() => const Stream.empty();

  @override
  Future<void> dispose() async {}

  Future<T> _unavailable<T>() =>
      Future.error(const CoreUnavailableException(_message));
}
