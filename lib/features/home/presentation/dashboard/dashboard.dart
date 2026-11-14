import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart';
import 'package:prism_ui/shapes/shapes.dart';

import '../../../../app/router.dart';
import '../../../../core/platform/app_platform.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/ip_info.dart';
import '../../../../data/models/runtime_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/core_status_l10n.dart';
import 'card.dart';
import 'layout.dart';
import 'style.dart';
import 'traffic.dart';
import 'outbound_mode.dart';
import 'network_takeover.dart';
import 'start_toggle.dart';

class TargetDashboard extends StatelessWidget {
  const TargetDashboard({
    required this.core,
    required this.capabilities,
    required this.appSettings,
    required this.onProxyModeChanged,
    required this.onRouteModeChanged,
    required this.onSystemProxyChanged,
    required this.onServiceAction,
    required this.ipInfo,
    required this.ipLoading,
    required this.ipError,
    required this.onRefreshIp,
    super.key,
  });

  final CoreState core;
  final AppCapabilities capabilities;
  final AppSettings appSettings;
  final ValueChanged<ProxyMode> onProxyModeChanged;
  final ValueChanged<RouteMode> onRouteModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;
  final VoidCallback onServiceAction;
  final IpInfo? ipInfo;
  final bool ipLoading;
  final String? ipError;
  final VoidCallback onRefreshIp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
        final density = DashboardDensity.of(
          Size(constraints.maxWidth, MediaQuery.sizeOf(context).height) / scale,
        );
        final columns = density.isDesktop
            ? dashboardColumnsOf(constraints.maxWidth / scale)
            : 1;
        final gap = density.isDesktop ? 16.0 : 12.0;
        final column = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final wide = columns == 4;
        Widget sized(int span, Widget child) => SizedBox(
          width: column * span + gap * (span - 1),
          child: RepaintBoundary(child: child),
        );
        return DashboardDensityScope(
          density: density,
          scale: scale,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              sized(wide ? 2 : columns, _StatusCard(core: core, onAction: onServiceAction)),
              if (density.isDesktop)
                for (final direction in [TrafficDirection.download, TrafficDirection.upload])
                  SizedBox(
                    width: column,
                    height: (density.isCompact ? 176 : 208) * scale,
                    child: SpeedCard(direction: direction),
                  )
              else
                sized(1, const NetworkSpeedCard()),
              sized(wide ? 2 : columns, OutboundModeCard(core: core, onChanged: onRouteModeChanged)),
              sized(wide ? 2 : columns, NetworkTakeoverCard(
                core: core,
                settings: appSettings,
                capabilities: capabilities,
                onProxyModeChanged: onProxyModeChanged,
                onSystemProxyChanged: onSystemProxyChanged,
              )),
              sized(wide ? 2 : columns, _IpCard(info: ipInfo, loading: ipLoading, error: ipError, onRefresh: onRefreshIp)),
              sized(wide ? 2 : columns, _ConnectionsCard(core: core)),
            ],
          ),
        );
      },
    );
  }

}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.core, required this.onAction});

  final CoreState core;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    return DashboardCard(
      child: Row(
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                DashboardCardHeader(
                  glyph: AppGlyphs.status,
                  title: core.backendName,
                  trailing: [
                    DashboardChip(
                      label: l10n.coreStatusLabel(core.lifecycle),
                      tone: core.running ? DashboardChipTone.ok : DashboardChipTone.idle,
                      dot: core.running,
                    ),
                  ],
                ),
                Text(
                  core.running ? l10n.serviceRunning : l10n.serviceStopped,
                  style: AppTextStyle.title2.of(context, emphasized: true),
                ),
                Text(
                  core.available
                      ? (core.running ? l10n.trafficRouted : l10n.startServicePrompt)
                      : l10n.coreUnavailable,
                  style: AppTextStyle.footnote.of(context).copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          StartToggle(
            size: 72,
            enabled: core.available && !core.busy,
            running: core.running,
            onToggle: onAction,
          ),
        ],
      ),
    );
  }
}

class _IpCard extends StatelessWidget {
  const _IpCard({required this.info, required this.loading, required this.error, required this.onRefresh});
  final IpInfo? info;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.colorScheme;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.proxies,
            title: l10n.ipInformation,
            trailing: [
              IconButton(
                tooltip: l10n.refresh,
                onPressed: loading ? null : onRefresh,
                icon: loading ? const ActivityIndicator() : const GlyphIcon(AppGlyphs.refresh, size: 18),
              ),
            ],
          ),
          DashboardFitText(
            info?.ip ?? (error != null ? l10n.failedToLoadIpInfo : '--'),
            style: AppTextStyle.title2.of(context, emphasized: true),
          ),
          if (info case final info?) ...[
            DashboardBlock(
              radius: DashboardCorner.block,
              padding: const EdgeInsets.all(14),
              child: Row(
                spacing: 12,
                children: [
                  ShapeBadge(
                    shape: MaterialShapes.clover4Leaf,
                    color: scheme.primary.withValues(alpha: 0.12),
                    size: 44,
                    child: Text(info.countryCode, style: AppTextStyle.footnote.of(context, emphasized: true).copyWith(color: scheme.primary)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text('${info.country} · ${info.city}', style: AppTextStyle.subheadline.of(context, emphasized: true)),
                        Text(info.isp, style: DashboardText.label(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(info.asName, style: DashboardText.label(context)),
          ],
        ],
      ),
    );
  }
}

class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard({required this.core});
  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardCard(
      onTap: () => context.go(AppRoute.connections.path),
      semanticLabel: l10n.connections,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          DashboardCardHeader(glyph: AppGlyphs.connections, title: l10n.activeConnections, chevron: true),
          Text(core.running && core.traffic.available ? '${core.traffic.activeConnections}' : '--', style: DashboardText.figure(context, AppTextStyle.display)),
          Text(l10n.connections, style: DashboardText.label(context)),
        ],
      ),
    );
  }
}

