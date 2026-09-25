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

  final String id;
  final String name;
  final String type;
  final String? selectedNodeId;
  final List<ProxyNode> nodes;

  ProxyNode? get selectedNode {
    if (selectedNodeId == null) return null;
    for (final node in nodes) {
      if (node.id == selectedNodeId) return node;
    }
    return null;
  }

  ProxyGroup copyWith({
    String? name,
    String? type,
    String? selectedNodeId,
    bool clearSelection = false,
    List<ProxyNode>? nodes,
  }) {
    return ProxyGroup(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      selectedNodeId: clearSelection ? null : selectedNodeId ?? this.selectedNodeId,
      nodes: nodes ?? this.nodes,
    );
  }
}
