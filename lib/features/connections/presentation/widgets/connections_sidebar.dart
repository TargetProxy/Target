import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/runtime/core_models.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/connections_notifier.dart';

class ConnectionsSidebar extends ConsumerWidget {
  const ConnectionsSidebar({required this.onOpenConnections, super.key});

  final VoidCallback onOpenConnections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider);
    final connectionsState = ref.watch(connectionsProvider);
    final connectionsNotifier = ref.read(connectionsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final connections = connectionsState.filteredConnections.take(8).toList();
    final target = core.settings.listenAddress;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      child: SizedBox(
        width: 276,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.ssid_chart,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.activeConnections,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CountBadge(value: connectionsState.activeCount),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed:
                        connectionsState.activeCount == 0 ||
                            connectionsState.closingAll
                        ? null
                        : () => _closeAll(context, ref, connectionsNotifier),
                    icon: connectionsState.closingAll
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_presentation_outlined),
                    tooltip: l10n.closeAllConnections,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: core.running
                            ? Colors.green
                            : theme.colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: connections.isEmpty
                    ? Center(
                        child: Text(
                          connectionsState.activeCount == 0
                              ? l10n.noConnections
                              : l10n.connectionDetailsUnavailable,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: connections.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final connection = connections[index];
                          return _ConnectionSummary(
                            connection: connection,
                            closing: connectionsState.isClosing(connection.id),
                            onClose: () => _closeOne(
                              context,
                              ref,
                              connectionsNotifier,
                              connection.id,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onOpenConnections,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.connections),
              ),
            ],
          ),
        ),
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
          ref.read(connectionsProvider).lastError ??
              AppLocalizations.of(context).unableToCloseConnection,
        ),
      ),
    );
  }

  Future<void> _closeAll(
    BuildContext context,
    WidgetRef ref,
    ConnectionsNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.closeAllConnections),
        content: Text(l10n.activeConnectionsWillInterrupt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.closeAll),
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
                    l10n.unableToCloseConnections
              : l10n.closedConnections(count),
        ),
      ),
    );
  }
}

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({
    required this.connection,
    required this.onClose,
    required this.closing,
  });

  final CoreConnection connection;
  final VoidCallback onClose;
  final bool closing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destination = connection.domain.isEmpty
        ? connection.destination
        : connection.domain;
    final total = connection.uplinkTotal + connection.downlinkTotal;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            connection.network.toUpperCase() == 'UDP'
                ? Icons.bolt_outlined
                : Icons.public,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${connection.outbound} · ${formatBytes(total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: closing ? null : onClose,
            icon: closing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.close, size: 16),
            tooltip: AppLocalizations.of(context).closeConnection,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
