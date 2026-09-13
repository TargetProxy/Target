import 'dart:async';
import 'package:fixnum/fixnum.dart';
import 'package:targetlib/targetlib.dart' as pb;
import '../../../core/runtime/core_gateway.dart';
import '../../../core/runtime/smart_runtime_gateway.dart';
import '../domain/smart_connect_models.dart';
import 'smart_policy_store.dart';
import '../domain/smart_runtime_models.dart';

class SmartCancellation {
  bool cancelled = false;
  Future<void> Function()? cancelStream;
  Future<void> cancel() async {
    cancelled = true;
    await cancelStream?.call();
  }

  void check() {
    if (cancelled) throw StateError('Evaluation cancelled');
  }
}

abstract class SmartConnectRepository {
  Future<SmartRuntimeSnapshot> load();
  Stream<void> events();
  Future<SmartAssessment> evaluate(
    SmartPolicy policy,
    SmartCancellation cancellation,
  );
  Future<void> apply(SmartAssessment assessment, {String? manualNodeId});
  Future<void> disable();
  Future<void> remove(String policyId);
  Future<List<SmartNode>> history(SmartPolicy policy, String nodeId);
}

/// The only feature layer aware of protobuf. No service operation selects the
/// ordinary proxy group, and evaluation never writes the runtime model.
class TargetSmartConnectRepository implements SmartConnectRepository {
  TargetSmartConnectRepository(this.core, {SmartPolicyStore? store})
    : store = store ?? SmartPolicyStore();
  final SmartPolicyStore store;
  final CoreGateway core;
  static const prefix = 'target.smart.';
  String _probeId(String policyId, int index) =>
      index == 0 ? '$prefix$policyId' : '$prefix$policyId.probe.$index';
  SmartRuntimeGateway get api {
    final gateway = core;
    if (gateway is! SmartRuntimeGateway) {
      throw UnsupportedError('This core does not support Smart Connect');
    }
    return gateway as SmartRuntimeGateway;
  }

