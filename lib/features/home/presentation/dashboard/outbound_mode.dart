import 'package:flutter/widgets.dart';

import 'package:prism_ui/prism_ui.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/runtime_settings.dart';
import '../../../../l10n/app_localizations.dart';
import 'card.dart';
import 'layout.dart';
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
  const OutboundModeCard({
    required this.core,
    required this.onChanged,
    super.key,
  });

  final CoreState core;
  final ValueChanged<RouteMode> onChanged;

  static const _outer = 26.0;
  static const _modes = [RouteMode.rule, RouteMode.all, RouteMode.direct];

  @override
  Widget build(BuildContext context) {
    final mode = core.selectedSettings.routeMode;
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
                    busy: core.busy,
                    first: index == 0,
                    last: index == 2,
                    outer: _outer,
                    inner: 12,
                    background: tone,
                    semanticLabel: _labelOf(context, item),
                    onTap: () {
                      if (item != mode) onChanged(item);
                    },
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

class OutboundModeBar extends StatelessWidget {
  const OutboundModeBar({
    required this.core,
    required this.onChanged,
    super.key,
  });

  final CoreState core;
  final ValueChanged<RouteMode> onChanged;

  static const _inset = 8.0;

  @override
  Widget build(BuildContext context) {
    final density = DashboardDensityScope.of(context);
    final mode = core.selectedSettings.routeMode;
    final appLocalizations = AppLocalizations.of(context);
    final outer = dashboardCardRadius(density) - _inset;
    final style = AppTextStyle.subheadline.of(context, emphasized: true);
    return DashboardCard(
      semanticLabel: appLocalizations.routingMode,
      padding: EdgeInsetsDirectional.fromSTEB(
        dashboardCardPadding(density).left,
        _inset,
        _inset,
        _inset,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: 16,
          children: [
            GlyphIcon(
              AppGlyphs.split,
              size: 18,
              color: context.colorScheme.onSurfaceVariant,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 4),
              child: Text(
                appLocalizations.routingMode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardText.cardTitle(context),
              ),
            ),
            Expanded(
              child: DashboardConnectedGroup(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in OutboundModeCard._modes.indexed)
                    Expanded(
                      child: DashboardConnectedButton(
                        selected: item == mode,
                        busy: core.busy,
                        first: index == 0,
                        last: index == OutboundModeCard._modes.length - 1,
                        outer: outer,
                        inner: 10,
                        background: DashboardColors.of(context).tone,
                        semanticLabel: _labelOf(context, item),
                        onTap: () {
                          if (item != mode) onChanged(item);
                        },
                        builder: (foreground) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            GlyphIcon(
                              _glyphOf(item),
                              size: 18,
                              color: foreground,
                            ),
                            Flexible(
                              child: Text(
                                _labelOf(context, item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.copyWith(color: foreground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
