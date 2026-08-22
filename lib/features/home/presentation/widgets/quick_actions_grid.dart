import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    required this.onTestLatency,
    required this.onRefreshRuleSets,
    required this.onCloseConnections,
    required this.enabled,
    super.key,
  });

  final VoidCallback onTestLatency;
  final VoidCallback onRefreshRuleSets;
  final VoidCallback onCloseConnections;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.itemGap),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.speed,
                    label: 'Test Proxies',
                    onTap: enabled ? onTestLatency : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.smallGap),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.hub,
                    label: 'Change Node',
                    onTap: () => context.go(AppRoute.proxies.path),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smallGap),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.rule_folder_outlined,
                    label: 'Refresh Rules',
                    onTap: enabled ? onRefreshRuleSets : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.smallGap),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.cancel_presentation_outlined,
                    label: 'Close Connections',
                    onTap: enabled ? onCloseConnections : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smallGap),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.sync,
                    label: 'Update Sub',
                    onTap: () => context.go(AppRoute.subscriptions.path),
                  ),
                ),
                const SizedBox(width: AppSpacing.smallGap),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'View Logs',
                    onTap: () => context.go(AppRoute.logs.path),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
