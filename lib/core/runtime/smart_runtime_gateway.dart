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
