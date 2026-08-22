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

  void replaceNodes(List<ProxyNode> sourceNodes) {
    if (sourceNodes.isEmpty) {
      return;
    }

    final previousSelections = {
      for (final group in state.groups) group.id: group.selectedNodeId,
    };
    final nodes = _mergeLatency(sourceNodes);
    final nextGroups = <ProxyGroup>[
      ProxyGroup(
        id: 'all',
        name: 'All',
        type: 'select',
        selectedNodeId: _restoreSelection(previousSelections['all'], nodes),
        nodes: _markSelected(nodes, previousSelections['all']),
      ),
    ];

    final grouped = <String, List<ProxyNode>>{};
    for (final node in nodes) {
      final groupName = node.metadata['group'] as String?;
      if (groupName == null || groupName.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(groupName, () => []).add(node);
    }

    for (final entry in grouped.entries) {
      final id = _groupId(entry.key);
      final selected = _restoreSelection(previousSelections[id], entry.value);
      nextGroups.add(
        ProxyGroup(
          id: id,
          name: entry.key,
          type: 'select',
          selectedNodeId: selected,
          nodes: _markSelected(entry.value, selected),
        ),
      );
    }

    final directNode = const ProxyNode(
      id: 'direct',
      name: 'Direct',
      type: 'direct',
      metadata: {'source': 'builtin'},
    );
    nextGroups.add(
      ProxyGroup(
        id: 'direct',
        name: 'Direct',
        type: 'select',
        selectedNodeId: 'direct',
        nodes: [directNode],
      ),
    );

    state = ProxyCatalogState(groups: nextGroups);
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

  String _groupId(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'group' : normalized;
  }
}

final proxyCatalogProvider =
    NotifierProvider<ProxyCatalogNotifier, ProxyCatalogState>(
      ProxyCatalogNotifier.new,
    );
