import 'dart:async';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/smart_runtime_gateway.dart';
import 'package:target/features/smart_connect/data/smart_connect_repository.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';

class FakeSmartGateway extends UnavailableCoreGateway
    implements SmartRuntimeGateway {
  FakeSmartGateway();
  int writes = 0;
  final requests = <pb.ProbeServiceRequest>[];
  final probes = <String, pb.ServiceProbe>{};
  pb.RuntimeConfig config = pb.RuntimeConfig(
    revision: 'r1',
    settings: pb.RuntimeSettings(mixedPort: 17890),
    selectors: [
      pb.SelectorConfig(
        tag: 'proxy',
        nodeIds: ['n1', 'n2'],
        selectedNodeId: 'n2',
      ),
      pb.SelectorConfig(tag: 'external', nodeIds: ['n2'], selectedNodeId: 'n2'),
    ],
    serviceRoutes: [
      pb.ServiceRoute(
        serviceId: 'external',
        domains: ['external.com'],
        selectorTag: 'external',
        enabled: true,
      ),
    ],
  );
  String poolRevision = 'pool1';
  bool supported = true;
  String? failTarget;
  StreamController<pb.ProbeResult>? stream;
  @override
  Future<pb.CapabilitiesResponse> smartCapabilities() async =>
      pb.CapabilitiesResponse(
        smartConnect: supported,
        serviceProbes: supported,
      );
  @override
  Future<pb.RuntimeConfig> smartConfig() async => config.deepCopy();
  @override
  Future<pb.NodePool> getNodePool() async => pb.NodePool(
    revision: poolRevision,
    nodes: [
      for (final id in ['n1', 'n2'])
        pb.ProfileNode(
          tag: id,
          name: id,
          countryCode: 'SG',
          subscriptionId: 'sub',
          phase: pb.ProfileNodePhase.PROFILE_NODE_PHASE_READY,
        ),
    ],
  );
  @override
  Future<pb.RuntimeState> getSmartConnectRuntimeState() async =>
      pb.RuntimeState(running: true);
  @override
  Future<pb.RuntimeConfig> updateSmartModel(
    pb.RuntimeModel model,
    String expectedRevision,
  ) async {
    if (expectedRevision != config.revision) {
      throw StateError('revision mismatch');
    }
    writes++;
    config = pb.RuntimeConfig(
      settings: config.settings,
      selectors: model.selectors,
      serviceRoutes: model.serviceRoutes,
      serviceBindings: model.serviceBindings,
      revision: 'r${writes + 1}',
    );
    return config;
  }

  @override
  Future<pb.ServiceProbe> putSmartProbe(pb.ServiceProbe probe) async {
    probe.revision = 'probe1';
    probes[probe.serviceId] = probe;
    return probe;
  }

  @override
  Stream<pb.ProbeResult> probeSmartService(pb.ProbeServiceRequest request) {
    requests.add(request);
    if (stream != null) return stream!.stream;
    return Stream.fromIterable([
      for (final id in request.nodeIds)
        pb.ProbeResult(
          nodeId: id,
          serviceId: request.serviceId,
          probeRevision: 'probe1',
          nodePoolRevision: poolRevision,
          stage: request.serviceId == failTarget
              ? pb.ProbeStage.PROBE_STAGE_TLS
              : pb.ProbeStage.PROBE_STAGE_READY,
          attempts: 3,
          successes: request.serviceId == failTarget ? 0 : 3,
          observedCountry: 'SG',
          latencyMilliseconds: id == 'n1' ? 20 : 80,
          testedAtUnixMs: Int64(DateTime.now().millisecondsSinceEpoch),
          expiresAtUnixMs: Int64(
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch,
          ),
        ),
    ]);
  }

  @override
  Stream<pb.RuntimeEvent> smartEvents() => const Stream.empty();
  @override
  Future<pb.QualityHistory> smartHistory(
    pb.QualityHistoryRequest request,
  ) async => pb.QualityHistory();
}

