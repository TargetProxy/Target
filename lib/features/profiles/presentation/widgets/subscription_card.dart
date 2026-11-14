import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/ui/chip_title.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../data/models/subscription.dart';
import '../../../../l10n/app_localizations.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    required this.profile,
    required this.busy,
    required this.isUpdating,
    required this.onToggle,
    required this.onUpdate,
    required this.onDetails,
    super.key,
  });

  final Subscription profile;
  final bool busy;
  final bool isUpdating;
  final VoidCallback onToggle;
  final VoidCallback onUpdate;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final isSelected = profile.enabled;
    return ContextMenuRegion(
      menuItems: [
        PopupMenuItem(glyph: AppGlyphs.refresh, label: AppLocalizations.of(context).updateSubscription, onPressed: busy ? null : onUpdate),
        PopupMenuItem(glyph: AppGlyphs.info, label: AppLocalizations.of(context).subscriptionDetails, onPressed: onDetails),
      ],
      child: Card(
        enterActionsOnRight: true,
        radius: AppCorner.xl,
        isSelected: isSelected,
        onPressed: busy ? null : onToggle,
        child: ListRow(
          key: Key(profile.id.toString()),
          minHeight: 88,
          minVerticalPadding: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context).subscriptionDetails,
                onPressed: onDetails,
                icon: const GlyphIcon(AppGlyphs.info, size: 20),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).updateSubscription,
                onPressed: busy ? null : onUpdate,
                icon: isUpdating ? const ActivityIndicator(size: 20) : const GlyphIcon(AppGlyphs.refresh, size: 20),
              ),
              if (isSelected) const SelectionBadge(size: 24),
            ],
          ),
          title: _ProfileCardTitle(
            profile: profile,
            expire: profile.expiresAt,
            subtitle: '${AppLocalizations.of(context).poolNodeCount(profile.nodeCount)} · ${formatBytes(profile.uploadBytes + profile.downloadBytes)}',
          ),
        ),
      ),
    );
  }
}

class _ProfileCardTitle extends StatelessWidget {
  const _ProfileCardTitle({
    required this.profile,
    required this.expire,
    required this.subtitle,
  });

  final Subscription profile;
  final DateTime? expire;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipTitle(
          title: profile.name,
          expire: expire,
          style: AppTextStyle.headline.of(context),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyle.footnote.of(context).toLighter,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

