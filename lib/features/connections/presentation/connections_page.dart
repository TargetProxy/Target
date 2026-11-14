import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import '../../../core/ui/app_glyphs.dart';

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
        prism.IconButton(
          onPressed: state.activeCount == 0 || state.closingAll
              ? null
              : () => closeAllConnectionsWithFeedback(context, ref, notifier),
          icon: state.closingAll
              ? const prism.ActivityIndicator(size: 20)
              : const GlyphIcon(AppGlyphs.close),
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
            child: prism.SearchField(
              hintText: l10n.searchConnections,
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          prism.PopupAnchor(
            targetBuilder: (open) => prism.IconButton(
              onPressed: open,
              tooltip: '${l10n.sortBy} ${sortAsc ? '↑' : '↓'}',
              icon: const GlyphIcon(AppGlyphs.sort),
            ),
            popupBuilder: (_) => prism.PopupMenu(items: [
              for (final (value, label) in [
                (ConnectionSortBy.traffic, l10n.trafficSort),
                (ConnectionSortBy.destination, l10n.destinationSort),
                (ConnectionSortBy.outbound, l10n.outboundSort),
                (ConnectionSortBy.network, l10n.networkSort),
              ])
                prism.PopupMenuItem(
                  label: '$label${sortBy == value ? (sortAsc ? ' ↑' : ' ↓') : ''}',
                  checked: sortBy == value,
                  onPressed: () => onSortChanged(value),
                ),
            ]),
          ),
        ],
      ),
    );
  }

}
