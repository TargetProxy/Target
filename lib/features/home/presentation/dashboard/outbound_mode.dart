import 'package:flutter/widgets.dart';

import 'package:prism_ui/prism_ui.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/runtime_settings.dart';
import '../../../../l10n/app_localizations.dart';
import 'card.dart';
import 'style.dart';

Glyph _glyphOf(RouteMode mode) => switch (mode) {
  RouteMode.rule => AppGlyphs.rules,
  RouteMode.all => AppGlyphs.proxies,
  RouteMode.direct => AppGlyphs.target,
};

String _labelOf(BuildContext context, RouteMode mode) {
  final l10n = AppLocalizations.of(context);
  return switch (mode) {
    RouteMode.rule => l10n.rule,
    RouteMode.all => l10n.all,
    RouteMode.direct => l10n.direct,
  };
}

class OutboundModeCard extends StatelessWidget {
  const OutboundModeCard({required this.core, required this.onChanged, super.key});

  final CoreState core;
  final ValueChanged<RouteMode> onChanged;

  static const _outer = 26.0;
  static const _modes = [RouteMode.rule, RouteMode.all, RouteMode.direct];

  @override
  Widget build(BuildContext context) {
    final mode = core.settings.routeMode;
    final tone = DashboardColors.of(context).tone;
    final style = AppTextStyle.footnote.of(context, emphasized: true);
    return DashboardCard(
      semanticLabel: AppLocalizations.of(context).routingMode,
      child: Column(
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.split,
            title: AppLocalizations.of(context).routingMode,
          ),
          const SizedBox(height: 12),
          DashboardConnectedGroup(
            children: [
              for (final (index, item) in _modes.indexed)
                Expanded(
                  child: DashboardConnectedButton(
                    selected: item == mode,
                    first: index == 0,
                    last: index == 2,
                    outer: _outer,
                    inner: 12,
                    background: tone,
                    semanticLabel: _labelOf(context, item),
                    onTap: () { if (!core.busy && item != mode) onChanged(item); },
                    builder: (foreground) => SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 2,
                        children: [
                          GlyphIcon(
                            _glyphOf(item),
                            size: 18,
                            color: foreground,
                          ),
                          Text(
                            _labelOf(context, item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.copyWith(color: foreground),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

