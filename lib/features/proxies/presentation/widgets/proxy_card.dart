import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/proxy_node.dart';
import '../../../../l10n/app_localizations.dart';

class ProxyCard extends StatelessWidget {
  const ProxyCard({
    required this.proxy,
    required this.source,
    required this.selected,
    required this.testing,
    required this.latencyColor,
    required this.onTestLatency,
    required this.onSelected,
    super.key,
  });

  final ProxyNode proxy;
  final String source;
  final bool selected;
  final bool testing;
  final Color latencyColor;
  final VoidCallback? onTestLatency;
  final VoidCallback onSelected;

  static const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const _titleGap = 3.0;
  static const _actionGap = 4.0;
  static const _badgeSize = 18.0;

  static double extentOf(BuildContext context) {
    final measure = MeasureScope.of(context);
    final theme = Theme.of(context);
    final actionHeight = math.max(
      (theme.tapTargetSize == TapTargetSize.padded ? 48.0 : 40.0) +
          theme.visualDensity.baseSizeAdjustment.dy,
      measure.textHeight(AppTextStyle.caption1),
    );
    return (Card.paddingOf(context, _padding).vertical +
            measure.textHeight(AppTextStyle.headline) * 2 +
            _titleGap +
            measure.textHeight(AppTextStyle.footnote) +
            _actionGap +
            actionHeight)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sourceLabel =
        '$source · ${proxy.typeLabel}${proxy.isAvailable ? '' : ' · ${l10n.nodeUnavailable}'}';
    final latency = switch (proxy) {
      ProxyNode(latencyTimedOut: true) => l10n.timeout,
      ProxyNode(latencyFailed: true) => l10n.latencyTestFailed,
      ProxyNode(latencyMs: final int ms) => '$ms ms',
      _ => null,
    };
    final result = testing ? null : latency;
    final actionStyle = AppTextStyle.caption1.of(context, emphasized: true);
    final action = TextButton.icon(
      onPressed: onTestLatency,
      style: ButtonStyle(
        textStyle: actionStyle,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      icon: testing
          ? const ActivityIndicator(size: 16)
          : const GlyphIcon(AppGlyphs.bolt, size: 16),
      label: Text(
        result ?? l10n.testLatency,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: result == null ? null : TextStyle(color: latencyColor),
      ),
    );
    return Card(
      radius: AppCorner.lg,
      enterActionsOnRight: true,
      onPressed: proxy.isAvailable ? onSelected : null,
      isSelected: selected,
      padding: _padding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _badgeSize + 4),
                child: TooltipText(
                  text: Text(
                    proxy.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.headline.of(context),
                  ),
                ),
              ),
              const SizedBox(height: _titleGap),
              TooltipText(
                text: Text(
                  sourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.footnote.of(context).toLighter,
                ),
              ),
              if (proxy.isAvailable) ...[
                const SizedBox(height: _actionGap),
                if (result == null)
                  action
                else
                  Tooltip(message: l10n.testLatency, child: action),
              ] else if (result != null) ...[
                const SizedBox(height: _actionGap),
                Text(result, style: actionStyle.copyWith(color: latencyColor)),
              ],
            ],
          ),
          if (selected)
            const PositionedDirectional(
              top: 0,
              end: 0,
              child: SelectionBadge(size: _badgeSize),
            ),
        ],
      ),
    );
  }
}
