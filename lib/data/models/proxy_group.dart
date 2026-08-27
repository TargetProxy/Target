import 'package:flutter/foundation.dart';

import 'proxy_node.dart';

@immutable
class ProxyGroup {
  const ProxyGroup({
    required this.id,
    required this.name,
    required this.type,
    this.selectedNodeId,
    this.nodes = const [],
  });

  /// Tag of the selector group that TargetLib generates for every profile
  /// (config.Build always emits a single selector named `proxy`). Selections
  /// in this group are applied to the runtime core via SelectOutbound.
  static const runtimeSelectorGroupId = 'proxy';

  bool get isRuntimeSelector => id == runtimeSelectorGroupId;

  final String id;
  final String name;
  final String type;
  final String? selectedNodeId;
  final List<ProxyNode> nodes;

  ProxyNode? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return nodes.firstWhere((n) => n.id == selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  ProxyGroup copyWith({
    String? id,
    String? name,
    String? type,
    String? selectedNodeId,
    List<ProxyNode>? nodes,
  }) {
    return ProxyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      nodes: nodes ?? this.nodes,
    );
  }
}
