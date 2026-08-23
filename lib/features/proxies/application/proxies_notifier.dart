import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/proxy_group.dart';
import '../../../data/models/proxy_node.dart';
import 'proxy_catalog.dart';

enum ProxyMode { rule, global, direct }

/// Immutable snapshot of the proxies workspace.
@immutable
class ProxiesState {
  const ProxiesState({
    this.mode = ProxyMode.rule,
    this.groups = const [],
    this.selectedGroupIndex = 0,
    this.searchQuery = '',
    this.sortAsc = true,
    this.testing = false,
    this.lastError,
  });

  final ProxyMode mode;
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
    ProxyMode? mode,
    List<ProxyGroup>? groups,
    int? selectedGroupIndex,
    String? searchQuery,
    bool? sortAsc,
    bool? testing,
    String? lastError,
    bool clearError = false,
  }) {
    return ProxiesState(
      mode: mode ?? this.mode,
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
  @override
  ProxiesState build() {
    ref.listen(proxyCatalogProvider, (_, next) {
      state = _syncFromCatalog(state, next);
    });
    ref.listen(coreProvider, (_, next) {
      state = _syncFromCore(state, next);
    });
    var result = _syncFromCatalog(
      const ProxiesState(),
      ref.read(proxyCatalogProvider),
    );
    result = _syncFromCore(result, ref.read(coreProvider));
    return result;
  }

  void setMode(ProxyMode mode) {
    state = state.copyWith(mode: mode);
  }

  void selectGroup(int index) {
    if (index >= 0 && index < state.groups.length) {
      state = state.copyWith(selectedGroupIndex: index);
    }
  }

  Future<void> selectNode(String nodeId) async {
    if (state.groups.isEmpty) return;
    final group = state.groups[state.selectedGroupIndex];
    ref.read(proxyCatalogProvider.notifier).selectNode(group.id, nodeId);
    state = state.copyWith(
      groups: [
        for (var i = 0; i < state.groups.length; i++)
          i == state.selectedGroupIndex
              ? group.copyWith(
                  selectedNodeId: nodeId,
                  nodes: [
                    for (final node in group.nodes)
                      node.copyWith(isSelected: node.id == nodeId),
                  ],
                )
              : state.groups[i],
      ],
    );
    await ref.read(coreProvider.notifier).selectOutbound(group.id, nodeId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSortOrder() {
    state = state.copyWith(sortAsc: !state.sortAsc);
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

  Future<void> testSingleLatency(String nodeId) async {
    state = state.copyWith(clearError: true);
    final coreGroups = ref.read(coreProvider).proxyGroups;
    final candidateGroups = coreGroups.any(_isUrlTestGroup)
        ? coreGroups
        : state.groups;
    final testable = candidateGroups.any(
      (group) =>
          _isUrlTestGroup(group) &&
          group.nodes.any(
            (node) => node.id == nodeId && node.type.toLowerCase() != 'direct',
          ),
    );
    if (!testable) {
      state = state.copyWith(
        lastError: 'This node is not part of a TargetLib URLTest group.',
      );
      return;
    }
    for (var gi = 0; gi < state.groups.length; gi++) {
      final group = state.groups[gi];
      final idx = group.nodes.indexWhere((n) => n.id == nodeId);
      if (idx < 0) continue;

      final node = group.nodes[idx];
      final latency = await ref
          .read(coreProvider.notifier)
          .testLatency(node.id);
      if (latency == null) {
        state = state.copyWith(lastError: ref.read(coreProvider).message);
      }
      final updated = List<ProxyNode>.from(group.nodes);
      updated[idx] = node.copyWith(latencyMs: latency);
      state = state.copyWith(
        groups: [
          for (var i = 0; i < state.groups.length; i++)
            i == gi ? group.copyWith(nodes: updated) : state.groups[i],
        ],
      );
      return;
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
