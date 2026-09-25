import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/proxy_group.dart';
import '../../../data/models/proxy_node.dart';

/// Immutable snapshot of the shared node pool.
@immutable
class ProxyCatalogState {
  const ProxyCatalogState({this.groups = const [], this.initialized = false});

  final List<ProxyGroup> groups;
  final bool initialized;
}

/// Owns the node pool and the latency results measured against it. Latency
/// merging lives here only, so a pool refresh cannot drop measurements.
class ProxyCatalogNotifier extends Notifier<ProxyCatalogState> {
  @override
  ProxyCatalogState build() => const ProxyCatalogState();

  void clear() {
    if (state.initialized && state.groups.isEmpty) return;
    state = const ProxyCatalogState(initialized: true);
  }

  void replaceGroups(List<ProxyGroup> sourceGroups) {
    final previous = <String, ProxyNode>{};
    for (final group in state.groups) {
      for (final node in group.nodes) {
        previous[node.id] = node;
      }
    }
    final selections = {
      for (final group in state.groups) group.id: group.selectedNodeId,
    };
    state = ProxyCatalogState(
      initialized: true,
      groups: [
        for (final group in sourceGroups)
          _rebuild(group, selections[group.id] ?? group.selectedNodeId, previous),
      ],
    );
  }

  void selectNode(String groupId, String nodeId) {
    state = ProxyCatalogState(
      initialized: state.initialized,
      groups: [
        for (final group in state.groups)
          if (group.id == groupId) _select(group, nodeId) else group,
      ],
    );
  }

  void applyLatency(String nodeId, {int? latencyMs, bool timedOut = false}) {
    state = ProxyCatalogState(
      initialized: state.initialized,
      groups: [
        for (final group in state.groups)
          group.copyWith(
            nodes: [
              for (final node in group.nodes)
                if (node.id == nodeId)
                  node.copyWith(latencyMs: latencyMs, latencyTimedOut: timedOut)
                else
                  node,
            ],
          ),
      ],
    );
  }

  ProxyGroup _rebuild(
    ProxyGroup source,
    String? previousSelection,
    Map<String, ProxyNode> previous,
  ) {
    final nodes = [
      for (final node in source.nodes) _withPreviousLatency(node, previous[node.id]),
    ];
    return _select(source.copyWith(nodes: nodes), previousSelection);
  }

  /// Removing a source must not silently choose a different connection, so an
  /// absent selection clears rather than falling back to another node.
  ProxyGroup _select(ProxyGroup group, String? nodeId) {
    final selected = nodeId != null && group.nodes.any((n) => n.id == nodeId)
        ? nodeId
        : null;
    return group.copyWith(
      selectedNodeId: selected,
      clearSelection: selected == null,
      nodes: [
        for (final node in group.nodes)
          node.copyWith(isSelected: node.id == selected),
      ],
    );
  }

  ProxyNode _withPreviousLatency(ProxyNode node, ProxyNode? previous) {
    if (previous == null || node.hasLatencyResult || !previous.hasLatencyResult) {
      return node;
    }
    return node.copyWith(
      latencyMs: previous.latencyMs,
      latencyTimedOut: previous.latencyTimedOut,
    );
  }
}

final proxyCatalogProvider =
    NotifierProvider<ProxyCatalogNotifier, ProxyCatalogState>(
      ProxyCatalogNotifier.new,
    );
