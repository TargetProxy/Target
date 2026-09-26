import 'dart:async';
import 'dart:convert';

import 'package:targetlib/targetlib.dart' as pb;

import '../../../core/runtime/core_gateway.dart';
import '../../../data/models/proxy_node.dart';
import '../domain/smart_connect_models.dart';
import '../domain/smart_runtime_models.dart';

/// Cancels the app's interest in an evaluation. The core contract has no
/// cancellation RPC, so the operation keeps running and its proposal is
/// rejected once it materializes.
class SmartCancellation {
  bool cancelled = false;
  void cancel() => cancelled = true;
  void check() {
    if (cancelled) throw StateError('Evaluation cancelled');
  }
}

/// Translates between the app's models and the core's intent API.
///
/// The core is authoritative for policy, scoring and binding, so there is no
/// local copy to reconcile and no interface seam: tests substitute a fake
/// [CoreGateway] instead.
class SmartConnectRepository {
  SmartConnectRepository(this.core);

  final CoreGateway core;

  static const prefix = 'target.smart.';
  int _nonce = 0;
  String _key() => '${DateTime.now().microsecondsSinceEpoch}-${_nonce++}';
  String _id(String id) => '$prefix$id';

  Future<pb.Operation> _wait(
    pb.Operation operation, {
    SmartCancellation? cancellation,
  }) async {
    for (var i = 0; i < 120; i++) {
      final waitingApproval =
          operation.status ==
          pb.OperationStatus.OPERATION_STATUS_WAITING_APPROVAL;
      if (cancellation?.cancelled == true &&
          waitingApproval &&
          operation.proposalId.isNotEmpty) {
        final snapshot = await core.smartSnapshot();
        await core.rejectSmartProposal(
          pb.ProposalCommandRequest(
            proposalId: operation.proposalId,
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        );
        throw StateError('Evaluation cancelled');
      }
      if (operation.status == pb.OperationStatus.OPERATION_STATUS_SUCCEEDED ||
          waitingApproval) {
        return operation;
      }
      if (operation.status == pb.OperationStatus.OPERATION_STATUS_FAILED ||
          operation.status == pb.OperationStatus.OPERATION_STATUS_CANCELLED ||
          operation.status == pb.OperationStatus.OPERATION_STATUS_ROLLED_BACK) {
        throw StateError('${operation.errorCode}: ${operation.errorMessage}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      operation = await core.smartOperation(operation.id);
    }
    throw TimeoutException(
      'Smart Connect operation is still running; refresh its status',
    );
  }

  Future<SmartRuntimeSnapshot> load() async {
    final capabilities = await core.smartCapabilities();
    if (!capabilities.smartConnectIntentApi) {
      throw UnsupportedError(
        'TargetLib intent API is unavailable; update the core',
      );
    }
    final snapshot = await core.smartSnapshot();
    final pool = await core.getNodePool();
    final config = await core.smartConfig();
    final runtime = await core.getSmartConnectRuntimeState();
    final defaultSelector = config.selectors
        .where((selector) => selector.tag == 'proxy')
        .firstOrNull;
    final actualDefault = runtime.selectors
        .where((selector) => selector.desired.tag == 'proxy')
        .firstOrNull;
    return SmartRuntimeSnapshot(
      nodes: _nodes(pool, snapshot),
      bindings: _bindings(config, runtime),
      revision: config.revision,
      poolRevision: pool.revision,
      running: runtime.running,
      eventsSupported: capabilities.runtimeEvents,
      defaultNodeId: defaultSelector?.selectedNodeId,
      actualDefaultNodeId: actualDefault?.actualNodeId,
      defaultEffective: actualDefault?.effective ?? false,
      loaded: true,
    );
  }

  List<ProxyNode> _nodes(pb.NodePool pool, pb.SmartConnectSnapshot snapshot) {
    final preferences = {
      for (final preference in snapshot.nodePreferences)
        preference.nodeId: preference,
    };
    return [
      for (final node in pool.nodes)
        ProxyNode(
          id: node.tag,
          name: node.name.isEmpty ? node.tag : node.name,
          type: node.type,
          subscriptionId: node.subscriptionId,
          countryCode: node.countryCode.isEmpty ? null : node.countryCode,
          server: node.server,
          port: node.port,
          isAvailable:
              node.phase != pb.ProfileNodePhase.PROFILE_NODE_PHASE_FAILED,
          enabled:
              (preferences[node.tag]?.enabled ?? true) &&
              node.phase != pb.ProfileNodePhase.PROFILE_NODE_PHASE_FAILED,
          excluded: preferences[node.tag]?.excluded ?? false,
          favorite: preferences[node.tag]?.favorite ?? false,
          tags: preferences[node.tag]?.labels.toSet() ?? const {},
          subscriptionPriority:
              preferences[node.tag]?.subscriptionPriority ?? 0,
        ),
    ];
  }

  Map<String, SmartBinding> _bindings(
    pb.RuntimeConfig config,
    pb.RuntimeState runtime,
  ) {
    final states = {
      for (final state in runtime.serviceBindings)
        state.desired.serviceId: state,
    };
    return {
      for (final binding in config.serviceBindings)
        if (binding.serviceId.startsWith(prefix))
          binding.serviceId.substring(prefix.length): SmartBinding(
            serviceId: binding.serviceId.substring(prefix.length),
            nodeId: binding.nodeId,
            effective: states[binding.serviceId]?.effective ?? false,
            needsEvaluation: states[binding.serviceId]?.needsEvaluation ?? true,
          ),
    };
  }

  Stream<void> events() => core.smartIntentEvents().map((_) {});

  pb.ServicePolicy _policy(SmartPolicy policy) => pb.ServicePolicy(
    serviceId: _id(policy.id),
    displayName: policy.name,
    domains: policy.domains.toList(),
    probes: [
      for (final target in policy.probeTargets)
        pb.ServiceProbe(
          serviceId: _id(policy.id),
          url: target.url,
          expectedStatus: target.expectedStatus.toList(),
          bodyContains: target.bodyContains,
          allowedCountries: policy.allowedRegions.toList(),
          egressUrl: target.egressUrl,
          serviceCountryHeader: target.serviceCountryHeader,
          timeoutMilliseconds: 10000,
          validitySeconds: policy.probeValidity.inSeconds,
        ),
    ],
    selection: pb.ServiceSelectionPolicy(
      serviceId: _id(policy.id),
      preferredCountries: policy.preferredRegions.toList(),
      subscriptionIds: policy.allowedSubscriptions.toList(),
      excludedNodeIds: policy.excludedNodes.toList(),
      allowDirect: policy.selectionMode == SmartSelectionMode.direct,
    ),
    switchPolicy: pb.SwitchPolicy(
      mode: policy.selectionMode == SmartSelectionMode.direct
          ? pb.SwitchMode.SWITCH_MODE_DIRECT
          : pb.SwitchMode.SWITCH_MODE_MANUAL,
      allowedCountries: policy.allowedRegions.toList(),
      allowedSubscriptionIds: policy.allowedSubscriptions.toList(),
      allowDirect: policy.selectionMode == SmartSelectionMode.direct,
    ),
    bindingValiditySeconds: policy.stickyDuration.inSeconds,
    qualityValiditySeconds: policy.probeValidity.inSeconds,
  );

  /// Pushes the policy unconditionally. The core stores it and returns the
  /// revision it recorded, so the app does not compare field by field first.
  Future<String> syncPolicy(
    SmartPolicy policy, {
    String? expectedRevision,
  }) async {
    final revision = expectedRevision ?? (await core.smartSnapshot()).revision;
    final operation = await _wait(
      await core.upsertSmartPolicy(
        pb.UpsertServicePolicyRequest(
          policy: _policy(policy),
          expectedRevision: revision,
          idempotencyKey: _key(),
        ),
      ),
    );
    return operation.runtimeRevision.isEmpty
        ? revision
        : operation.runtimeRevision;
  }

  Future<SmartAssessment> evaluate(
    SmartPolicy policy,
    SmartCancellation cancellation,
  ) async {
    final errors = policy.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    await syncPolicy(policy);
    cancellation.check();
    final snapshot = await core.smartSnapshot();
    if (policy.selectionMode == SmartSelectionMode.direct) {
      final pool = await core.getNodePool();
      return SmartAssessment(
        policy: policy,
        selection: const SmartSelection(
          direct: true,
          reason: 'Explicit Direct policy',
        ),
        poolRevision: pool.revision,
      );
    }
    final operation = await _wait(
      await core.requestSmartEvaluation(
        pb.RequestServiceEvaluationRequest(
          serviceId: _id(policy.id),
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
      cancellation: cancellation,
    );
    cancellation.check();
    final latest = await core.smartSnapshot();
    final proposal = latest.proposals
        .where((p) => p.id == operation.proposalId)
        .firstOrNull;
    if (proposal == null) {
      throw StateError('Evaluation completed without a proposal');
    }
    final pool = await core.getNodePool();
    final nodes = _nodes(pool, latest);
    return SmartAssessment(
      policy: policy,
      selection: SmartSelection(
        node: nodes.where((n) => n.id == proposal.suggestedNodeId).firstOrNull,
        scores: {
          for (final c in proposal.candidates.where((c) => c.eligible))
            c.nodeId: c.score,
        },
        excluded: {
          for (final c in proposal.candidates.where((c) => !c.eligible))
            c.nodeId: c.reason,
        },
        direct: proposal.suggestedNodeId == 'direct',
        reason: proposal.reason,
      ),
      poolRevision: pool.revision,
      proposalId: proposal.id,
    );
  }

  /// Applies a usable first choice immediately. Quality evaluation can refine
  /// this choice later, but it is not required before the service works.
  Future<void> connectDefault(SmartPolicy policy) async {
    final errors = policy.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    await syncPolicy(policy);
    final snapshot = await core.smartSnapshot();
    if (policy.selectionMode == SmartSelectionMode.direct) {
      await _forceBinding(policy.id, 'direct', snapshot.revision);
      return;
    }
    final pool = await core.getNodePool();
    final nodes = _nodes(pool, snapshot).where((node) {
      final region = node.effectiveCountryCode;
      return node.isAvailable &&
          node.enabled &&
          !node.excluded &&
          (policy.allowedRegions.isEmpty ||
              policy.allowedRegions.contains(region)) &&
          (policy.allowedSubscriptions.isEmpty ||
              policy.allowedSubscriptions.contains(node.subscriptionId));
    }).toList();
    nodes.sort((a, b) {
      final aPreferred = policy.preferredRegions.contains(
        a.effectiveCountryCode,
      );
      final bPreferred = policy.preferredRegions.contains(
        b.effectiveCountryCode,
      );
      if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      final priority = b.subscriptionPriority.compareTo(a.subscriptionPriority);
      if (priority != 0) return priority;
      final aLatency = a.latencyMs ?? 1 << 30;
      final bLatency = b.latencyMs ?? 1 << 30;
      final latency = aLatency.compareTo(bLatency);
      return latency != 0 ? latency : a.name.compareTo(b.name);
    });
    if (nodes.isEmpty) {
      throw StateError('No available node matches this service');
    }
    await _forceBinding(policy.id, nodes.first.id, snapshot.revision);
  }

  /// Applies an explicit node choice for one service route. This is the
  /// service-level counterpart of selecting the global Default node.
  Future<void> forceNode(SmartPolicy policy, String nodeId) async {
    final errors = policy.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    if (policy.selectionMode == SmartSelectionMode.direct) {
      throw StateError('Direct routes do not use a proxy node');
    }
    final snapshot = await core.smartSnapshot();
    final pool = await core.getNodePool();
    final node = _nodes(
      pool,
      snapshot,
    ).where((candidate) => candidate.id == nodeId).firstOrNull;
    if (node == null || !_eligibleFor(node, policy)) {
      throw StateError('Node is not eligible for this service');
    }
    await syncPolicy(policy, expectedRevision: snapshot.revision);
    await _forceBinding(
      policy.id,
      nodeId,
      (await core.smartSnapshot()).revision,
    );
  }

  Future<void> selectDefault(String nodeId) =>
      core.selectOutbound('proxy', nodeId);

  Future<void> applyRoute(
    SmartPolicy policy, {
    String? nodeId,
    SmartAssessment? assessment,
  }) async {
    if (!policy.enabled ||
        policy.selectionMode == SmartSelectionMode.followDefault) {
      await remove(policy.id);
      return;
    }
    switch (policy.selectionMode) {
      case SmartSelectionMode.manual:
        if (nodeId == null) throw StateError('Choose a node for this group');
        await forceNode(policy, nodeId);
      case SmartSelectionMode.direct:
        await syncPolicy(policy);
        await _forceBinding(
          policy.id,
          'direct',
          (await core.smartSnapshot()).revision,
        );
      case SmartSelectionMode.automatic:
        if (assessment == null) {
          throw StateError('Get a recommendation before applying');
        }
        if (jsonEncode(assessment.policy.toJson()) !=
            jsonEncode(policy.toJson())) {
          throw StateError('Group settings changed; get a new recommendation');
        }
        await apply(assessment);
      case SmartSelectionMode.followDefault:
        break;
    }
  }

  bool _eligibleFor(ProxyNode node, SmartPolicy policy) {
    final region = node.effectiveCountryCode;
    return node.isAvailable &&
        node.enabled &&
        !node.excluded &&
        !policy.excludedNodes.contains(node.id) &&
        (policy.allowedRegions.isEmpty ||
            policy.allowedRegions.contains(region)) &&
        (policy.allowedSubscriptions.isEmpty ||
            policy.allowedSubscriptions.contains(node.subscriptionId));
  }

  Future<void> _forceBinding(
    String policyId,
    String nodeId,
    String revision,
  ) async {
    await _wait(
      await core.forceSmartBinding(
        pb.ForceServiceBindingRequest(
          serviceId: _id(policyId),
          nodeId: nodeId,
          expectedRevision: revision,
          idempotencyKey: _key(),
        ),
      ),
    );
  }

  Future<void> apply(SmartAssessment assessment, {String? manualNodeId}) async {
    final snapshot = await core.smartSnapshot();
    if (manualNodeId != null || assessment.selection.direct) {
      final nodeId = manualNodeId ?? 'direct';
      if (!assessment.selection.direct &&
          !assessment.selection.scores.containsKey(nodeId)) {
        throw StateError('Node is not eligible in the latest evaluation');
      }
      await _wait(
        await core.forceSmartBinding(
          pb.ForceServiceBindingRequest(
            serviceId: _id(assessment.policy.id),
            nodeId: nodeId,
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
      return;
    }
    final proposal = snapshot.proposals
        .where((p) => p.id == assessment.proposalId)
        .firstOrNull;
    if (proposal == null ||
        proposal.expiresAtUnixMs.toInt() <=
            DateTime.now().millisecondsSinceEpoch ||
        proposal.nodePoolRevision != assessment.poolRevision) {
      throw StateError('Proposal expired or node pool changed; re-evaluate');
    }
    await _wait(
      await core.approveSmartProposal(
        pb.ProposalCommandRequest(
          proposalId: proposal.id,
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
    );
  }

  Future<void> remove(String policyId) async {
    final snapshot = await core.smartSnapshot();
    if (snapshot.policies.any((p) => p.serviceId == _id(policyId))) {
      await _wait(
        await core.deleteSmartPolicy(
          pb.DeleteServicePolicyRequest(
            serviceId: _id(policyId),
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
    }
  }

  Future<void> setPreference(String nodeId, NodePreference preference) async {
    final snapshot = await core.smartSnapshot();
    await _wait(
      await core.setSmartPreference(
        pb.SetNodePreferenceRequest(
          preference: pb.NodePreference(
            nodeId: nodeId,
            enabled: preference.enabled,
            excluded: preference.excluded,
            favorite: preference.favorite,
            labels: preference.tags.toList(),
            subscriptionPriority: preference.subscriptionPriority,
          ),
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
    );
  }

  /// Probe results the core recorded for one node, newest last.
  Future<List<ProxyNode>> history(SmartPolicy policy, String nodeId) async {
    final snapshot = await core.smartSnapshot();
    final pool = await core.getNodePool();
    final node = _nodes(
      pool,
      snapshot,
    ).where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return const [];
    return [
      for (final result in snapshot.results.where(
        (r) => r.serviceId == _id(policy.id) && r.nodeId == nodeId,
      ))
        node.copyWith(
          latencyMs: result.latencyMilliseconds,
          observedCountryCode: result.observedCountry,
        ),
    ];
  }
}
