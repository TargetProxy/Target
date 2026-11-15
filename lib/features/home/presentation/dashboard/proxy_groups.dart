import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart';
import 'package:prism_ui/shapes/shapes.dart';

import '../../../../app/router.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/proxy_group.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../proxies/application/proxies_notifier.dart';
import 'card.dart';
import 'layout.dart';
import 'style.dart';

// Adapted from FlClash's dashboard/widgets/proxy_groups.dart.
class ProxyGroupsCard extends ConsumerWidget {
  const ProxyGroupsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final scale = DashboardDensityScope.scaleOf(context);
    final groups = ref.watch(proxiesProvider).groups;
    final l10n = AppLocalizations.of(context);
    final height = (density.isCompact ? 52 : 60) * scale;
    final gap = density.isCompact ? 6.0 : 8.0;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.layers,
            title: l10n.nodeSelection,
            leading: [DashboardChip(label: '${groups.length}')],
            trailing: [
              DashboardIconButton(
                tooltip: l10n.nodeSelection,
                onPressed: () => context.go(AppRoute.nodes.path),
                glyph: AppGlyphs.chevronForward,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Text(
                      l10n.emptyPool,
                      style: DashboardText.label(context),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) => DashboardFadeOut(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              constraints.maxWidth >= 172 * scale * 2 + gap
                              ? 2
                              : 1,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          mainAxisExtent: height,
                        ),
                        itemCount: groups.length,
                        itemBuilder: (context, index) => _GroupTile(
                          group: groups[index],
                          onTap: () {
                            ref
                                .read(proxiesProvider.notifier)
                                .selectGroup(index);
                            context.go(AppRoute.nodes.path);
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final ProxyGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DashboardBlock(
    radius: DashboardCorner.block,
    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 14, 0),
    onTap: onTap,
    semanticLabel: group.name,
    child: Row(
      spacing: 12,
      children: [
        ShapeBadge(
          size: 36,
          shape: MaterialShapes.clover4Leaf,
          color: DashboardColors.of(context).tone2,
          child: Text(
            group.name.characters.firstOrNull ?? 'P',
            style: AppTextStyle.headline.of(context),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardText.label(context),
              ),
              Text(
                group.selectedNode?.displayName ??
                    AppLocalizations.of(context).nodeNotSelected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardText.rowTitle(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
