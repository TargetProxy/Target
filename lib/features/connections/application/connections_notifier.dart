import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/runtime/core_models.dart';

enum ConnectionSortBy { destination, outbound, network, traffic }

/// Immutable snapshot of the connections workspace.
@immutable
class ConnectionsState {
  const ConnectionsState({
    this.connections = const [],
    this.searchQuery = '',
    this.sortBy = ConnectionSortBy.traffic,
    this.sortAsc = false,
    this.closing = const {},
    this.closingAll = false,
    this.lastError,
  });

  final List<CoreConnection> connections;
  final String searchQuery;
  final ConnectionSortBy sortBy;
  final bool sortAsc;
  final Set<String> closing;
  final bool closingAll;
  final String? lastError;

  bool isClosing(String id) => closing.contains(id);

  int get activeCount => connections.length;

  List<CoreConnection> get filteredConnections {
    var list = connections;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (c) =>
                c.destination.toLowerCase().contains(q) ||
                c.outbound.toLowerCase().contains(q) ||
                c.network.toLowerCase().contains(q) ||
                c.protocol.toLowerCase().contains(q) ||
                c.domain.toLowerCase().contains(q),
          )
          .toList();
    }

    list = List.of(list)..sort(_compare);

    return list;
  }

  ConnectionsState copyWith({
    List<CoreConnection>? connections,
    String? searchQuery,
    ConnectionSortBy? sortBy,
    bool? sortAsc,
    Set<String>? closing,
    bool? closingAll,
    String? lastError,
    bool clearError = false,
  }) {
    return ConnectionsState(
      connections: connections ?? this.connections,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAsc: sortAsc ?? this.sortAsc,
      closing: closing ?? this.closing,
      closingAll: closingAll ?? this.closingAll,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }

  int _compare(CoreConnection a, CoreConnection b) {
    final result = switch (sortBy) {
      ConnectionSortBy.destination => a.destination.compareTo(b.destination),
      ConnectionSortBy.outbound => a.outbound.compareTo(b.outbound),
      ConnectionSortBy.network => a.network.compareTo(b.network),
      ConnectionSortBy.traffic => (a.uplinkTotal + a.downlinkTotal).compareTo(
        b.uplinkTotal + b.downlinkTotal,
      ),
    };
    return sortAsc ? result : -result;
  }
}

class ConnectionsNotifier extends Notifier<ConnectionsState> {
  @override
  ConnectionsState build() {
    ref.listen(coreProvider, (_, next) {
      state = state.copyWith(connections: next.connections);
    });
    return ConnectionsState(connections: ref.read(coreProvider).connections);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(ConnectionSortBy sortBy) {
    if (state.sortBy == sortBy) {
      state = state.copyWith(sortAsc: !state.sortAsc);
    } else {
      state = state.copyWith(sortBy: sortBy, sortAsc: false);
    }
  }

  Future<bool> close(String connectionId) async {
    final core = ref.read(coreProvider.notifier);
    if (state.closing.contains(connectionId)) return false;
    state = state.copyWith(
      clearError: true,
      closing: {...state.closing, connectionId},
    );
    try {
      final closed = await core.closeConnection(connectionId);
      if (!closed) {
        state = state.copyWith(lastError: ref.read(coreProvider).message);
      }
      return closed;
    } finally {
      state = state.copyWith(
        closing: {...state.closing}..remove(connectionId),
      );
    }
  }

  Future<int?> closeAll() async {
    final core = ref.read(coreProvider.notifier);
    if (state.closingAll) return null;
    state = state.copyWith(clearError: true, closingAll: true);
    try {
      final count = await core.closeAllConnections();
      if (count == null) {
        state = state.copyWith(lastError: ref.read(coreProvider).message);
      }
      return count;
    } finally {
      state = state.copyWith(closingAll: false);
    }
  }
}

final connectionsProvider =
    NotifierProvider<ConnectionsNotifier, ConnectionsState>(
      ConnectionsNotifier.new,
    );
