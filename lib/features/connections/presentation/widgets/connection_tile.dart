import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/ui/record.dart';

import '../../../../core/utils/format_bytes.dart';
import '../../../../core/runtime/core_models.dart';
import '../../../../l10n/app_localizations.dart';

class ConnectionTile extends StatelessWidget {
  const ConnectionTile({
    required this.connection,
    this.onClose,
    this.closing = false,
    super.key,
  });

  final CoreConnection connection;
  final VoidCallback? onClose;
  final bool closing;

  @override
  Widget build(BuildContext context) {
    final styles = RecordTextStyles.of(context);
    final l10n = AppLocalizations.of(context);
    final total = connection.uplinkTotal + connection.downlinkTotal;
    final duration = _formatDuration(connection.createdAt, connection.closedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: recordListGap),
      child: RecordListItem(
        header: RecordHeader(
          trailing: onClose == null ? null : IconButton(
            onPressed: closing ? null : onClose,
            tooltip: l10n.closeConnection,
            icon: closing
                ? const ActivityIndicator(size: 18)
                : const GlyphIcon(AppGlyphs.close, size: 18),
          ),
          children: [
            Text(connection.network.toUpperCase()),
            Text(connection.protocol.isEmpty ? '-' : connection.protocol),
            Text(formatBytes(total)),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_displayDestination(connection), style: styles.title),
            const SizedBox(height: 6),
            DefaultTextStyle(
              style: styles.secondary,
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('↑ ${formatBytes(connection.uplinkTotal)}'),
                  Text('↓ ${formatBytes(connection.downlinkTotal)}'),
                  Text(connection.outbound),
                  if (duration.isNotEmpty) Text(duration),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayDestination(CoreConnection c) {
    if (c.domain.isNotEmpty) return c.domain;
    return c.destination;
  }

  String _formatDuration(int createdAt, int closedAt) {
    if (createdAt <= 0) return '';
    final end = closedAt > 0
        ? closedAt
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final seconds = end - createdAt;
    if (seconds < 0) return '';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}
