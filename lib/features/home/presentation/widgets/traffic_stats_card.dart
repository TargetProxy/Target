import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/runtime/core_models.dart';

class TrafficStatsCard extends StatelessWidget {
  const TrafficStatsCard({required this.snapshot, super.key});

  final TrafficSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.arrow_upward,
                label: 'Upload',
                value: formatSpeed(snapshot.uploadBytes),
                color: const Color(0xff7c3aed),
              ),
            ),
            const SizedBox(width: AppSpacing.itemGap),
            Expanded(
              child: _StatItem(
                icon: Icons.arrow_downward,
                label: 'Download',
                value: formatSpeed(snapshot.downloadBytes),
                color: const Color(0xff2563eb),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