  DateTime _date(Int64 value) =>
      DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);

  @override
  Future<SmartRuntimeSnapshot> load() async {
    final caps = await api.smartCapabilities();
    if (!caps.smartConnect || !caps.serviceProbes) {
      throw UnsupportedError(
        'TargetLib does not support service routing and probes; update the core',
      );
    }
    final pool = await core.getNodePool();
    final preferences = await store.nodePreferences();
    final priorities = await store.subscriptionPriorities();
    final config = await api.smartConfig();
    final runtime = await core.getSmartConnectRuntimeState();
    final policies = {for (final p in await store.load()) p.id: p};
    final bindings = <String, SmartBinding>{};
    for (final b in config.serviceBindings.where(
      (b) => b.serviceId.startsWith(prefix),
    )) {
      final id = b.serviceId.substring(prefix.length);
      bindings[id] = await _bindingWithQuality(b, runtime, policies[id]);
    }
    return SmartRuntimeSnapshot(
      nodes: [
        for (final n in pool.nodes)
          _node(n, preferences[n.tag], priorities[n.subscriptionId] ?? 0),
      ],
      revision: config.revision,
      poolRevision: pool.revision,
      running: runtime.running,
      eventsSupported: caps.runtimeEvents,
      bindings: bindings,
    );
  }

  SmartNode _node(
    pb.ProfileNode node,
    SmartNodePreference? preference,
    int priority,
  ) => SmartNode(
    id: node.tag,
    name: node.name,
    subscriptionId: node.subscriptionId,
    protocol: node.type,
    region: node.countryCode,
    enabled:
        (preference?.enabled ?? true) &&
        node.phase != pb.ProfileNodePhase.PROFILE_NODE_PHASE_FAILED,
    excluded: preference?.excluded ?? false,
    favorite: preference?.favorite ?? false,
    tags: preference?.tags ?? {},
    subscriptionPriority: priority,
  );

  SmartBinding _binding(pb.ServiceBinding binding, pb.RuntimeState runtime) {
    final states = runtime.serviceBindings.where(
      (b) => b.desired.serviceId == binding.serviceId,
    );
    final actual = states.isEmpty ? null : states.first;
    return SmartBinding(
      serviceId: binding.serviceId.substring(prefix.length),
      nodeId: binding.nodeId,
      selectedAt: _date(binding.selectedAtUnixMs),
      expiresAt: _date(binding.expiresAtUnixMs),
      reason: binding.selectionReason,
      score: binding.selectedScore,
      policyRevision: binding.selectionPolicyRevision,
      effective: actual?.effective ?? false,
      needsEvaluation: actual?.needsEvaluation ?? true,
      status: actual?.evaluationReason ?? 'Runtime status unavailable',
    );
  }

  Future<SmartBinding> _bindingWithQuality(
    pb.ServiceBinding raw,
    pb.RuntimeState runtime,
    SmartPolicy? policy,
  ) async {
    final binding = _binding(raw, runtime);
    var reason = binding.status;
    var needsEvaluation = binding.needsEvaluation;
    if (policy == null ||
        !policy.enabled ||
        binding.policyRevision != policy.revision) {
      reason = 'Policy missing, disabled or changed; re-evaluation required';
      needsEvaluation = true;
    } else if (policy.selectionMode != SmartSelectionMode.direct) {
      for (var i = 0; i < policy.probeTargets.length; i++) {
        final history = await api.smartHistory(
          pb.QualityHistoryRequest(
            serviceId: _probeId(policy.id, i),
            nodeId: binding.nodeId,
            limit: 1,
          ),
        );
        final latest = history.results.firstOrNull;
        if (latest == null ||
            latest.stage != pb.ProbeStage.PROBE_STAGE_READY ||
            latest.successes == 0 ||
            latest.expiresAtUnixMs.toInt() <=
                DateTime.now().millisecondsSinceEpoch) {
          reason =
              'Target ${i + 1}: ${latest == null
                  ? "not probed"
                  : latest.stage == pb.ProbeStage.PROBE_STAGE_READY
                  ? "quality expired"
                  : latest.stage.name.replaceFirst("PROBE_STAGE_", "")}';
          needsEvaluation = true;
          break;
        }
      }
    }
    return SmartBinding(
      serviceId: binding.serviceId,
      nodeId: binding.nodeId,
      selectedAt: binding.selectedAt,
      expiresAt: binding.expiresAt,
      reason: binding.reason,
      score: binding.score,
      policyRevision: binding.policyRevision,
      effective: binding.effective,
      needsEvaluation: needsEvaluation,
      status: reason,
    );
  }

  @override
  Stream<void> events() => api.smartEvents().map((_) {});

  @override
  Future<SmartAssessment> evaluate(
    SmartPolicy policy,
    SmartCancellation cancellation,
  ) async {
    final errors = policy.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    final snapshot = await load();
    cancellation.check();
    final candidates = snapshot.nodes
        .where((n) => smartCandidateExclusion(policy, n) == null)
        .toList();
    final results = <String, Map<int, pb.ProbeResult>>{};
    if (policy.selectionMode != SmartSelectionMode.direct &&
        candidates.isNotEmpty) {
      for (var i = 0; i < policy.probeTargets.length; i++) {
        cancellation.check();
        final target = policy.probeTargets[i];
        final probe = await api.putSmartProbe(
          pb.ServiceProbe(
            serviceId: _probeId(policy.id, i),
            url: target.url,
            expectedStatus: target.expectedStatus,
            bodyContains: target.bodyContains,
            allowedCountries: policy.allowedRegions,
            egressUrl: target.egressUrl,
            serviceCountryHeader: target.serviceCountryHeader,
            timeoutMilliseconds: 10000,
            validitySeconds: policy.probeValidity.inSeconds,
          ),
        );
        cancellation.check();
        for (var offset = 0; offset < candidates.length; offset += 256) {
          cancellation.check();
          final batch = candidates
              .skip(offset)
              .take(256)
              .map((n) => n.id)
              .toList();
          final done = Completer<void>();
          final subscription = api
              .probeSmartService(
                pb.ProbeServiceRequest(
                  serviceId: probe.serviceId,
                  nodeIds: batch,
                  attempts: 3,
                  maxConcurrency: 4,
                ),
              )
              .listen(
                (result) {
                  if (!cancellation.cancelled &&
                      result.serviceId == probe.serviceId &&
                      result.probeRevision == probe.revision &&
                      result.nodePoolRevision == snapshot.poolRevision &&
                      batch.contains(result.nodeId)) {
                    results.putIfAbsent(result.nodeId, () => {})[i] = result;
                  }
                },
                onError: (Object error, StackTrace stack) {
                  if (!done.isCompleted) done.completeError(error, stack);
                },
                onDone: () {
                  if (!done.isCompleted) done.complete();
                },
              );
          cancellation.cancelStream = () async {
            await subscription.cancel();
            if (!done.isCompleted) done.complete();
          };
          try {
            await done.future;
          } finally {
            await subscription.cancel();
            cancellation.cancelStream = null;
          }
          cancellation.check();
        }
      }
    }
    final nodes = [
      for (final n in snapshot.nodes)
        _aggregate(n, results[n.id]?.values.toList() ?? [], policy),
    ];
    return SmartAssessment(
      policy: policy,
      nodes: nodes,
      selection: selectSmartNode(policy, nodes),
      runtimeRevision: snapshot.revision,
      poolRevision: snapshot.poolRevision,
      evaluatedAt: DateTime.now(),
    );
  }

  SmartNode _aggregate(
    SmartNode node,
    List<pb.ProbeResult> results,
    SmartPolicy policy, {
    bool historyRow = false,
  }) {
    final passed =
        (historyRow || results.length == policy.probeTargets.length) &&
        results.isNotEmpty &&
        results.every(
          (r) => r.stage == pb.ProbeStage.PROBE_STAGE_READY && r.successes > 0,
        );
    final regions = results
        .map((r) => r.observedCountry)
        .where((r) => r.isNotEmpty)
        .toSet();
    final serviceRegions = results
        .map((r) => r.serviceCountry)
        .where((r) => r.isNotEmpty)
        .toSet();
    final losses =
        results
            .where((r) => r.packetLossAvailable)
            .map((r) => r.packetLossRatio)
            .toList()
          ..sort();
    final failures = results.where(
      (r) => r.stage != pb.ProbeStage.PROBE_STAGE_READY,
    );
    final attempts = results.fold<int>(0, (v, r) => v + r.attempts);
    final successes = results.fold<int>(0, (v, r) => v + r.successes);
    final times = results.map((r) => r.testedAtUnixMs.toInt()).toList()..sort();
    final expiry = results.map((r) => r.expiresAtUnixMs.toInt()).toList()
      ..sort();
    return SmartNode(
      id: node.id,
      name: node.name,
      subscriptionId: node.subscriptionId,
      protocol: node.protocol,
      region: node.region,
      enabled: node.enabled,
      tags: node.tags,
      excluded: node.excluded,
      favorite: node.favorite,
      subscriptionPriority: node.subscriptionPriority,
      observedRegion: regions.length == 1 ? regions.single : '',
      serviceRegion: serviceRegions.length == 1 ? serviceRegions.single : '',
      packetLoss: losses.length == results.length && losses.isNotEmpty
          ? losses.last
          : null,
      probePassed: passed && regions.length <= 1 && serviceRegions.length <= 1,
      successRate: attempts == 0 ? 0 : successes / attempts,
      latencyMs: results.isEmpty
          ? null
          : (results.fold<int>(0, (v, r) => v + r.latencyMilliseconds) /
                    results.length)
                .round(),
      testedAt: times.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(times.first),
      expiresAt: expiry.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiry.first),
      policyRevision: policy.revision,
      failureReason: regions.length > 1 || serviceRegions.length > 1
          ? 'Conflicting observed regions across targets'
          : failures.isNotEmpty
          ? failures.first.stage.name.replaceFirst('PROBE_STAGE_', '')
          : !passed
          ? 'Not all service targets returned a valid result'
          : '',
    );
  }

  @override
  Future<void> apply(SmartAssessment assessment, {String? manualNodeId}) async {
    final policy = assessment.policy;
    final eligible = selectSmartNode(policy, assessment.nodes);
    if (!eligible.succeeded) throw StateError(eligible.reason);
    final nodeId = eligible.direct
        ? 'direct'
        : manualNodeId ?? eligible.node!.id;
    if (!eligible.direct && !eligible.scores.containsKey(nodeId)) {
      throw StateError('Node is excluded or its probe has expired');
    }
    final current = await load();
    if (!eligible.direct) {
      final node = current.nodes.where((n) => n.id == nodeId).firstOrNull;
      if (node == null || smartCandidateExclusion(policy, node) != null) {
        throw StateError('Node preferences changed; re-evaluate');
      }
    }
    if (current.poolRevision != assessment.poolRevision) {
      throw StateError('Node pool changed; re-evaluate');
    }
    final config = await api.smartConfig();
    if (config.revision != assessment.runtimeRevision) {
      throw StateError('Runtime changed; re-evaluate');
    }
    final serviceId = '$prefix${policy.id}';
    final selectorTag = '$serviceId.selector';
    final now = DateTime.now();
    final model = _model(config);
    model.selectors.removeWhere((s) => s.tag == selectorTag);
    model.serviceRoutes.removeWhere((r) => r.serviceId == serviceId);
    model.serviceBindings.removeWhere((b) => b.serviceId == serviceId);
    // A singleton selector cannot silently switch to another candidate.
    model.selectors.add(
      pb.SelectorConfig(
        tag: selectorTag,
        nodeIds: [nodeId],
        selectedNodeId: nodeId,
      ),
    );
    model.serviceRoutes.add(
      pb.ServiceRoute(
        serviceId: serviceId,
        domains: policy.domains,
        selectorTag: selectorTag,
        enabled: true,
      ),
    );
    model.serviceBindings.add(
      pb.ServiceBinding(
        serviceId: serviceId,
        selectorTag: selectorTag,
        nodeId: nodeId,
        selectedAtUnixMs: Int64(now.millisecondsSinceEpoch),
        expiresAtUnixMs: Int64(
          now.add(policy.stickyDuration).millisecondsSinceEpoch,
        ),
        selectedScore: eligible.scores[nodeId] ?? 0,
        selectionReason: manualNodeId == null
            ? eligible.reason
            : 'Explicit manual selection; all policy checks passed',
        selectionPolicyRevision: policy.revision,
      ),
    );
    await api.updateSmartModel(model, config.revision);
  }

  pb.RuntimeModel _model(pb.RuntimeConfig config) => pb.RuntimeModel(
    selectors: config.selectors.map((s) => s.deepCopy()),
    serviceRoutes: config.serviceRoutes.map((r) => r.deepCopy()),
    serviceBindings: config.serviceBindings.map((b) => b.deepCopy()),
  );

  @override
  Future<void> disable() async {
    final config = await api.smartConfig();
    final model = _model(config);
    final ownedSelectors = model.serviceRoutes
        .where((r) => r.serviceId.startsWith(prefix))
        .map((r) => r.selectorTag)
        .toSet();
    final changed =
        ownedSelectors.isNotEmpty ||
        model.selectors.any((s) => s.tag.startsWith(prefix)) ||
        model.serviceBindings.any((b) => b.serviceId.startsWith(prefix));
    // Removing dormant selectors is essential: otherwise deleted subscription
    // nodes can invalidate later ordinary proxy config updates while opted out.
    model.serviceRoutes.removeWhere((r) => r.serviceId.startsWith(prefix));
    model.serviceBindings.removeWhere((b) => b.serviceId.startsWith(prefix));
    model.selectors.removeWhere(
      (s) => ownedSelectors.contains(s.tag) || s.tag.startsWith(prefix),
    );
    if (changed) await api.updateSmartModel(model, config.revision);
  }

  @override
  Future<void> remove(String policyId) async {
    final config = await api.smartConfig();
    final id = '$prefix$policyId';
    final model = _model(config);
    model.selectors.removeWhere((s) => s.tag == '$id.selector');
    model.serviceRoutes.removeWhere((r) => r.serviceId == id);
    model.serviceBindings.removeWhere((b) => b.serviceId == id);
    await api.updateSmartModel(model, config.revision);
  }

  @override
  Future<List<SmartNode>> history(SmartPolicy policy, String nodeId) async {
    final snapshot = await load();
    final node = snapshot.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return [];
    final rows = <SmartNode>[];
    for (var i = 0; i < policy.probeTargets.length; i++) {
      final history = await api.smartHistory(
        pb.QualityHistoryRequest(
          serviceId: _probeId(policy.id, i),
          nodeId: nodeId,
          limit: 100,
        ),
      );
      for (final result in history.results) {
        rows.add(_aggregate(node, [result], policy, historyRow: true));
      }
    }
    rows.sort((a, b) => b.testedAt!.compareTo(a.testedAt!));
    return rows;
  }
}

