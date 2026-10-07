import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../application/connections_notifier.dart';
import 'connection_actions.dart';
import 'widgets/connection_tile.dart';

class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);
    final connections = state.filteredConnections;
    final l10n = AppLocalizations.of(context);

    return TargetPageScaffold(
      title: l10n.connections,
      scrollableBody: false,
      actions: [
        IconButton(
          onPressed: state.activeCount == 0 || state.closingAll
              ? null
              : () => closeAllConnectionsWithFeedback(context, ref, notifier),
          icon: state.closingAll
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.clear_all_rounded),
          tooltip: l10n.closeAllConnections,
        ),
      ],
      body: Column(
        children: [
          _ConnectionsToolbar(
            l10n: l10n,
            searchQuery: state.searchQuery,
            sortBy: state.sortBy,
            sortAsc: state.sortAsc,
            onSearchChanged: notifier.setSearchQuery,
            onSortChanged: notifier.setSortBy,
          ),
          Expanded(
            child: connections.isEmpty
                ? EmptyState(
                    icon: Icons.cable_rounded,
                    title: l10n.noConnections,
                  )
                : ListView.builder(
                    itemCount: connections.length,
                    itemBuilder: (context, index) {
                      final connection = connections[index];
                      return ConnectionTile(
                        key: ValueKey(connection.id),
                        connection: connection,
                        closing: state.isClosing(connection.id),
                        onClose: () => closeConnectionWithFeedback(
                          context,
                          ref,
                          notifier,
                          connection.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionsToolbar extends StatelessWidget {
  const _ConnectionsToolbar({
    required this.searchQuery,
    required this.sortBy,
    required this.sortAsc,
    required this.l10n,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final String searchQuery;
  final ConnectionSortBy sortBy;
  final bool sortAsc;
  final AppLocalizations l10n;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ConnectionSortBy> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchConnections,
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<ConnectionSortBy>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort_rounded, size: 20),
                const SizedBox(width: 2),
                Icon(
                  sortAsc
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                ),
              ],
            ),
            tooltip: l10n.sortBy,
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              _sortItem(ConnectionSortBy.traffic, l10n.trafficSort),
              _sortItem(ConnectionSortBy.destination, l10n.destinationSort),
              _sortItem(ConnectionSortBy.outbound, l10n.outboundSort),
              _sortItem(ConnectionSortBy.network, l10n.networkSort),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ConnectionSortBy> _sortItem(
    ConnectionSortBy value,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          if (sortBy == value)
            Icon(
              sortAsc
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
            ),
        ],
      ),
    );
  }
}
