import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart';
import 'package:prism_ui/shapes/shapes.dart';

import '../../../../app/router.dart';
import '../../../../core/platform/app_platform.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/ip_info.dart';
import '../../../../data/models/runtime_settings.dart';
import '../../../../features/connections/application/connections_notifier.dart';
import '../../../../features/proxies/application/proxies_notifier.dart';
import '../../../../features/subscriptions/application/subscriptions_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/core_status_l10n.dart';
import 'card.dart';
import 'edit.dart';
import 'widget_registry.dart';
import 'layout.dart';
import 'network_takeover.dart';
import 'outbound_mode.dart';
import 'start_toggle.dart';
import 'style.dart';
import 'traffic.dart';
import 'usage_progress.dart';
import 'connections_table.dart';
import 'proxy_groups.dart';

class TargetDashboard extends StatefulWidget {
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
    required this.dashboardOrder,
    required this.dashboardVisible,
    required this.editing,
    required this.onDone,
    required this.onWidgetsChanged,
    required this.serviceLabel,
    required this.serviceRunning,
    required this.serviceBusy,
    required this.onServiceStatusAction,
    this.header,
    this.footer,
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
  final List<String> dashboardOrder;
  final List<String> dashboardVisible;

  final bool editing;
  final VoidCallback onDone;
  final ValueChanged<List<DashboardWidget>> onWidgetsChanged;
  final String serviceLabel;
  final bool serviceRunning;
  final bool serviceBusy;
  final VoidCallback onServiceStatusAction;
  final Widget? header;
  final Widget? footer;

  @override
  State<TargetDashboard> createState() => _TargetDashboardState();
}

class _TargetDashboardState extends State<TargetDashboard> {
  final _keys = <DashboardWidget, GlobalKey>{};
  GlobalKey _cardKeyOf(DashboardWidget card) =>
      _keys.putIfAbsent(card, GlobalKey.new);

