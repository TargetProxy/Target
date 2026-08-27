import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/proxy_group.dart';
import '../../../data/models/proxy_node.dart';
import 'proxy_catalog.dart';

/// Immutable snapshot of the proxies workspace.
@immutable
class ProxiesState {
  const ProxiesState({
    this.groups = const [],
    this.selectedGroupIndex = 0,
    this.searchQuery = '',
    this.sortAsc = true,
    this.testing = false,
    this.lastError,
  });

  final List<ProxyGroup> groups;
  final int selectedGroupIndex;
  final String searchQuery;
  final bool sortAsc;
  final bool testing;
  final String? lastError;

  ProxyGroup? get selectedGroup {
    if (groups.isEmpty) return null;
    final index = selectedGroupIndex.clamp(0, groups.length - 1);
    return groups[index];
  }

  List<ProxyNode> get filteredNodes {
    final group = selectedGroup;
    if (group == null) return const [];

    var nodes = group.nodes.where((n) => n.isAvailable).toList();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      nodes = nodes
          .where(
            (n) =>
                n.name.toLowerCase().contains(q) ||
                n.type.toLowerCase().contains(q) ||
                (n.countryCode?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    nodes.sort((a, b) {
      final la = a.latencyMs ?? 99999;
      final lb = b.latencyMs ?? 99999;
      return sortAsc ? la.compareTo(lb) : lb.compareTo(la);
    });

    return nodes;
  }

  ProxiesState copyWith({
    List<ProxyGroup>? groups,
    int? selectedGroupIndex,
    String? searchQuery,
    bool? sortAsc,
    bool? testing,
    String? lastError,
    bool clearError = false,
  }) {
    return ProxiesState(
      groups: groups ?? this.groups,
      selectedGroupIndex: selectedGroupIndex ?? this.selectedGroupIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      sortAsc: sortAsc ?? this.sortAsc,
      testing: testing ?? this.testing,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class ProxiesNotifier extends Notifier<ProxiesState> {
  final Map<String, String> _runtimeSelections = {};

  @override
  ProxiesState build() {
    ref.listen(proxyCatalogProvider, (_, next) {
      state = _syncFromCatalog(state, next);
    });
    ref.listen(coreProvider, (previous, next) {
      state = _syncFromCore(state, next);
      if (!next.running) {
        _runtimeSelections.clear();
      } else if (previous?.running != true) {
        unawaited(_syncAllSelectionsToRuntime());
      }
    });
    var result = _syncFromCatalog(
      const ProxiesState(),
      ref.read(proxyCatalogProvider),
    );
    result = _syncFromCore(result, ref.read(coreProvider));
    return result;
  }

  void selectGroup(int index) {
    if (index >= 0 && index < state.groups.length) {
      state = state.copyWith(selectedGroupIndex: index);
    }
  }

  Future<void> selectNode(String nodeId) async {
    if (state.groups.isEmpty) return;
    final group = state.groups[state.selectedGroupIndex];
    if (!group.nodes.any((node) => node.id == nodeId)) return;
    if (group.selectedNodeId != nodeId) {
      if (ref.read(coreProvider).running &&
          !await _selectRuntime(group.id, nodeId)) {
        return;
      }
      _applyLocalSelection(group.id, state.selectedGroupIndex, nodeId);
      return;
    }
    await _selectRuntime(group.id, nodeId);
  }

  void _applyLocalSelection(String groupId, int groupIndex, String nodeId) {
    ref.read(proxyCatalogProvider.notifier).selectNode(groupId, nodeId);
    state = state.copyWith(
      groups: [
        for (var i = 0; i < state.groups.length; i++)
          i == groupIndex
              ? state.groups[i].copyWith(
                  selectedNodeId: nodeId,
                  nodes: [
                    for (final node in state.groups[i].nodes)
                      node.copyWith(isSelected: node.id == nodeId),
                  ],
                )
              : state.groups[i],
      ],
      clearError: true,
    );
  }

  Future<void> _syncAllSelectionsToRuntime() async {
    for (final group in state.groups) {
      final nodeId = group.selectedNodeId;
      if (nodeId != null) {
        await _selectRuntime(group.id, nodeId);
      }
    }
  }

  Future<bool> _selectRuntime(String groupId, String nodeId) async {
    if (!ref.read(coreProvider).running ||
        _runtimeSelections[groupId] == nodeId) {
      return true;
    }
    try {
      await ref.read(coreProvider.notifier).selectOutbound(groupId, nodeId);
      _runtimeSelections[groupId] = nodeId;
      state = state.copyWith(clearError: true);
      return true;
    } on Object {
      // Allow a later retry instead of memoizing the failed selection.
      _runtimeSelections.remove(groupId);
      state = state.copyWith(
        lastError: 'Failed to switch outbound to $nodeId.',
      );
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> testAllLatency() async {
    if (state.testing) return;
    state = state.copyWith(testing: true, clearError: true);

    try {
      final coreGroups = ref.read(coreProvider).proxyGroups;
      final candidateGroups = coreGroups.any((group) => _isUrlTest(group.type))
          ? coreGroups
          : state.groups;
      final nodeIds = {
        for (final group in candidateGroups.where(_isUrlTestGroup))
          for (final node in group.nodes)
            if (node.type.toLowerCase() != 'direct') node.id,
      };
      if (nodeIds.isEmpty) {
        final protocols = state.groups
            .expand((group) => group.nodes)
            .map((node) => node.type)
            .where((type) => type.isNotEmpty)
            .toSet()
            .join(', ');
        state = state.copyWith(
          lastError: protocols.isEmpty
              ? 'TargetLib has no testable URLTest nodes. Add a subscription first.'
              : 'TargetLib has no testable URLTest nodes. '
                    'Supported nodes found: $protocols.',
        );
        return;
      }
      var successCount = 0;
      final errors = <String>[];
      await for (final result
          in ref.read(coreProvider.notifier).testLatencies(nodeIds)) {
        final latency = result.delayMilliseconds;
        if (result.succeeded && latency != null) {
          successCount++;
          _mergeLatency(result.outboundId, latency);
        } else if (result.errorMessage.isNotEmpty) {
          errors.add('${result.outboundId}: ${result.errorMessage}');
        }
      }
      if (successCount == 0) {
        state = state.copyWith(
          lastError: errors.isEmpty
              ? ref.read(coreProvider).message
              : errors.first,
        );
      }
    } on Object catch (error) {
      state = state.copyWith(lastError: 'Latency test failed: $error');
    } finally {
      state = state.copyWith(testing: false);
    }
  }

  bool _isUrlTest(String type) =>
      type.toLowerCase().replaceAll(RegExp(r'[-_]'), '') == 'urltest';

  bool _isUrlTestGroup(ProxyGroup group) => _isUrlTest(group.type);

  void _mergeLatency(String nodeId, int latency) {
    // Merge into the latest snapshot because group updates can arrive while
    // the server-side test stream is still producing results.
    state = state.copyWith(
      groups: [
        for (final group in state.groups)
          group.copyWith(
            nodes: [
              for (final node in group.nodes)
                node.id == nodeId ? node.copyWith(latencyMs: latency) : node,
            ],
          ),
      ],
    );
  }

  ProxiesState _syncFromCatalog(ProxiesState current, ProxyCatalogState next) {
    final selectedGroupId = current.selectedGroup?.id;
    final groups = List<ProxyGroup>.of(next.groups);
    final index = groups.indexWhere((group) => group.id == selectedGroupId);
    final selectedGroupIndex = index >= 0 ? index : 0;
    return current.copyWith(
      groups: groups,
      selectedGroupIndex: selectedGroupIndex >= groups.length
          ? 0
          : selectedGroupIndex,
    );
  }

  ProxiesState _syncFromCore(ProxiesState current, CoreState core) {
    if (core.proxyGroups.isEmpty) {
      return current;
    }
    final catalogGroups = ref.read(proxyCatalogProvider).groups;
    if (catalogGroups.isNotEmpty) {
      final runtimeNodes = <String, ProxyNode>{
        for (final group in core.proxyGroups)
          for (final node in group.nodes) node.id: node,
      };
      final groups = [
        for (final group in catalogGroups)
          group.copyWith(
            nodes: [
              for (final node in group.nodes)
                node.copyWith(latencyMs: runtimeNodes[node.id]?.latencyMs),
            ],
          ),
      ];
      final selectedGroupId = current.selectedGroup?.id;
      final index = groups.indexWhere((group) => group.id == selectedGroupId);
      return current.copyWith(
        groups: groups,
        selectedGroupIndex: index >= 0 ? index : 0,
      );
    }
    final selectedGroupId = current.selectedGroup?.id;
    final groups = List<ProxyGroup>.of(core.proxyGroups);
    final index = groups.indexWhere((group) => group.id == selectedGroupId);
    final selectedGroupIndex = index >= 0 ? index : 0;
    return current.copyWith(
      groups: groups,
      selectedGroupIndex: selectedGroupIndex >= groups.length
          ? 0
          : selectedGroupIndex,
    );
  }
}

final proxiesProvider = NotifierProvider<ProxiesNotifier, ProxiesState>(
  ProxiesNotifier.new,
);
