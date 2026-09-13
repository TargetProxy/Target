import 'smart_connect_models.dart';

class SmartBinding {
  const SmartBinding({
    required this.serviceId,
    required this.nodeId,
    required this.selectedAt,
    required this.expiresAt,
    required this.reason,
    this.score = 0,
    this.policyRevision = '',
    this.effective = false,
    this.needsEvaluation = false,
    this.status = '',
  });
  final String serviceId, nodeId, reason, policyRevision, status;
  final DateTime selectedAt, expiresAt;
  final double score;
  final bool effective, needsEvaluation;
  bool get valid => !needsEvaluation && DateTime.now().isBefore(expiresAt);
}

class SmartRuntimeSnapshot {
  const SmartRuntimeSnapshot({
    this.nodes = const [],
    this.bindings = const {},
    this.revision = '',
    this.poolRevision = '',
    this.running = false,
    this.eventsSupported = false,
  });
  final List<SmartNode> nodes;
  final Map<String, SmartBinding> bindings;
  final String revision, poolRevision;
  final bool running, eventsSupported;
}

class SmartAssessment {
  const SmartAssessment({
    required this.policy,
    required this.nodes,
    required this.selection,
    required this.runtimeRevision,
    required this.poolRevision,
    required this.evaluatedAt,
  });
  final SmartPolicy policy;
  final List<SmartNode> nodes;
  final SmartSelection selection;
  final String runtimeRevision, poolRevision;
  final DateTime evaluatedAt;
}
