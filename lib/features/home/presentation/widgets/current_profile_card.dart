import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/runtime/core_notifier.dart';
import 'home_info_row.dart';

class CurrentProfileCard extends StatelessWidget {
  const CurrentProfileCard({required this.core, super.key});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTun = core.settings.proxyMode.name == 'tun';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rss_feed,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    core.running ? 'Connected' : 'No active profile',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(core: core),
              ],
            ),
            const SizedBox(height: AppSpacing.itemGap),
            HomeInfoRow(
              icon: isTun ? Icons.alt_route : Icons.speed,
              label: 'Mode',
              value: core.settings.proxyMode.label,
            ),
            const SizedBox(height: AppSpacing.smallGap),
            HomeInfoRow(
              icon: isTun
                  ? Icons.admin_panel_settings_outlined
                  : Icons.place_outlined,
              label: isTun ? 'Privilege' : 'Listen',
              value: isTun
                  ? 'Elevate on demand'
                  : '${core.settings.listenAddress}:${core.settings.mixedPort}',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.core});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = core.running;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: running
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        core.status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: running ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
