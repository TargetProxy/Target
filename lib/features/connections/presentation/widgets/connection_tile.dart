import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/runtime/core_models.dart';

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
    final theme = Theme.of(context);
    final total = connection.uplinkTotal + connection.downlinkTotal;
    final duration = _formatDuration(connection.createdAt, connection.closedAt);
    final networkLabel = connection.network.toUpperCase();
    final protocolLabel = connection.protocol.isNotEmpty
        ? connection.protocol
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _NetworkChip(network: networkLabel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _displayDestination(connection),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatBytes(total),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: closing ? null : onClose,
                      icon: closing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close, size: 18),
                      tooltip: 'Close connection',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TrafficArrow(
                    icon: Icons.arrow_upward,
                    value: formatBytes(connection.uplinkTotal),
                    color: AppColors.upload,
                  ),
                  const SizedBox(width: 12),
                  _TrafficArrow(
                    icon: Icons.arrow_downward,
                    value: formatBytes(connection.downlinkTotal),
                    color: AppColors.download,
                  ),
                  const Spacer(),
                  _MetaChip(icon: Icons.route, label: connection.outbound),
                  const SizedBox(width: 6),
                  _MetaChip(icon: Icons.policy_outlined, label: protocolLabel),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _MetaChip(icon: Icons.timer_outlined, label: duration),
                  ],
                ],
              ),
            ],
          ),
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

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.network});

  final String network;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (network) {
      'TCP' => theme.colorScheme.primary,
      'UDP' => const Color(0xffd97706),
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        network,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrafficArrow extends StatelessWidget {
  const _TrafficArrow({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
