import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/runtime/core_notifier.dart';
import '../../core/runtime/core_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/app_platform.dart';
import '../../core/utils/format_bytes.dart';
import 'package:targetlib/targetlib.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/runtime_settings.dart' as runtime_models;
import '../../data/models/ip_info.dart';
import '../../core/widgets/target_page_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/core_status_l10n.dart';
import '../proxies/application/proxies_notifier.dart';
import '../settings/application/settings_notifier.dart';
import 'presentation/widgets/connection_error_banner.dart';
import 'presentation/widgets/current_profile_card.dart';
import 'presentation/widgets/ip_info_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  IpInfo? _ipInfo;
  bool _ipLoading = false;
  String? _ipError;
  bool _serviceChecking = true;
  bool _serviceCheckFailed = false;
  bool _serviceStarting = false;
  TargetLibServiceStatus? _serviceStatus;
  String? _serviceError;
  final _serviceController = TargetLibServiceController();

  @override
  void initState() {
    super.initState();
    _fetchIpInfo();
    if (!ref.read(appCapabilitiesProvider).supportsManagedService) {
      _serviceChecking = false;
    } else {
      _checkTargetLibService();
    }
  }

  Future<void> _checkTargetLibService() async {
    try {
      final result = await _serviceController.status();
      if (mounted) {
        setState(() {
          _serviceChecking = false;
          _serviceCheckFailed = false;
          _serviceStatus = result.status;
          _serviceError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _serviceChecking = false;
          _serviceCheckFailed = true;
          _serviceStatus = null;
          _serviceError = error.toString();
        });
      }
    }
  }

  Future<void> _startTargetLibService() async {
    setState(() {
      _serviceStarting = true;
      _serviceError = null;
    });
    try {
      await _serviceController.start();
      if (mounted) {
        setState(() {
          _serviceStatus = TargetLibServiceStatus.running;
          _serviceCheckFailed = false;
          _serviceError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _serviceError = error.toString());
    } finally {
      if (mounted) setState(() => _serviceStarting = false);
    }
  }

  Future<void> _fetchIpInfo() async {
    setState(() {
      _ipLoading = true;
      _ipError = null;
    });
    try {
      final info = await ref.read(coreGatewayProvider).fetchIpInfo();
      if (mounted) setState(() => _ipInfo = info);
    } catch (e) {
      if (mounted) setState(() => _ipError = e.toString());
    } finally {
      if (mounted) setState(() => _ipLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = ref.watch(coreProvider);
    final capabilities = ref.watch(appCapabilitiesProvider);
    final appSettings = ref.watch(settingsProvider).settings;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TargetPageScaffold(
      title: l10n.dashboard,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (capabilities.supportsManagedService &&
                  !_serviceChecking &&
                  (_serviceCheckFailed ||
                      _serviceStatus != TargetLibServiceStatus.running)) ...[
                _ServiceStatusCard(
                  starting: _serviceStarting,
                  status: _serviceStatus,
                  checkFailed: _serviceCheckFailed,
                  error: _serviceError,
                  onAction:
                      !_serviceCheckFailed &&
                          _serviceStatus == TargetLibServiceStatus.stopped
                      ? _startTargetLibService
                      : _checkTargetLibService,
                ),
                const SizedBox(height: 16),
              ],
              _DashboardCards(
                core: core,
                capabilities: capabilities,
                appSettings: appSettings,
                wide: wide,
                onProxyModeChanged: _changeProxyMode,
                onRouteModeChanged: _changeRouteMode,
                onSystemProxyChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .updateSettings(
                      (settings) => settings.copyWith(systemProxy: value),
                    ),
                onServiceAction: () => core.running
                    ? ref.read(coreProvider.notifier).stop()
                    : _connect(),
              ),
              if (core.message.isNotEmpty &&
                  (!core.available ||
                      core.lifecycle == CoreLifecycle.failed)) ...[
                const SizedBox(height: 16),
                ConnectionErrorBanner(message: core.message),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.nodeSelection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoute.nodes.path),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l10n.nodeLibrary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _ProxyWorkspaceCard(),
              const SizedBox(height: 20),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: CurrentProfileCard(core: core)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: IpInfoCard(
                          ipInfo: _ipInfo,
                          loading: _ipLoading,
                          error: _ipError,
                          onRefresh: _fetchIpInfo,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    CurrentProfileCard(core: core),
                    const SizedBox(height: 16),
                    IpInfoCard(
                      ipInfo: _ipInfo,
                      loading: _ipLoading,
                      error: _ipError,
                      onRefresh: _fetchIpInfo,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _connect() async {
    final notifier = ref.read(coreProvider.notifier);
    await notifier.start();
    if (!mounted) return;

    final core = ref.read(coreProvider);
    if (core.lifecycle != CoreLifecycle.failed) return;

    // The core reports failures in English for diagnostics; the UI shows a
    // localized summary and the raw detail stays in the log.
    AppLogger.warning('Core connect failed: ${core.message}', source: 'home');
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          content: Text(l10n.connectionErrorMessage),
          action: SnackBarAction(
            label: l10n.viewLogs,
            onPressed: () {
              if (mounted) context.go(AppRoute.logs.path);
            },
          ),
        ),
      );
  }

  Future<void> _changeProxyMode(runtime_models.ProxyMode mode) async {
    final current = ref.read(coreProvider).settings;
    await _updateRuntimeConfig(
      current.proxyMode == mode ? null : current.copyWith(proxyMode: mode),
    );
  }

  Future<void> _changeRouteMode(runtime_models.RouteMode mode) async {
    final current = ref.read(coreProvider).settings;
    await _updateRuntimeConfig(
      current.routeMode == mode ? null : current.copyWith(routeMode: mode),
    );
  }

  Future<void> _updateRuntimeConfig(
    runtime_models.RuntimeSettings? settings,
  ) async {
    if (settings == null) return;
    await ref.read(coreProvider.notifier).updateRuntimeConfig(settings);
    if (!mounted) return;
    final core = ref.read(coreProvider);
    if (core.lifecycle == CoreLifecycle.failed) {
      _showMessage(
        AppLocalizations.of(context).connectionErrorMessage,
        error: true,
      );
    }
  }

  void _showMessage(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({
    required this.core,
    required this.capabilities,
    required this.appSettings,
    required this.wide,
    required this.onProxyModeChanged,
    required this.onRouteModeChanged,
    required this.onSystemProxyChanged,
    required this.onServiceAction,
  });

  final CoreState core;
  final AppCapabilities capabilities;
  final AppSettings appSettings;
  final bool wide;
  final ValueChanged<runtime_models.ProxyMode> onProxyModeChanged;
  final ValueChanged<runtime_models.RouteMode> onRouteModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;
  final VoidCallback onServiceAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = wide ? (constraints.maxWidth - 16) / 2 : null;
        final serviceCard = _ServiceOverviewCard(
          core: core,
          onAction: onServiceAction,
        );
        final trafficCard = _TrafficSummaryCard(core: core);
        final settingsCard = _RoutingSettingsCard(
          core: core,
          capabilities: capabilities,
          appSettings: appSettings,
          onProxyModeChanged: onProxyModeChanged,
          onRouteModeChanged: onRouteModeChanged,
          onSystemProxyChanged: onSystemProxyChanged,
        );

        if (!wide) {
          return Column(
            children: [
              serviceCard,
              const SizedBox(height: 16),
              trafficCard,
              const SizedBox(height: 16),
              settingsCard,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: cardWidth, child: serviceCard),
                const SizedBox(width: 16),
                SizedBox(width: cardWidth, child: trafficCard),
              ],
            ),
            const SizedBox(height: 16),
            settingsCard,
          ],
        );
      },
    );
  }
}

class _ServiceOverviewCard extends StatelessWidget {
  const _ServiceOverviewCard({required this.core, required this.onAction});

  final CoreState core;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusColor = core.running
        ? Colors.green
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.profiles,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    l10n.coreStatusLabel(core.lifecycle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              core.running ? l10n.serviceRunning : l10n.serviceStopped,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              core.available
                  ? (core.running
                        ? l10n.trafficRouted
                        : l10n.startServicePrompt)
                  : l10n.coreUnavailable,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: core.busy || !core.available ? null : onAction,
                icon: Icon(
                  core.running
                      ? Icons.stop_circle_outlined
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  core.busy
                      ? l10n.working
                      : core.running
                      ? l10n.stop
                      : l10n.start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficSummaryCard extends StatelessWidget {
  const _TrafficSummaryCard({required this.core});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final traffic = core.traffic;
    final available = core.running && traffic.available;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.liveTraffic,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoute.traffic.path),
                  child: Text(l10n.traffic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TrafficMetric(
                    label: l10n.uploadRate,
                    value: available ? formatSpeed(traffic.uploadBytes) : '--',
                    color: colors.tertiary,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TrafficMetric(
                    label: l10n.downloadRate,
                    value: available
                        ? formatSpeed(traffic.downloadBytes)
                        : '--',
                    color: colors.primary,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TrafficMetric(
              label: l10n.activeConnections,
              value: available ? '${traffic.activeConnections}' : '--',
              color: colors.secondary,
              icon: Icons.hub_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficMetric extends StatelessWidget {
  const _TrafficMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveModeSelector<T> extends StatelessWidget {
  const _ResponsiveModeSelector({
    required this.value,
    required this.items,
    required this.segments,
    required this.busy,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final List<ButtonSegment<T>> segments;
  final bool busy;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: busy
                ? null
                : (selected) {
                    if (selected != null) onChanged(selected);
                  },
          );
        }
        return SegmentedButton<T>(
          expandedInsets: EdgeInsets.zero,
          segments: segments,
          selected: {value},
          onSelectionChanged: busy
              ? null
              : (selected) {
                  if (selected.isNotEmpty) onChanged(selected.first);
                },
        );
      },
    );
  }
}

class _RoutingSettingsCard extends StatelessWidget {
  const _RoutingSettingsCard({
    required this.core,
    required this.capabilities,
    required this.appSettings,
    required this.onProxyModeChanged,
    required this.onRouteModeChanged,
    required this.onSystemProxyChanged,
  });

  final CoreState core;
  final AppCapabilities capabilities;
  final AppSettings appSettings;
  final ValueChanged<runtime_models.ProxyMode> onProxyModeChanged;
  final ValueChanged<runtime_models.RouteMode> onRouteModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 900;
            final proxy = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.proxyMode, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (capabilities.vpnOnly)
                  Row(
                    children: [
                      const Icon(Icons.vpn_lock_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.vpnTun),
                    ],
                  )
                else
                  _ResponsiveModeSelector<runtime_models.ProxyMode>(
                    value: core.settings.proxyMode,
                    busy: core.busy,
                    items: [
                      DropdownMenuItem(
                        value: runtime_models.ProxyMode.mixed,
                        child: Text(l10n.mixed),
                      ),
                      DropdownMenuItem(
                        value: runtime_models.ProxyMode.tun,
                        child: Text(l10n.tun),
                      ),
                    ],
                    segments: [
                      ButtonSegment(
                        value: runtime_models.ProxyMode.mixed,
                        icon: const Icon(Icons.lan_outlined),
                        label: Text(l10n.mixed),
                      ),
                      ButtonSegment(
                        value: runtime_models.ProxyMode.tun,
                        icon: const Icon(Icons.vpn_lock_outlined),
                        label: Text(l10n.tun),
                      ),
                    ],
                    onChanged: onProxyModeChanged,
                  ),
                if (capabilities.supportsMixedProxy) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.systemProxy),
                    subtitle: Text(l10n.systemProxyDescription),
                    value: appSettings.systemProxy,
                    onChanged: onSystemProxyChanged,
                  ),
                ],
              ],
            );
            final route = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.routingMode, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _ResponsiveModeSelector<runtime_models.RouteMode>(
                  value: core.settings.routeMode,
                  busy: core.busy,
                  items: [
                    for (final mode in runtime_models.RouteMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(switch (mode) {
                          runtime_models.RouteMode.rule => l10n.rule,
                          runtime_models.RouteMode.direct => l10n.direct,
                          runtime_models.RouteMode.all => l10n.all,
                        }),
                      ),
                  ],
                  segments: [
                    ButtonSegment(
                      value: runtime_models.RouteMode.rule,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: Text(l10n.rule),
                    ),
                    ButtonSegment(
                      value: runtime_models.RouteMode.direct,
                      icon: const Icon(Icons.flash_on_outlined),
                      label: Text(l10n.direct),
                    ),
                    ButtonSegment(
                      value: runtime_models.RouteMode.all,
                      icon: const Icon(Icons.public),
                      label: Text(l10n.all),
                    ),
                  ],
                  onChanged: onRouteModeChanged,
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.routingMode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (horizontal)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: proxy),
                      const SizedBox(width: 20),
                      Expanded(child: route),
                    ],
                  )
                else ...[
                  proxy,
                  const SizedBox(height: 16),
                  route,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProxyWorkspaceCard extends ConsumerWidget {
  const _ProxyWorkspaceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proxiesProvider);
    final theme = Theme.of(context);
    final group = state.selectedGroup;
    final nodes = group?.nodes ?? const [];
    final selected = group?.selectedNode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group?.name ?? AppLocalizations.of(context).emptyPool,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${nodes.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (nodes.isEmpty)
              Text(
                AppLocalizations.of(context).noSubscriptionsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        selected?.displayName ??
                            AppLocalizations.of(context).nodeNotSelected,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected?.latencyMs != null)
                      Text(
                        '${selected!.latencyMs} ms',
                        style: theme.textTheme.labelMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nodes.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final active = node.id == group?.selectedNodeId;
                    return ChoiceChip(
                      label: Text(node.displayName),
                      selected: active,
                      onSelected: (_) => ref
                          .read(proxiesProvider.notifier)
                          .selectNode(node.id),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({
    required this.starting,
    required this.status,
    required this.checkFailed,
    required this.error,
    required this.onAction,
  });

  final bool starting;
  final TargetLibServiceStatus? status;
  final bool checkFailed;
  final String? error;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    checkFailed
                        ? l10n.serviceCheckFailed
                        : status == TargetLibServiceStatus.stopped
                        ? l10n.targetLibStopped
                        : status == TargetLibServiceStatus.notInstalled
                        ? l10n.targetLibNotInstalled
                        : l10n.targetLibUnknown,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              (checkFailed ? error : null) ??
                  (status == TargetLibServiceStatus.stopped
                      ? l10n.startRegisteredService
                      : l10n.repairTargetLib),
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: starting ? null : onAction,
                icon: starting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        !checkFailed && status == TargetLibServiceStatus.stopped
                            ? Icons.play_arrow
                            : Icons.refresh,
                      ),
                label: Text(
                  starting
                      ? l10n.starting
                      : !checkFailed && status == TargetLibServiceStatus.stopped
                      ? l10n.startService
                      : l10n.checkAgain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
