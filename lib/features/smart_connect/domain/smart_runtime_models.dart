import '../../../data/models/proxy_node.dart';
import 'smart_connect_models.dart';

/// A service binding as the core reports it. The core owns every field here,
/// so nothing is reconciled against a local copy.
class SmartBinding {
  const SmartBinding({
    required this.serviceId,
    required this.nodeId,
    required this.selectedAt,
    required this.expiresAt,
    required this.reason,
    this.score = 0,
    this.effective = false,
    this.needsEvaluation = false,
    this.status = '',
  });
  final String serviceId, nodeId, reason, status;
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
    this.defaultNodeId,
    this.actualDefaultNodeId,
    this.defaultEffective = false,
    this.loaded = false,
  });
  final List<ProxyNode> nodes;
  final Map<String, SmartBinding> bindings;
  final String revision, poolRevision;
  final bool running, eventsSupported;
  final String? defaultNodeId, actualDefaultNodeId;
  final bool defaultEffective, loaded;
}

/// One evaluation result from the core, awaiting an explicit apply.
class SmartAssessment {
  const SmartAssessment({
    required this.policy,
    required this.nodes,
    required this.selection,
    required this.poolRevision,
    required this.evaluatedAt,
    this.proposalId,
  });
  final SmartPolicy policy;
  final List<ProxyNode> nodes;
  final SmartSelection selection;
  final String poolRevision;
  final DateTime evaluatedAt;
  final String? proposalId;
}

class SmartSelection {
  const SmartSelection({
    this.node,
    required this.reason,
    this.excluded = const {},
    this.scores = const {},
    this.direct = false,
  });
  final ProxyNode? node;
  final String reason;
  final Map<String, String> excluded;
  final Map<String, double> scores;
  final bool direct;
  bool get succeeded => direct || node != null;
}
