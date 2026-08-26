import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/proxy_group.dart';
import '../../../data/models/proxy_node.dart';

/// Immutable snapshot of the parsed proxy catalog.
@immutable
class ProxyCatalogState {
  const ProxyCatalogState({this.groups = const []});

  final List<ProxyGroup> groups;

  ProxyCatalogState copyWith({List<ProxyGroup>? groups}) {
    return ProxyCatalogState(groups: groups ?? this.groups);
  }
}

class ProxyCatalogNotifier extends Notifier<ProxyCatalogState> {
  @override
  ProxyCatalogState build() => const ProxyCatalogState();

  void clear() {
    if (state.groups.isEmpty) return;
    state = const ProxyCatalogState();
  }

  void replaceGroups(List<ProxyGroup> sourceGroups) {
    final previousSelections = {
      for (final group in state.groups) group.id: group.selectedNodeId,
    };
    state = ProxyCatalogState(
      groups: [
        for (final group in sourceGroups)
          _mergeGroup(group, previousSelections[group.id]),
      ],
    );
  }

  ProxyGroup _mergeGroup(ProxyGroup source, String? previousSelection) {
    final nodes = _mergeLatency(source.nodes);
    final selected = _restoreSelection(
      previousSelection ?? source.selectedNodeId,
      nodes,
    );
    return source.copyWith(
      selectedNodeId: selected,
      nodes: _markSelected(nodes, selected),
    );
  }

  void selectNode(String groupId, String nodeId) {
    state = state.copyWith(
      groups: [
        for (final group in state.groups)
          if (group.id == groupId)
            group.copyWith(
              selectedNodeId: nodeId,
              nodes: _markSelected(group.nodes, nodeId),
            )
          else
            group,
      ],
    );
  }

  List<ProxyNode> _mergeLatency(List<ProxyNode> nodes) {
    final previous = <String, ProxyNode>{};
    for (final group in state.groups) {
      for (final node in group.nodes) {
        previous[node.id] = node;
      }
    }
    return [
      for (final node in nodes)
        node.copyWith(latencyMs: previous[node.id]?.latencyMs),
    ];
  }

  String? _restoreSelection(String? previous, List<ProxyNode> nodes) {
    if (previous != null && nodes.any((node) => node.id == previous)) {
      return previous;
    }
    return nodes.isEmpty ? null : nodes.first.id;
  }

  List<ProxyNode> _markSelected(List<ProxyNode> nodes, String? selectedNodeId) {
    final selected = _restoreSelection(selectedNodeId, nodes);
    return [
      for (final node in nodes) node.copyWith(isSelected: node.id == selected),
    ];
  }
}

final proxyCatalogProvider =
    NotifierProvider<ProxyCatalogNotifier, ProxyCatalogState>(
      ProxyCatalogNotifier.new,
    );
