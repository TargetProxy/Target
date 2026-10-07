import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../application/connections_notifier.dart';

Future<void> closeConnectionWithFeedback(
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

Future<void> closeAllConnectionsWithFeedback(
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
