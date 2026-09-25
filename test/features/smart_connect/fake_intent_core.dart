import 'package:fixnum/fixnum.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';

class FakeIntentCore extends UnavailableCoreGateway {
  pb.SmartConnectSnapshot snapshot = pb.SmartConnectSnapshot(revision: 's1');
  pb.RuntimeConfig config = pb.RuntimeConfig(revision: 'r1');
  pb.NodePool pool = pb.NodePool(revision: 'pool1');
  final forced = <pb.ForceServiceBindingRequest>[];
  final selections = <(String, String)>[];
  int bindingWrites = 0;
  bool intentApi = true, running = true, effective = false, failBinding = false;

  @override
  Future<CoreSnapshot> current() async => CoreSnapshot(
    lifecycle: running ? CoreLifecycle.running : CoreLifecycle.stopped,
  );
  @override
  Future<pb.CapabilitiesResponse> smartCapabilities() async =>
      pb.CapabilitiesResponse(
        smartConnectIntentApi: intentApi,
        runtimeEvents: true,
      );
  @override
  Future<pb.SmartConnectSnapshot> smartSnapshot() async => snapshot.deepCopy();
  @override
  Future<pb.NodePool> getNodePool() async => pool.deepCopy();
  @override
  Future<pb.RuntimeConfig> smartConfig() async => config.deepCopy();
  @override
  Future<pb.RuntimeState> getSmartConnectRuntimeState() async =>
      pb.RuntimeState(
        running: running,
        selectors: [
          for (final selector in config.selectors)
            pb.SelectorState(
              desired: selector,
              actualNodeId: running ? selector.selectedNodeId : '',
              effective: running && effective,
            ),
        ],
        serviceBindings: [
          for (final binding in config.serviceBindings)
            pb.ServiceBindingState(
              desired: binding,
              effective: running && effective,
            ),
        ],
      );
  @override
  Stream<pb.SmartConnectEvent> smartIntentEvents() => const Stream.empty();
  @override
  Future<pb.Operation> upsertSmartPolicy(
    pb.UpsertServicePolicyRequest request,
  ) async {
    snapshot.policies.removeWhere(
      (p) => p.serviceId == request.policy.serviceId,
    );
    snapshot.policies.add(request.policy..revision = 'policy1');
    snapshot.revision = 's3';
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<pb.Operation> forceSmartBinding(
    pb.ForceServiceBindingRequest request,
  ) async {
    if (failBinding) throw StateError('Binding rejected');
    bindingWrites++;
    forced.add(request);
    config.serviceBindings.removeWhere((b) => b.serviceId == request.serviceId);
    config.serviceBindings.add(
      pb.ServiceBinding(
        serviceId: request.serviceId,
        nodeId: request.nodeId,
        selectionPolicyRevision: 'policy1',
        expiresAtUnixMs: Int64(
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        ),
      ),
    );
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<pb.Operation> deleteSmartPolicy(
    pb.DeleteServicePolicyRequest request,
  ) async {
    snapshot.policies.removeWhere((p) => p.serviceId == request.serviceId);
    config.serviceBindings.removeWhere((b) => b.serviceId == request.serviceId);
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<void> selectOutbound(String groupId, String outboundId) async {
    selections.add((groupId, outboundId));
    config.selectors.removeWhere((s) => s.tag == groupId);
    config.selectors.add(
      pb.SelectorConfig(tag: groupId, selectedNodeId: outboundId),
    );
  }

  @override
  Future<pb.Operation> requestSmartEvaluation(
    pb.RequestServiceEvaluationRequest request,
  ) async {
    snapshot.proposals.add(
      pb.SwitchProposal(
        id: 'proposal',
        serviceId: request.serviceId,
        suggestedNodeId: pool.nodes.first.tag,
        nodePoolRevision: pool.revision,
        expiresAtUnixMs: Int64(
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        ),
        candidates: [
          pb.ServiceCandidate(
            nodeId: pool.nodes.first.tag,
            eligible: true,
            score: 90,
          ),
        ],
      ),
    );
    return pb.Operation(
      status: pb.OperationStatus.OPERATION_STATUS_WAITING_APPROVAL,
      proposalId: 'proposal',
    );
  }

  @override
  Future<pb.Operation> approveSmartProposal(
    pb.ProposalCommandRequest request,
  ) async {
    final proposal = snapshot.proposals.firstWhere(
      (p) => p.id == request.proposalId,
    );
    return forceSmartBinding(
      pb.ForceServiceBindingRequest(
        serviceId: proposal.serviceId,
        nodeId: proposal.suggestedNodeId,
      ),
    );
  }
}
