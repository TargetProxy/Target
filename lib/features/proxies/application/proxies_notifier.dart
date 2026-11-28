import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_models.dart';
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
    this.testingNodeIds = const {},
    this.lastError,
  });

  final List<ProxyGroup> groups;
  final int selectedGroupIndex;
  final String searchQuery;
  final bool sortAsc;
  final bool testing;
  final Set<String> testingNodeIds;
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
    Set<String>? testingNodeIds,
    String? lastError,
    bool clearError = false,
  }) {
    return ProxiesState(
      groups: groups ?? this.groups,
      selectedGroupIndex: selectedGroupIndex ?? this.selectedGroupIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      sortAsc: sortAsc ?? this.sortAsc,
      testing: testing ?? this.testing,
      testingNodeIds: testingNodeIds ?? this.testingNodeIds,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

/// Presents the catalog's pool and applies selections to the running core. The
/// catalog owns node data, so this notifier never merges pool snapshots itself.
class ProxiesNotifier extends Notifier<ProxiesState> {
  final Map<String, String> _runtimeSelections = {};
  StreamIterator<CoreLatencyResult>? _latencyRun;

  @override
  ProxiesState build() {
    ref.onDispose(() => unawaited(_latencyRun?.cancel()));
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
    final index = next.groups.indexWhere(
      (group) => group.id == selectedGroupId,
    );
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
    if (ref.read(coreProvider).running) {
      await _selectRuntime(group.id, nodeId);
    }
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
    if (_runtimeSelections[groupId] == nodeId) {
      return true;
    }
    try {
      await ref.read(coreProvider.notifier).selectNode(nodeId);
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

  Future<void> testAllLatency() =>
      _testLatency(state.groups.expand((group) => group.nodes));

  Future<void> testNodeLatency(ProxyNode node) => _testLatency([node]);

  Future<void> cancelLatencyTest() async {
    await _latencyRun?.cancel();
  }

  Future<void> _testLatency(Iterable<ProxyNode> nodes) async {
    if (_latencyRun != null) return;
    final pending = {
      for (final node in nodes)
        if (node.isAvailable) node.id,
    };
    if (pending.isEmpty) return;
    final catalog = ref.read(proxyCatalogProvider.notifier);
    final run = StreamIterator(
      ref.read(coreProvider.notifier).testLatencies(pending.toList()),
    );
    _latencyRun = run;
    state = state.copyWith(
      testing: true,
      testingNodeIds: Set.unmodifiable(pending),
      clearError: true,
    );

    try {
      while (await run.moveNext() && ref.mounted) {
        final result = run.current;
        if (!pending.remove(result.outboundId)) continue;
        final delay = result.succeeded ? result.delayMilliseconds : null;
        final timedOut = result.status == CoreLatencyStatus.timeout;
        catalog.applyLatency(
          result.outboundId,
          latencyMs: delay,
          timedOut: timedOut,
          failed: delay == null && !timedOut,
        );
        state = state.copyWith(testingNodeIds: Set.unmodifiable(pending));
      }
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(lastError: 'Latency test failed: $error');
      }
    } finally {
      unawaited(run.cancel());
      _latencyRun = null;
      if (ref.mounted) {
        state = state.copyWith(testing: false, testingNodeIds: const {});
      }
    }
  }
}

final proxiesProvider = NotifierProvider<ProxiesNotifier, ProxiesState>(
  ProxiesNotifier.new,
);
