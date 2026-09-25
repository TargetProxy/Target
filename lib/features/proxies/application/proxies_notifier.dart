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

/// Presents the catalog's pool and applies selections to the running core. The
/// catalog owns node data, so this notifier never merges pool snapshots itself.
class ProxiesNotifier extends Notifier<ProxiesState> {
  final Map<String, String> _runtimeSelections = {};

  @override
  ProxiesState build() {
    ref.listen(proxyCatalogProvider, (_, next) {
      state = _fromCatalog(state, next);
    });
    ref.listen(coreProvider, (previous, next) {
      if (!next.running) {
        _runtimeSelections.clear();
      } else if (previous?.running != true) {
        unawaited(_syncAllSelectionsToRuntime());
      }
    });
    return _fromCatalog(const ProxiesState(), ref.read(proxyCatalogProvider));
  }

  ProxiesState _fromCatalog(ProxiesState current, ProxyCatalogState next) {
    final selectedGroupId = current.selectedGroup?.id;
    final index = next.groups.indexWhere((group) => group.id == selectedGroupId);
    return current.copyWith(
      groups: next.groups,
      selectedGroupIndex: index >= 0 ? index : 0,
    );
  }

  void selectGroup(int index) {
    if (index >= 0 && index < state.groups.length) {
      state = state.copyWith(selectedGroupIndex: index);
    }
  }

  Future<void> selectNode(String nodeId) async {
    final group = state.selectedGroup;
    if (group == null || !group.nodes.any((node) => node.id == nodeId)) return;
    if (group.selectedNodeId != nodeId) {
      if (ref.read(coreProvider).running &&
          !await _selectRuntime(group.id, nodeId)) {
        return;
      }
      ref.read(proxyCatalogProvider.notifier).selectNode(group.id, nodeId);
      state = state.copyWith(clearError: true);
      return;
    }
    await _selectRuntime(group.id, nodeId);
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
      // TargetLib maps these node tags back to its internal URLTest group, so
      // every node in the pool is testable regardless of client-side grouping.
      final nodeIds = {
        for (final group in state.groups)
          for (final node in group.nodes)
            if (_isTestableNode(node)) node.id,
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
              ? 'TargetLib has no testable nodes. Add a subscription first.'
              : 'TargetLib has no testable nodes. Supported nodes found: $protocols.',
        );
        return;
      }
      final catalog = ref.read(proxyCatalogProvider.notifier);
      var successCount = 0;
      final errors = <String>[];
      await for (final result
          in ref.read(coreProvider.notifier).testLatencies(nodeIds)) {
        final latency = result.delayMilliseconds;
        if (result.succeeded && latency != null) {
          successCount++;
          catalog.applyLatency(result.outboundId, latencyMs: latency);
        } else {
          catalog.applyLatency(result.outboundId, timedOut: true);
          if (result.errorMessage.isNotEmpty) {
            errors.add('${result.outboundId}: ${result.errorMessage}');
          }
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

  bool _isTestableNode(ProxyNode node) {
    final type = node.type.toLowerCase();
    return node.id.isNotEmpty &&
        node.isAvailable &&
        type != 'direct' &&
        type != 'block' &&
        type != 'dns';
  }
}

final proxiesProvider = NotifierProvider<ProxiesNotifier, ProxiesState>(
  ProxiesNotifier.new,
);
