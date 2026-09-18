import 'dart:async';
import 'package:targetlib/targetlib.dart' as pb;
import '../../../core/runtime/core_gateway.dart';
import '../../../core/runtime/smart_runtime_gateway.dart';
import '../domain/smart_connect_models.dart';
import '../domain/smart_runtime_models.dart';
import 'smart_connect_repository.dart';
import 'smart_policy_store.dart';

/// Intent-capable TargetLib is authoritative for policy, scoring and binding.
class IntentSmartConnectRepository implements SmartConnectRepository {
  IntentSmartConnectRepository(this.core, this.api, this.store);
  final CoreGateway core;
  final SmartIntentGateway api;
  final SmartPolicyStore store;
  static const prefix = 'target.smart.';
  int _nonce = 0;
  String _key() => '${DateTime.now().microsecondsSinceEpoch}-${_nonce++}';
  String _id(String id) => '$prefix$id';

  Future<pb.Operation> _wait(
    pb.Operation operation, {
    SmartCancellation? cancellation,
  }) async {
    for (var i = 0; i < 120; i++) {
      if (cancellation?.cancelled == true) {
        // There is no cancellation command in the core contract. The operation
        // continues; its proposal is rejected once it has materialized.
        if (operation.status ==
                pb.OperationStatus.OPERATION_STATUS_WAITING_APPROVAL &&
            operation.proposalId.isNotEmpty) {
          final snapshot = await api.smartSnapshot();
          await api.rejectSmartProposal(
            pb.ProposalCommandRequest(
              proposalId: operation.proposalId,
              expectedRevision: snapshot.revision,
              idempotencyKey: _key(),
            ),
          );
          throw StateError('Evaluation cancelled');
        }
      }
      if (operation.status == pb.OperationStatus.OPERATION_STATUS_SUCCEEDED ||
          operation.status ==
              pb.OperationStatus.OPERATION_STATUS_WAITING_APPROVAL) {
        return operation;
      }
      if (operation.status == pb.OperationStatus.OPERATION_STATUS_FAILED ||
          operation.status == pb.OperationStatus.OPERATION_STATUS_CANCELLED ||
          operation.status == pb.OperationStatus.OPERATION_STATUS_ROLLED_BACK) {
        throw StateError('${operation.errorCode}: ${operation.errorMessage}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      operation = await api.smartOperation(operation.id);
    }
    throw TimeoutException(
      'Smart Connect operation is still running; refresh its status',
    );
  }

  Future<void> enable() async {
    final snapshot = await api.smartSnapshot();
    if (!snapshot.enabled) {
      await _wait(
        await api.setSmartEnabled(
          pb.SetSmartConnectEnabledRequest(
            enabled: true,
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
    }
  }

  Future<void> reconcileDisabled() async {
    final snapshot = await api.smartSnapshot();
    if (snapshot.enabled) await disable();
  }

  @override
  Future<void> disable() async {
    final snapshot = await api.smartSnapshot();
    if (snapshot.enabled) {
      await _wait(
        await api.setSmartEnabled(
          pb.SetSmartConnectEnabledRequest(
            enabled: false,
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
    }
  }

  @override
  Future<SmartRuntimeSnapshot> load() async {
    final caps = await (core as SmartRuntimeGateway).smartCapabilities();
    if (!caps.smartConnectIntentApi) {
      throw UnsupportedError(
        'TargetLib intent API is unavailable; update the core',
      );
    }
    final snapshot = await api.smartSnapshot();
    final pool = await core.getNodePool();
    final config = await (core as SmartRuntimeGateway).smartConfig();
    final runtime = await core.getSmartConnectRuntimeState();
    final localPolicies = {for (final p in await store.load()) p.id: p};
    final bindings = <String, SmartBinding>{};
    for (final b in config.serviceBindings.where(
      (b) => b.serviceId.startsWith(prefix),
    )) {
      final states = runtime.serviceBindings.where(
        (s) => s.desired.serviceId == b.serviceId,
      );
      final actual = states.firstOrNull;
      bindings[b.serviceId.substring(prefix.length)] = SmartBinding(
        serviceId: b.serviceId.substring(prefix.length),
        nodeId: b.nodeId,
        selectedAt: DateTime.fromMillisecondsSinceEpoch(
          b.selectedAtUnixMs.toInt(),
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          b.expiresAtUnixMs.toInt(),
        ),
        reason: b.selectionReason,
        score: b.selectedScore,
        policyRevision:
            snapshot.policies.any(
              (p) =>
                  p.serviceId == b.serviceId &&
                  p.revision == b.selectionPolicyRevision &&
                  localPolicies.containsKey(
                    b.serviceId.substring(prefix.length),
                  ) &&
                  _samePolicy(
                    p,
                    localPolicies[b.serviceId.substring(prefix.length)]!,
                  ),
            )
            ? localPolicies[b.serviceId.substring(prefix.length)]!.revision
            : '',
        effective: actual?.effective ?? false,
        needsEvaluation: actual?.needsEvaluation ?? true,
        status: actual?.evaluationReason ?? 'Runtime status unavailable',
      );
    }
    final preferences = {for (final p in snapshot.nodePreferences) p.nodeId: p};
    return SmartRuntimeSnapshot(
      nodes: [
        for (final n in pool.nodes)
          SmartNode(
            id: n.tag,
            name: n.name,
            subscriptionId: n.subscriptionId,
            protocol: n.type,
            region: n.countryCode,
            enabled:
                (preferences[n.tag]?.enabled ?? true) &&
                n.phase != pb.ProfileNodePhase.PROFILE_NODE_PHASE_FAILED,
            excluded: preferences[n.tag]?.excluded ?? false,
            favorite: preferences[n.tag]?.favorite ?? false,
            tags: preferences[n.tag]?.labels.toSet() ?? {},
            subscriptionPriority: preferences[n.tag]?.subscriptionPriority ?? 0,
          ),
      ],
      bindings: bindings,
      revision: config.revision,
      poolRevision: pool.revision,
      running: runtime.running,
      eventsSupported: caps.runtimeEvents,
    );
  }

  @override
  Stream<void> events() => api.smartIntentEvents().map((_) {});

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

  bool _samePolicy(pb.ServicePolicy saved, SmartPolicy policy) {
    bool sameSet<T>(Iterable<T> a, Iterable<T> b) =>
        a.toSet().length == b.toSet().length && a.toSet().containsAll(b);
    if (saved.displayName != policy.name ||
        !sameSet(saved.domains, policy.domains) ||
        saved.probes.length != policy.probeTargets.length ||
        !sameSet(saved.selection.preferredCountries, policy.preferredRegions) ||
        !sameSet(
          saved.selection.subscriptionIds,
          policy.allowedSubscriptions,
        ) ||
        !sameSet(saved.selection.excludedNodeIds, policy.excludedNodes) ||
        !sameSet(saved.switchPolicy.allowedCountries, policy.allowedRegions) ||
        saved.bindingValiditySeconds != policy.stickyDuration.inSeconds ||
        saved.qualityValiditySeconds != policy.probeValidity.inSeconds ||
        saved.switchPolicy.mode !=
            (policy.selectionMode == SmartSelectionMode.direct
                ? pb.SwitchMode.SWITCH_MODE_DIRECT
                : pb.SwitchMode.SWITCH_MODE_MANUAL)) {
      return false;
    }
    for (var i = 0; i < saved.probes.length; i++) {
      final a = saved.probes[i], b = policy.probeTargets[i];
      if (a.url != b.url ||
          a.bodyContains != b.bodyContains ||
          a.egressUrl != b.egressUrl ||
          a.serviceCountryHeader != b.serviceCountryHeader ||
          !sameSet(a.expectedStatus, b.expectedStatus)) {
        return false;
      }
    }
    return true;
  }

  Future<void> syncPolicy(SmartPolicy policy) async {
    if (policy.requiredTags.isNotEmpty) {
      throw UnsupportedError(
        'This TargetLib policy API cannot enforce required node tags',
      );
    }
    final snapshot = await api.smartSnapshot();
    final existing = snapshot.policies
        .where((p) => p.serviceId == _id(policy.id))
        .firstOrNull;
    if (existing == null || !_samePolicy(existing, policy)) {
      await _wait(
        await api.upsertSmartPolicy(
          pb.UpsertServicePolicyRequest(
            policy: _policy(policy),
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
    }
  }

  @override
  Future<SmartAssessment> evaluate(
    SmartPolicy policy,
    SmartCancellation cancellation,
  ) async {
    final errors = policy.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('; '));
    await enable();
    await syncPolicy(policy);
    final snapshot = await api.smartSnapshot();
    cancellation.check();
    if (policy.selectionMode == SmartSelectionMode.direct) {
      final current = await load();
      return SmartAssessment(
        policy: policy,
        nodes: current.nodes,
        selection: const SmartSelection(
          direct: true,
          reason: 'Explicit Direct policy',
        ),
        runtimeRevision: current.revision,
        poolRevision: current.poolRevision,
        evaluatedAt: DateTime.now(),
      );
    }
    final operation = await _wait(
      await api.requestSmartEvaluation(
        pb.RequestServiceEvaluationRequest(
          serviceId: _id(policy.id),
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
      cancellation: cancellation,
    );
    cancellation.check();
    final latest = await api.smartSnapshot();
    final proposal = latest.proposals
        .where((p) => p.id == operation.proposalId)
        .firstOrNull;
    if (proposal == null) {
      throw StateError('Evaluation completed without a proposal');
    }
    final current = await load();
    final nodes = {for (final n in current.nodes) n.id: n};
    final scores = {
      for (final c in proposal.candidates.where((c) => c.eligible))
        c.nodeId: c.score,
    };
    final excluded = {
      for (final c in proposal.candidates.where((c) => !c.eligible))
        c.nodeId: c.reason,
    };
    final selected = nodes[proposal.suggestedNodeId];
    return SmartAssessment(
      policy: policy,
      nodes: current.nodes,
      selection: SmartSelection(
        node: selected,
        scores: scores,
        excluded: excluded,
        direct: proposal.suggestedNodeId == 'direct',
        reason: proposal.reason,
      ),
      runtimeRevision: current.revision,
      poolRevision: current.poolRevision,
      evaluatedAt: DateTime.fromMillisecondsSinceEpoch(
        proposal.createdAtUnixMs.toInt(),
      ),
      proposalId: proposal.id,
    );
  }

  @override
  Future<void> apply(SmartAssessment assessment, {String? manualNodeId}) async {
    final snapshot = await api.smartSnapshot();
    if (manualNodeId != null || assessment.selection.direct) {
      final nodeId = manualNodeId ?? 'direct';
      if (!assessment.selection.direct &&
          !assessment.selection.scores.containsKey(nodeId)) {
        throw StateError('Node is not eligible in the latest evaluation');
      }
      await _wait(
        await api.forceSmartBinding(
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
      await api.approveSmartProposal(
        pb.ProposalCommandRequest(
          proposalId: proposal.id,
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
    );
  }

  @override
  Future<void> remove(String policyId) async {
    final snapshot = await api.smartSnapshot();
    if (snapshot.policies.any((p) => p.serviceId == _id(policyId))) {
      await _wait(
        await api.deleteSmartPolicy(
          pb.DeleteServicePolicyRequest(
            serviceId: _id(policyId),
            expectedRevision: snapshot.revision,
            idempotencyKey: _key(),
          ),
        ),
      );
    }
  }

  Future<void> setPreference(
    SmartNode node,
    SmartNodePreference preference,
    int priority,
  ) async {
    final snapshot = await api.smartSnapshot();
    await _wait(
      await api.setSmartPreference(
        pb.SetNodePreferenceRequest(
          preference: pb.NodePreference(
            nodeId: node.id,
            enabled: preference.enabled,
            excluded: preference.excluded,
            favorite: preference.favorite,
            labels: preference.tags.toList(),
            subscriptionPriority: priority,
          ),
          expectedRevision: snapshot.revision,
          idempotencyKey: _key(),
        ),
      ),
    );
  }

  @override
  Future<List<SmartNode>> history(SmartPolicy policy, String nodeId) async {
    final snapshot = await api.smartSnapshot();
    final node = (await load()).nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return [];
    return [
      for (final r in snapshot.results.where(
        (r) => r.serviceId == _id(policy.id) && r.nodeId == nodeId,
      ))
        SmartNode(
          id: node.id,
          name: node.name,
          region: node.region,
          latencyMs: r.latencyMilliseconds,
          observedRegion: r.observedCountry,
          testedAt: DateTime.fromMillisecondsSinceEpoch(
            r.testedAtUnixMs.toInt(),
          ),
          failureReason: r.stage == pb.ProbeStage.PROBE_STAGE_READY
              ? ''
              : r.stage.name,
        ),
    ];
  }
}
