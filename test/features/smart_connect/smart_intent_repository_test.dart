import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/smart_runtime_gateway.dart';
import 'package:target/features/smart_connect/data/smart_connect_repository.dart';
import 'package:target/features/smart_connect/data/smart_intent_repository.dart';
import 'package:target/features/smart_connect/data/smart_policy_store.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';

class FakeIntentCore extends UnavailableCoreGateway
    implements SmartIntentGateway, SmartRuntimeGateway {
  pb.SmartConnectSnapshot snapshot = pb.SmartConnectSnapshot(revision: 's1');
  pb.RuntimeConfig config = pb.RuntimeConfig(revision: 'r1');
  int modelWrites = 0;
  int forceCalls = 0;

  @override
  Future<pb.CapabilitiesResponse> smartCapabilities() async =>
      pb.CapabilitiesResponse(smartConnectIntentApi: true, runtimeEvents: true);
  @override
  Future<pb.SmartConnectSnapshot> smartSnapshot() async => snapshot.deepCopy();
  @override
  Future<pb.NodePool> getNodePool() async => pb.NodePool(revision: 'pool1');
  @override
  Future<pb.RuntimeConfig> smartConfig() async => config.deepCopy();
  @override
  Future<pb.RuntimeState> getSmartConnectRuntimeState() async =>
      pb.RuntimeState(running: true);
  @override
  Future<pb.Operation> setSmartEnabled(
    pb.SetSmartConnectEnabledRequest request,
  ) async {
    snapshot.enabled = request.enabled;
    snapshot.revision = 's${request.enabled ? 2 : 5}';
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<pb.Operation> upsertSmartPolicy(
    pb.UpsertServicePolicyRequest request,
  ) async {
    snapshot.policies.add(request.policy..revision = 'policy1');
    snapshot.revision = 's3';
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<pb.Operation> forceSmartBinding(
    pb.ForceServiceBindingRequest request,
  ) async {
    forceCalls++;
    expect(request.nodeId, 'direct');
    expect(request.serviceId, 'target.smart.direct');
    config.serviceBindings.add(
      pb.ServiceBinding(
        serviceId: request.serviceId,
        nodeId: request.nodeId,
        selectionPolicyRevision: 'policy1',
      ),
    );
    return pb.Operation(status: pb.OperationStatus.OPERATION_STATUS_SUCCEEDED);
  }

  @override
  Future<pb.RuntimeConfig> updateSmartModel(
    pb.RuntimeModel model,
    String revision,
  ) async {
    modelWrites++;
    throw StateError('legacy model mutation');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'intent path owns Direct policy and binding without runtime model writes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final core = FakeIntentCore();
      final repository = IntentSmartConnectRepository(
        core,
        core,
        SmartPolicyStore(),
      );
      const policy = SmartPolicy(
        id: 'direct',
        domains: {'example.com'},
        selectionMode: SmartSelectionMode.direct,
      );
      await repository.enable();
      final assessment = await repository.evaluate(policy, SmartCancellation());
      expect(assessment.selection.direct, isTrue);
      await repository.apply(assessment);
      expect(core.forceCalls, 1);
      expect(core.modelWrites, 0);
      await repository.disable();
      expect(core.snapshot.enabled, isFalse);
    },
  );
}
