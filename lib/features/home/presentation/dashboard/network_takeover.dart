import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';
import '../../../../core/platform/app_platform.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/runtime_settings.dart';
import '../../../../l10n/app_localizations.dart';

import 'card.dart';
import 'layout.dart';

typedef _RowMetrics = ({
  EdgeInsets padding,
  double titleStart,
  double radius,
  double icon,
  bool subtitle,
});

const _RowMetrics _cardRowMetrics = (
  padding: EdgeInsets.fromLTRB(10, 10, 12, 10),
  titleStart: 14,
  radius: 20,
  icon: 38,
  subtitle: true,
);

enum TakeoverSwitch { systemProxy, tun }

class _TakeoverRow extends StatelessWidget {
  const _TakeoverRow({
    required this.kind,
    required this.core,
    required this.settings,
    required this.onProxyModeChanged,
    required this.onSystemProxyChanged,
    required this.supportsMixedProxy,
    required this.metrics,
    required this.showIcon,
    this.color,
  });

  final TakeoverSwitch kind;
  final CoreState core;
  final AppSettings settings;
  final ValueChanged<ProxyMode> onProxyModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;
  final bool supportsMixedProxy;
  final _RowMetrics metrics;
  final bool showIcon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final systemProxy = kind == TakeoverSwitch.systemProxy;
    final title = _titleOf(context, kind);
    final value = systemProxy
        ? settings.systemProxy
        : core.selectedSettings.proxyMode == ProxyMode.tun;
    final on = systemProxy
        ? '${core.settings.mixedPort}'
        : appLocalizations.enabled;
    void change(bool value) {
      if (systemProxy) {
        onSystemProxyChanged(value);
      } else {
        onProxyModeChanged(value ? ProxyMode.tun : ProxyMode.mixed);
      }
    }

    final enabled = systemProxy || supportsMixedProxy;
    return DashboardSwitchRow(
      glyph: systemProxy ? AppGlyphs.shuffle : AppGlyphs.vpn,
      title: title,
      subtitle: metrics.subtitle
          ? value
                ? on
                : appLocalizations.disabled
          : null,
      value: value,
      iconSize: metrics.icon,
      padding: showIcon
          ? metrics.padding
          : metrics.padding.copyWith(left: metrics.titleStart),
      radius: metrics.radius,
      color: color,
      showIcon: showIcon,
      onTap: enabled ? () => change(!value) : null,
      onChanged: enabled ? change : null,
    );
  }
}

String _titleOf(BuildContext context, TakeoverSwitch kind) => switch (kind) {
  TakeoverSwitch.systemProxy => AppLocalizations.of(context).systemProxy,
  TakeoverSwitch.tun => AppLocalizations.of(context).tun,
};

/// Both switches in one card, for the card list of a narrow window.
class NetworkTakeoverCard extends StatelessWidget {
  const NetworkTakeoverCard({
    required this.core,
    required this.settings,
    required this.capabilities,
    required this.onProxyModeChanged,
    required this.onSystemProxyChanged,
    super.key,
  });

  final CoreState core;
  final AppSettings settings;
  final AppCapabilities capabilities;
  final ValueChanged<ProxyMode> onProxyModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;

  @override
  Widget build(BuildContext context) {
    const metrics = _cardRowMetrics;
    final kinds = [
      if (capabilities.supportsMixedProxy) TakeoverSwitch.systemProxy,
      TakeoverSwitch.tun,
    ];
    final appLocalizations = AppLocalizations.of(context);
    return DashboardCard(
      semanticLabel: appLocalizations.proxyMode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.shuffle,
            title: appLocalizations.proxyMode,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final showIcon = DashboardSwitchRow.iconFits(
                context,
                width: constraints.maxWidth,
                iconSize: metrics.icon,
                padding: metrics.padding,
                titles: [for (final kind in kinds) _titleOf(context, kind)],
              );
              return Column(
                spacing: 8,
                children: [
                  for (final kind in kinds)
                    _TakeoverRow(
                      kind: kind,
                      core: core,
                      settings: settings,
                      onProxyModeChanged: onProxyModeChanged,
                      onSystemProxyChanged: onSystemProxyChanged,
                      supportsMixedProxy: capabilities.supportsMixedProxy,
                      metrics: metrics,
                      showIcon: showIcon,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

_RowMetrics _tileMetricsOf(DashboardDensity density) => density.isCompact
    ? (
        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
        titleStart: dashboardCardPadding(density).left,
        radius: dashboardCardRadius(density),
        icon: 36,
        subtitle: false,
      )
    : (
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
        titleStart: dashboardCardPadding(density).left,
        radius: dashboardCardRadius(density),
        icon: 40,
        subtitle: true,
      );

class NetworkTakeoverTile extends StatelessWidget {
  const NetworkTakeoverTile(
    this.kind, {
    required this.core,
    required this.settings,
    required this.capabilities,
    required this.onProxyModeChanged,
    required this.onSystemProxyChanged,
    super.key,
  });
  final CoreState core;
  final AppSettings settings;
  final AppCapabilities capabilities;
  final ValueChanged<ProxyMode> onProxyModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;

  final TakeoverSwitch kind;

  @override
  Widget build(BuildContext context) {
    final metrics = _tileMetricsOf(DashboardDensityScope.of(context));
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => _TakeoverRow(
          kind: kind,
          core: core,
          settings: settings,
          supportsMixedProxy: capabilities.supportsMixedProxy,
          onProxyModeChanged: onProxyModeChanged,
          onSystemProxyChanged: onSystemProxyChanged,
          metrics: metrics,
          color: Colors.transparent,
          showIcon: DashboardSwitchRow.iconFits(
            context,
            width: constraints.maxWidth,
            iconSize: metrics.icon,
            padding: metrics.padding,
            titles: [
              for (final kind in TakeoverSwitch.values) _titleOf(context, kind),
            ],
          ),
        ),
      ),
    );
  }
}
