import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import '../../../core/ui/app_glyphs.dart';
import '../../../core/ui/scaffold/scaffold.dart' as ui;

import '../../../core/widgets/empty_state.dart';
import '../../../core/ui/null_status_illustration.dart';
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
      searchState: ui.AppBarSearchState(
        onSearch: notifier.setSearchQuery,
      ),
      actions: [
        prism.PopupAnchor(
          targetBuilder: (open) => prism.IconButton(
            onPressed: open,
            tooltip: '${l10n.sortBy} ${state.sortAsc ? '↑' : '↓'}',
            icon: const GlyphIcon(AppGlyphs.sort),
          ),
          popupBuilder: (_) => prism.PopupMenu(
            items: [
              for (final (value, label) in [
                (ConnectionSortBy.traffic, l10n.trafficSort),
                (ConnectionSortBy.destination, l10n.destinationSort),
                (ConnectionSortBy.outbound, l10n.outboundSort),
                (ConnectionSortBy.network, l10n.networkSort),
              ])
                prism.PopupMenuItem(
                  label:
                      '$label${state.sortBy == value ? (state.sortAsc ? ' ↑' : ' ↓') : ''}',
                  checked: state.sortBy == value,
                  onPressed: () => notifier.setSortBy(value),
                ),
            ],
          ),
        ),
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
          Expanded(
            child: connections.isEmpty
                ? EmptyState(
                    illustration: NullStatusIllustration.connections,
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
