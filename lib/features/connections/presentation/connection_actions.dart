import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

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
  BannerHost.maybeOf(context)?.show(
    ref.read(connectionsProvider).lastError ??
        AppLocalizations.of(context).unableToCloseConnection,
    level: BannerLevel.error,
  );
}

Future<void> closeAllConnectionsWithFeedback(
  BuildContext context,
  WidgetRef ref,
  ConnectionsNotifier notifier,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showFloatingDialog<bool>(
    context: context,
    child: AlertDialog(
      title: l10n.closeAllConnections,
      child: Text(l10n.activeConnectionsWillInterrupt),
      destructive: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.closeAll),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final count = await notifier.closeAll();
  if (!context.mounted) return;
  BannerHost.maybeOf(context)?.show(
    count == null
        ? ref.read(connectionsProvider).lastError ?? l10n.unableToCloseConnections
        : l10n.closedConnections(count),
    level: count == null ? BannerLevel.error : BannerLevel.success,
  );
}
