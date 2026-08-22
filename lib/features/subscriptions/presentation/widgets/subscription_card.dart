import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../data/models/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.onMenuSelected,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = subscription;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sub.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sub.nodeCount} nodes'
                          '${sub.lastUpdatedAt != null ? ' · Updated ${_formatDate(sub.lastUpdatedAt!)}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub.safeUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (sub.enabled) ...[
                    _ActiveChip(theme: theme),
                    const SizedBox(width: 6),
                  ],
                  _StatusChip(subscription: sub),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: onMenuSelected,
                    itemBuilder: (_) => [
                      if (!sub.enabled)
                        const PopupMenuItem(value: 'use', child: Text('Use')),
                      const PopupMenuItem(
                        value: 'update',
                        child: Text('Update'),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              if (sub.totalBytes != null) ...[
                const SizedBox(height: AppSpacing.itemGap),
                _TrafficBar(subscription: sub),
              ],
              if (sub.expiresAt != null) ...[
                const SizedBox(height: AppSpacing.smallGap),
                Text(
                  'Expires: ${_formatDate(sub.expiresAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sub.isExpired
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (sub.lastError != null && sub.lastError!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.smallGap),
                Text(
                  sub.lastError!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Active',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = subscription.updateStatus;
    final (label, color) = switch (status) {
      SubscriptionUpdateStatus.updating => (
        'Updating',
        theme.colorScheme.primary,
      ),
      SubscriptionUpdateStatus.updated => ('Updated', const Color(0xff15803d)),
      SubscriptionUpdateStatus.noChange => (
        'Current',
        theme.colorScheme.primary,
      ),
      SubscriptionUpdateStatus.failed => ('Failed', theme.colorScheme.error),
      SubscriptionUpdateStatus.idle => (
        'Idle',
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    if (status == SubscriptionUpdateStatus.updating) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrafficBar extends StatelessWidget {
  const _TrafficBar({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = subscription.usagePercent ?? 0;
    final used = subscription.uploadBytes + subscription.downloadBytes;
    final total = subscription.totalBytes!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${formatBytes(used)} / ${formatBytes(total)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
