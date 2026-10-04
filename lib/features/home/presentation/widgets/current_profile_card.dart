import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
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