void main() {
  late FakeSmartGateway gateway;
  late TargetSmartConnectRepository repository;
  const policy = SmartPolicy(
    id: 'chatgpt',
    domains: {'chatgpt.com'},
    allowedRegions: {'SG'},
    probeTargets: [
      SmartProbeTarget(url: 'https://chatgpt.com/'),
      SmartProbeTarget(url: 'https://openai.com/'),
    ],
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeSmartGateway();
    repository = TargetSmartConnectRepository(gateway);
  });
  test(
    'evaluation probes all targets without touching any runtime binding',
    () async {
      final assessment = await repository.evaluate(policy, SmartCancellation());
      expect(assessment.selection.node?.id, 'n1');
      expect(gateway.requests.length, 2);
      expect(gateway.writes, 0);
      expect(gateway.config.selectors.first.selectedNodeId, 'n2');
    },
  );
  test(
    'failure of one target excludes every failing candidate and never switches',
    () async {
      gateway.failTarget = 'target.smart.chatgpt.probe.1';
      final assessment = await repository.evaluate(policy, SmartCancellation());
      expect(assessment.selection.succeeded, false);
      expect(gateway.writes, 0);
      await expectLater(repository.apply(assessment), throwsStateError);
    },
  );
  test(
    'explicit apply creates an independent singleton selector and preserves ordinary configuration',
    () async {
      final assessment = await repository.evaluate(policy, SmartCancellation());
      await repository.apply(assessment);
      expect(gateway.config.settings.mixedPort, 17890);
      expect(
        gateway.config.selectors
            .firstWhere((s) => s.tag == 'proxy')
            .selectedNodeId,
        'n2',
      );
      expect(gateway.config.selectors.last.nodeIds, ['n1']);
      expect(gateway.config.serviceRoutes.first.enabled, true);
      expect(
        gateway.config.serviceBindings.single.selectionPolicyRevision,
        policy.revision,
      );
      expect(
        (await repository.load()).bindings[policy.id]!.effective,
        false,
      ); // No invented runtime success.
    },
  );
  test(
    'disabling removes owned model and preserves global selection and external routes',
    () async {
      await repository.apply(
        await repository.evaluate(policy, SmartCancellation()),
      );
      await repository.disable();
      expect(gateway.config.serviceRoutes.first.enabled, true);
      expect(gateway.config.serviceRoutes.length, 1);
      expect(gateway.config.selectors.map((s) => s.tag), ['proxy', 'external']);
      expect(gateway.config.serviceBindings, isEmpty);
      expect(gateway.config.selectors.first.selectedNodeId, 'n2');
      final writes = gateway.writes;
      await repository.disable();
      expect(gateway.writes, writes);
    },
  );
  test('runtime and pool revisions prevent stale application', () async {
    final assessment = await repository.evaluate(policy, SmartCancellation());
    gateway.poolRevision = 'pool2';
    await expectLater(repository.apply(assessment), throwsStateError);
    gateway.poolRevision = 'pool1';
    gateway.config.revision = 'external-change';
    await expectLater(repository.apply(assessment), throwsStateError);
    expect(gateway.writes, 0);
  });
  test(
    'cancellation cancels active stream and never starts another target',
    () async {
      var cancelled = false;
      gateway.stream = StreamController<pb.ProbeResult>(
        onCancel: () {
          cancelled = true;
        },
      );
      final token = SmartCancellation();
      final future = repository.evaluate(policy, token);
      final expectation = expectLater(future, throwsStateError);
      while (gateway.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await token.cancel();
      await expectation;
      expect(cancelled, true);
      expect(gateway.requests.length, 1);
      expect(gateway.writes, 0);
      await gateway.stream!.close();
    },
  );
  test(
    'unsupported core fails explicitly before probes or runtime updates',
    () async {
      gateway.supported = false;
      await expectLater(repository.load(), throwsUnsupportedError);
      expect(gateway.requests, isEmpty);
      expect(gateway.writes, 0);
    },
  );
  test(
    'Direct never probes nodes and is represented as a service selector',
    () async {
      const direct = SmartPolicy(
        id: 'cn',
        domains: {'example.cn'},
        selectionMode: SmartSelectionMode.direct,
      );
      await repository.apply(
        await repository.evaluate(direct, SmartCancellation()),
      );
      expect(gateway.requests, isEmpty);
      expect(gateway.config.selectors.last.selectedNodeId, 'direct');
    },
  );
  test(
    'new exclusions are checked again immediately before applying',
    () async {
      final assessment = await repository.evaluate(policy, SmartCancellation());
      await repository.store.saveNodePreference(
        'n1',
        const SmartNodePreference(excluded: true),
      );
      await expectLater(repository.apply(assessment), throwsStateError);
      expect(gateway.writes, 0);
    },
  );
}