  Widget _cardOf(DashboardWidget card, {bool desktop = false}) =>
      switch (card) {
        DashboardWidget.status => _StatusCard(
          core: widget.core,
          onAction: widget.onServiceAction,
          info: widget.ipInfo,
        ),
        DashboardWidget.traffic => const NetworkSpeedCard(),
        DashboardWidget.outboundMode =>
          desktop
              ? OutboundModeBar(
                  core: widget.core,
                  onChanged: widget.onRouteModeChanged,
                )
              : OutboundModeCard(
                  core: widget.core,
                  onChanged: widget.onRouteModeChanged,
                ),
        DashboardWidget.networkTakeover =>
          desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    for (final kind in [
                      if (widget.capabilities.supportsMixedProxy)
                        TakeoverSwitch.systemProxy,
                      TakeoverSwitch.tun,
                    ])
                      Expanded(
                        child: NetworkTakeoverTile(
                          kind,
                          core: widget.core,
                          settings: widget.appSettings,
                          capabilities: widget.capabilities,
                          onProxyModeChanged: widget.onProxyModeChanged,
                          onSystemProxyChanged: widget.onSystemProxyChanged,
                        ),
                      ),
                  ],
                )
              : NetworkTakeoverCard(
                  core: widget.core,
                  settings: widget.appSettings,
                  capabilities: widget.capabilities,
                  onProxyModeChanged: widget.onProxyModeChanged,
                  onSystemProxyChanged: widget.onSystemProxyChanged,
                ),
        DashboardWidget.ip => _IpCard(
          info: widget.ipInfo,
          loading: widget.ipLoading,
          error: widget.ipError,
          onRefresh: widget.onRefreshIp,
        ),
        DashboardWidget.profiles => const _ProfilesCard(),
        DashboardWidget.proxyGroups =>
          desktop ? const ProxyGroupsCard() : const _ProxyGroupsCard(),
        DashboardWidget.service => _ServiceCard(
          label: widget.serviceLabel,
          running: widget.serviceRunning,
          busy: widget.serviceBusy,
          backend: widget.core.backendName,
          onTap: widget.onServiceStatusAction,
        ),
        DashboardWidget.memory => const _MemoryCard(),
        DashboardWidget.connections =>
          desktop ? const ConnectionsTableCard() : const _ConnectionsCard(),
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = math.max(1.0, MediaQuery.textScalerOf(context).scale(1));
      final density = widget.editing
          ? DashboardDensity.mobile
          : DashboardDensity.of(constraints.biggest / scale);
      final visible = {...widget.dashboardVisible, 'status'};
      final order = {
        ...widget.dashboardOrder,
        for (final item in defaultDashboardOrder)
          if (!widget.dashboardOrder.contains(item)) item,
      };
      final cards = [
        for (final name in order)
          for (final card in DashboardWidget.values)
            if (card.name == name && visible.contains(name)) card,
      ];
      final gap = density.isDesktop ? 16.0 : 12.0;
      final top = context.contentTopPadding;
      final bottom = 24 + context.bottomInset;
      return DashboardDensityScope(
        density: density,
        scale: scale,
        child: density.isDesktop
            ? _desktop(
                context,
                constraints,
                cards,
                density,
                scale,
                gap,
                top,
                bottom,
              )
            : CustomScrollView(
                scrollCacheExtent: widget.editing
                    ? ScrollCacheExtent.viewport(
                        DashboardWidget.values.length.toDouble(),
                      )
                    : null,
                slivers: [
                  if (widget.editing)
                    DashboardEditor(
                      widgets: cards,
                      cardOf: _cardOf,
                      cardKeyOf: _cardKeyOf,
                      padding: EdgeInsets.fromLTRB(
                        dashboardMobileSideOf(constraints.maxWidth),
                        top,
                        dashboardMobileSideOf(constraints.maxWidth),
                        bottom,
                      ),
                      gap: gap,
                      onDone: widget.onDone,
                      onChanged: widget.onWidgetsChanged,
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        dashboardMobileSideOf(constraints.maxWidth),
                        top,
                        dashboardMobileSideOf(constraints.maxWidth),
                        bottom,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: gap,
                          children: [
                            if (widget.header != null) widget.header!,
                            for (final card in cards)
                              RepaintBoundary(
                                key: _cardKeyOf(card),
                                child: _cardOf(card),
                              ),
                            if (widget.footer != null) widget.footer!,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      );
    },
  );

  Widget _desktop(
    BuildContext context,
    BoxConstraints constraints,
    List<DashboardWidget> cards,
    DashboardDensity density,
    double scale,
    double gap,
    double top,
    double bottom,
  ) {
    final columns = dashboardColumnsOf(constraints.maxWidth / scale);
    final room = constraints.maxWidth - 40 - gap * (columns - 1);
    final column = math.min(room / columns, 440 * scale);
    final inset = (room - column * columns) / 2;
    final topHeight = (density.isCompact ? 176.0 : 208.0) * scale;
    final controlHeight = (density.isCompact ? 56.0 : 64.0) * scale;
    final middleHeight = (density.isCompact ? 168.0 : 184.0) * scale;
    final feedHeight = math.max(
      240 * scale,
      constraints.maxHeight -
          top -
          bottom -
          topHeight -
          controlHeight -
          middleHeight -
          gap * 3,
    );
    Widget sized(int span, double height, Widget child) => SizedBox(
      width: column * span + gap * (span - 1),
      height: height,
      child: RepaintBoundary(child: child),
    );
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.fromSTEB(
        16 + inset,
        top,
        24 + inset,
        bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [
          if (widget.header != null) widget.header!,
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards)
                if (card == DashboardWidget.traffic) ...[
                  sized(
                    1,
                    topHeight,
                    const SpeedCard(direction: TrafficDirection.upload),
                  ),
                  sized(
                    1,
                    topHeight,
                    const SpeedCard(direction: TrafficDirection.download),
                  ),
                ] else
                  sized(
                    switch (card) {
                      DashboardWidget.status ||
                      DashboardWidget.outboundMode ||
                      DashboardWidget.networkTakeover ||
                      DashboardWidget.connections ||
                      DashboardWidget.proxyGroups => 2,
                      _ => 1,
                    },
                    switch (card) {
                      DashboardWidget.status => topHeight,
                      DashboardWidget.outboundMode ||
                      DashboardWidget.networkTakeover => controlHeight,
                      DashboardWidget.connections ||
                      DashboardWidget.proxyGroups => feedHeight,
                      _ => middleHeight,
                    },
                    _cardOf(card, desktop: true),
                  ),
            ],
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({
    required this.core,
    required this.onAction,
    required this.info,
  });
  final CoreState core;
  final VoidCallback onAction;
  final IpInfo? info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final metrics = _OutboundMetrics.of(density);
    final l10n = AppLocalizations.of(context);
    final colorScheme = context.colorScheme;
    final colors = DashboardColors.of(context);
    final node = ref.watch(proxiesProvider).selectedGroup?.selectedNode;
    return DashboardCard(
      padding: EdgeInsets.zero,
      semanticLabel: l10n.dashboardStatus,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: AppShape.all(dashboardCardRadius(density)),
                textDirection: Directionality.of(context),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    end: metrics.decorationEnd,
                    top: metrics.decorationTop,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: core.running ? 1 : 0),
                      duration: context.motionDuration(
                        const Duration(milliseconds: 400),
                      ),
                      curve: Curves.easeOutBack,
                      builder: (_, progress, _) => Transform.rotate(
                        angle: 2 * math.pi / 12 * progress,
                        child: Transform.scale(
                          scale: 1 + .12 * progress,
                          child: ShapeBadge(
                            shape: MaterialShapes.cookie12Sided,
                            color: Color.lerp(
                              colors.tone,
                              Color.alphaBlend(
                                colorScheme.primary.withValues(alpha: .1),
                                colors.card,
                              ),
                              progress.clamp(0, 1),
                            )!,
                            size: metrics.decorationSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: metrics.padding,
            child: Row(
              spacing: metrics.gap,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardCardHeader(
                        glyph: AppGlyphs.status,
                        title: l10n.dashboardStatus,
                        leading: [
                          DashboardChip(
                            label: core.available
                                ? l10n.coreStatusLabel(core.lifecycle)
                                : l10n.dashboardUnavailable,
                            tone: core.running
                                ? DashboardChipTone.ok
                                : DashboardChipTone.idle,
                            dot: core.running,
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.ipTop),
                      Row(
                        spacing: 12,
                        children: [
                          if (info != null)
                            ShapeBadge(
                              shape: MaterialShapes.clover4Leaf,
                              color: colors.tone,
                              size: metrics.badgeSize,
                              child: Text(
                                info!.countryCode,
                                style: AppTextStyle.footnote.of(
                                  context,
                                  emphasized: true,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                DashboardFitText(
                                  info?.ip ?? core.backendName,
                                  style: metrics.ip.of(
                                    context,
                                    emphasized: true,
                                  ),
                                ),
                                Text(
                                  info != null
                                      ? '${info!.country} · ${info!.isp}'
                                      : core.available
                                      ? l10n.startServicePrompt
                                      : l10n.coreUnavailable,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardText.label(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (density.isDesktop)
                        const Spacer()
                      else
                        const SizedBox(height: 16),
                      Text(
                        l10n.defaultNode,
                        style: DashboardText.label(context),
                      ),
                      Text(
                        node?.name ?? l10n.nodeNotSelected,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subheadline.of(
                          context,
                          emphasized: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: metrics.buttonSlot,
                  child: Center(
                    child: StartToggle(
                      size: metrics.buttonSize,
                      enabled: core.available,
                      running: core.showStop,
                      onToggle: onAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutboundMetrics {
  const _OutboundMetrics({
    required this.padding,
    required this.gap,
    required this.ipTop,
    required this.cellGap,
    required this.badgeSize,
    required this.ip,
    required this.buttonSize,
    required this.buttonSlot,
    required this.decorationSize,
    required this.decorationEnd,
    required this.decorationTop,
  });

  factory _OutboundMetrics.of(DashboardDensity density) => switch (density) {
    DashboardDensity.standard => _OutboundMetrics(
      padding: dashboardCardPadding(density),
      gap: 16,
      ipTop: 10,
      cellGap: 28,
      badgeSize: 48,
      ip: AppTextStyle.title1,
      buttonSize: 104,
      buttonSlot: 120,
      decorationSize: 290,
      decorationEnd: -64,
      decorationTop: -87,
    ),
    DashboardDensity.compact => _OutboundMetrics(
      padding: dashboardCardPadding(density),
      gap: 16,
      ipTop: 8,
      cellGap: 22,
      badgeSize: 40,
      ip: AppTextStyle.title2,
      buttonSize: 84,
      buttonSlot: 100,
      decorationSize: 250,
      decorationEnd: -64,
      decorationTop: -75,
    ),
    DashboardDensity.mobile => const _OutboundMetrics(
      padding: EdgeInsetsDirectional.fromSTEB(20, 18, 16, 18),
      gap: 10,
      ipTop: 12,
      cellGap: 24,
      badgeSize: 48,
      ip: AppTextStyle.title2,
      buttonSize: 88,
      buttonSlot: 88,
      decorationSize: 240,
      decorationEnd: -60,
      decorationTop: -66,
    ),
  };

  final EdgeInsetsGeometry padding;
  final double gap;
  final double ipTop;
  final double cellGap;
  final double badgeSize;
  final AppTextStyle ip;
  final double buttonSize;
  final double buttonSlot;
  final double decorationSize;
  final double decorationEnd;
  final double decorationTop;
}

class _IpCard extends StatelessWidget {
  const _IpCard({
    required this.info,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });
  final IpInfo? info;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.devices,
            title: l10n.ipInformation,
            trailing: [
              if (loading)
                const SizedBox.square(dimension: 24, child: ActivityIndicator())
              else
                DashboardIconButton(
                  tooltip: l10n.refresh,
                  onPressed: onRefresh,
                  glyph: AppGlyphs.refresh,
                ),
            ],
          ),
          DashboardFitText(
            info?.ip ?? (error != null ? l10n.failedToLoadIpInfo : '--'),
            style: AppTextStyle.title2.of(context, emphasized: true),
          ),
          if (info case final info?) ...[
            Text(
              '${info.country} · ${info.city}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DashboardText.label(context),
            ),
            Text(
              info.isp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DashboardText.label(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilesCard extends ConsumerWidget {
  const _ProfilesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(subscriptionsProvider).subscriptions;
    final l10n = AppLocalizations.of(context);
    final selected = profiles.where((profile) => profile.enabled).firstOrNull;
    final used = (selected?.uploadBytes ?? 0) + (selected?.downloadBytes ?? 0);
    final total = selected?.totalBytes;
    return DashboardCard(
      onTap: () => context.go(AppRoute.proxies.path),
      semanticLabel: l10n.profiles,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.profiles,
            title: l10n.profiles,
            chevron: true,
          ),
          const SizedBox(height: 12),
          Text(
            selected?.name ?? l10n.noActiveProfile,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.headline.of(context, emphasized: true),
          ),
          if (DashboardDensityScope.of(context).isDesktop)
            const Spacer()
          else
            const SizedBox(height: 16),
          if (total != null && total > 0) ...[
            Row(
              children: [
                Text(
                  '${(used / total * 100).round()}%',
                  style: DashboardText.figure(context, AppTextStyle.title2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatBytes(used)} / ${formatBytes(total)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: DashboardText.label(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 12,
              child: CustomPaint(
                painter: WavyProgressPainter(
                  value: (used / total).clamp(0, 1),
                  active: context.colorScheme.primary,
                  track: DashboardColors.of(context).tone2,
                ),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: '${profiles.length}',
                    label: l10n.profiles,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: formatBytes(used),
                    label: l10n.trafficUsed,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProxyGroupsCard extends ConsumerWidget {
  const _ProxyGroupsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(proxiesProvider).groups;
    final nodes = groups.expand((group) => group.nodes).length;
    return DashboardCard(
      onTap: () => context.go(AppRoute.nodes.path),
      semanticLabel: l10n.nodeSelection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.layers,
            title: l10n.nodeSelection,
            chevron: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${groups.length} ${l10n.dashboardGroups}',
                style: DashboardText.figure(context, AppTextStyle.title2),
              ),
              Text(
                '$nodes ${l10n.dashboardNodes}',
                style: DashboardText.label(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.label,
    required this.running,
    required this.busy,
    required this.backend,
    required this.onTap,
  });
  final String label;
  final bool running;
  final bool busy;
  final String backend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final density = DashboardDensityScope.of(context);
    final statusColor = running
        ? DashboardColors.of(context).ok
        : context.colorScheme.onSurfaceVariant;
    return DashboardCard(
      onTap: busy ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.verified,
            title: AppLocalizations.of(context).dashboardService,
            chevron: true,
          ),
          if (density.isDesktop) const Spacer() else const SizedBox(height: 16),
          if (busy)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActivityIndicator(),
            )
          else
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: statusColor.withValues(alpha: .12),
                    shape: AppShape.circle,
                  ),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: ShapeDecoration(
                      color: statusColor,
                      shape: AppShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: DashboardFitText(
                    label,
                    style: AppTextStyle.title2.of(context, emphasized: true),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            backend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardText.label(context),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard();

  @override
  Widget build(BuildContext context) => DashboardCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardCardHeader(
          glyph: AppGlyphs.memory,
          title: AppLocalizations.of(context).dashboardMemory,
        ),
        if (DashboardDensityScope.of(context).isDesktop)
          const Spacer()
        else
          const SizedBox(height: 16),
        Text(
          formatBytes(ProcessInfo.currentRss),
          style: DashboardText.figure(context, AppTextStyle.title1),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).dashboardAppMemory,
          style: DashboardText.label(context),
        ),
      ],
    ),
  );
}

class _ConnectionsCard extends ConsumerWidget {
  const _ConnectionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      connectionsProvider.select((state) => state.activeCount),
    );
    final l10n = AppLocalizations.of(context);
    return DashboardCard(
      onTap: () => context.go(AppRoute.connections.path),
      semanticLabel: l10n.connections,
      child: Row(
        children: [
          Expanded(
            child: DashboardCardHeader(
              glyph: AppGlyphs.connections,
              title: l10n.connections,
            ),
          ),
          Text(
            '$count',
            style: DashboardText.figure(context, AppTextStyle.title2),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: DashboardText.figure(context, AppTextStyle.title2)),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DashboardText.label(context),
      ),
    ],
  );
}
