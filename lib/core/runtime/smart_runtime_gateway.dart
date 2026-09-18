import 'package:targetlib/targetlib.dart' as pb;

/// Optional native capability, separate from the ordinary proxy contract.
abstract interface class SmartRuntimeGateway {
  Future<pb.CapabilitiesResponse> smartCapabilities();
  Future<pb.RuntimeConfig> smartConfig();
  Future<pb.RuntimeConfig> updateSmartModel(
    pb.RuntimeModel model,
    String expectedRevision,
  );
  Future<pb.ServiceProbe> putSmartProbe(pb.ServiceProbe probe);
  Stream<pb.ProbeResult> probeSmartService(pb.ProbeServiceRequest request);
  Stream<pb.RuntimeEvent> smartEvents();
  Future<pb.QualityHistory> smartHistory(pb.QualityHistoryRequest request);
}

/// The core owns policy decisions and runtime mutations on intent-capable hosts.
abstract interface class SmartIntentGateway {
  Future<pb.SmartConnectSnapshot> smartSnapshot();
  Future<pb.Operation> setSmartEnabled(
    pb.SetSmartConnectEnabledRequest request,
  );
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
}
