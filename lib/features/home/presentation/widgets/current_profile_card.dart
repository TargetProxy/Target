import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/app_animate.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../maps/application/proxy_country_map.dart';
import '../../../proxies/application/proxies_notifier.dart';
import 'home_info_row.dart';
import '../../../../l10n/app_localizations.dart';

class CurrentProfileCard extends ConsumerWidget {
  const CurrentProfileCard({required this.core, super.key});

  final CoreState core;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final proxies = ref.watch(proxiesProvider);
    final isTun = core.settings.proxyMode.name == 'tun';
    final selectedNode = proxies.selectedGroup?.selectedNode;
    final selectedCountry = selectedNode == null
        ? null
        : proxyNodeCountryCode(selectedNode);
    final selectedNodeMeta = selectedNode == null
        ? l10n.nodeNotSelected
        : [?selectedCountry, selectedNode.typeLabel].join(' / ');

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
                    core.running ? l10n.connected : l10n.noActiveProfile,
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
              label: l10n.mode,
              value: core.settings.proxyMode.label,
            ),
            const SizedBox(height: AppSpacing.smallGap),
            HomeInfoRow(
              icon: Icons.route_outlined,
              label: l10n.node,
              value: selectedNode?.displayName ?? l10n.nodeNotSelected,
            ),
            if (selectedNode != null) ...[
              const SizedBox(height: AppSpacing.smallGap),
              HomeInfoRow(
                icon: Icons.flag_outlined,
                label: l10n.region,
                value: selectedNodeMeta,
              ),
              const SizedBox(height: AppSpacing.smallGap),
              HomeInfoRow(
                icon: Icons.tag_outlined,
                label: l10n.nodeId,
                value: selectedNode.id,
              ),
            ],
            if (proxies.lastError != null) ...[
              const SizedBox(height: AppSpacing.smallGap),
              HomeInfoRow(
                icon: Icons.error_outline,
                label: l10n.proxyError,
                value: proxies.lastError!,
              ),
            ],
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
      child: AppAnimate(
        key: ValueKey(core.status),
        effects: [
          FadeEffect(duration: AppMotion.fast, curve: AppMotion.easeOut),
          ScaleEffect(
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            begin: const Offset(0.92, 0.92),
          ),
        ],
        child: Text(
          core.status,
          style: theme.textTheme.labelSmall?.copyWith(
            color: running ? Colors.green.shade700 : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
