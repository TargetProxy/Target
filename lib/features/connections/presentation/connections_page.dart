import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../application/connections_notifier.dart';
import 'widgets/connection_tile.dart';

class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final notifier = ref.read(connectionsProvider.notifier);
    final connections = state.filteredConnections;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TargetPageLayout.maxWidth,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TargetPageHeader(
                      title: 'Connections',
                      subtitle: 'Inspect active network connections.',
                    ),
                  ),
                  IconButton(
                    onPressed: state.activeCount == 0 || state.closingAll
                        ? null
                        : () => _closeAll(context, ref, notifier),
                    icon: state.closingAll
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_presentation_outlined),
                    tooltip: 'Close all connections',
                  ),
                ],
              ),
            ),
          ),
          _ConnectionsToolbar(
            searchQuery: state.searchQuery,
            sortBy: state.sortBy,
            sortAsc: state.sortAsc,
            onSearchChanged: notifier.setSearchQuery,
            onSortChanged: notifier.setSortBy,
          ),
          Expanded(
            child: connections.isEmpty
                ? const EmptyState(
                    icon: Icons.cable_outlined,
                    title: 'No connections',
                    description:
                        'Active connections will appear here when the proxy is running.',
                  )
                : ListView.builder(
                    itemCount: connections.length,
                    itemBuilder: (context, index) {
                      final connection = connections[index];
                      return ConnectionTile(
                        connection: connection,
                        closing: state.isClosing(connection.id),
                        onClose: () =>
                            _closeOne(context, ref, notifier, connection.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeOne(
    BuildContext context,
    WidgetRef ref,
    ConnectionsNotifier notifier,
    String id,
  ) async {
    final closed = await notifier.close(id);
    if (!context.mounted || closed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(connectionsProvider).lastError ?? 'Unable to close connection.',
        ),
      ),
    );
  }

  Future<void> _closeAll(
    BuildContext context,
    WidgetRef ref,
    ConnectionsNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close all connections?'),
        content: const Text('Active network connections will be interrupted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Close all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final count = await notifier.closeAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == null
              ? ref.read(connectionsProvider).lastError ??
                    'Unable to close connections.'
              : 'Closed $count active connection${count == 1 ? '' : 's'}.',
        ),
      ),
    );
  }
}

class _ConnectionsToolbar extends StatelessWidget {
  const _ConnectionsToolbar({
    required this.searchQuery,
    required this.sortBy,
    required this.sortAsc,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final String searchQuery;
  final ConnectionSortBy sortBy;
  final bool sortAsc;
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
              decoration: const InputDecoration(
                hintText: 'Search connections...',
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<ConnectionSortBy>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 2),
                Icon(
                  sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                ),
              ],
            ),
            tooltip: 'Sort by',
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              _sortItem(ConnectionSortBy.traffic, 'Traffic'),
              _sortItem(ConnectionSortBy.destination, 'Destination'),
              _sortItem(ConnectionSortBy.outbound, 'Outbound'),
              _sortItem(ConnectionSortBy.network, 'Network'),
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
            Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
        ],
      ),
    );
  }
}
