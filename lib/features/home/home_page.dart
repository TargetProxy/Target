import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/runtime/core_notifier.dart';
import '../../core/runtime/core_models.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/app_platform.dart';
import 'package:targetlib/targetlib.dart';
import '../../data/models/runtime_settings.dart' as runtime_models;
import '../../data/models/ip_info.dart';
import '../../core/widgets/target_page_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/core_status_l10n.dart';
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

  Future<void> _refreshTargetLibService() async {
    await _checkTargetLibService();
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
                      : _refreshTargetLibService,
                ),
                const SizedBox(height: 16),
              ],
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: core.running
                                  ? Colors.green
                                  : theme.colorScheme.outline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              l10n.coreStatusLabel(core.lifecycle),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: core.running
                                    ? Colors.green
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        core.running
                            ? l10n.serviceRunning
                            : l10n.serviceStopped,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        core.available
                            ? (core.running
                                  ? l10n.trafficRouted
                                  : l10n.startServicePrompt)
                            : l10n.coreUnavailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.proxyMode, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      if (capabilities.vpnOnly)
                        Row(
                          children: [
                            Icon(Icons.vpn_lock_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.vpnTun),
                          ],
                        )
                      else
                        SegmentedButton<runtime_models.ProxyMode>(
                          expandedInsets: EdgeInsets.zero,
                          segments: [
                            ButtonSegment(
                              value: runtime_models.ProxyMode.mixed,
                              icon: Icon(Icons.lan_outlined),
                              label: Text(l10n.mixed),
                            ),
                            ButtonSegment(
                              value: runtime_models.ProxyMode.tun,
                              icon: Icon(Icons.vpn_lock_outlined),
                              label: Text(l10n.tun),
                            ),
                          ],
                          selected: {core.settings.proxyMode},
                          onSelectionChanged: core.busy
                              ? null
                              : (selected) {
                                  if (selected.isNotEmpty) {
                                    _changeProxyMode(selected.first);
                                  }
                                },
                        ),
                      const SizedBox(height: 16),
                      Text(l10n.routingMode, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SegmentedButton<runtime_models.RouteMode>(
                        expandedInsets: EdgeInsets.zero,
                        segments: [
                          ButtonSegment(
                            value: runtime_models.RouteMode.rule,
                            icon: Icon(Icons.account_tree_outlined),
                            label: Text(l10n.rule),
                          ),
                          ButtonSegment(
                            value: runtime_models.RouteMode.direct,
                            icon: Icon(Icons.flash_on_outlined),
                            label: Text(l10n.direct),
                          ),
                          ButtonSegment(
                            value: runtime_models.RouteMode.all,
                            icon: Icon(Icons.public),
                            label: Text(l10n.all),
                          ),
                        ],
                        selected: {core.settings.routeMode},
                        onSelectionChanged: core.busy
                            ? null
                            : (selected) {
                                if (selected.isNotEmpty) {
                                  _changeRouteMode(selected.first);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: core.busy || !core.available
                              ? null
                              : () => core.running
                                    ? ref.read(coreProvider.notifier).stop()
                                    : _connect(),
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
              ),
              if (core.message.isNotEmpty &&
                  (!core.available ||
                      core.lifecycle == CoreLifecycle.failed)) ...[
                const SizedBox(height: 16),
                ConnectionErrorBanner(message: core.message),
              ],
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
    if (current.proxyMode == mode) return;
    await ref
        .read(coreProvider.notifier)
        .updateRuntimeConfig(current.copyWith(proxyMode: mode));
    if (!mounted) return;
    final core = ref.read(coreProvider);
    if (core.lifecycle == CoreLifecycle.failed) {
      _showMessage(
        AppLocalizations.of(context).connectionErrorMessage,
        error: true,
      );
    }
  }

  Future<void> _changeRouteMode(runtime_models.RouteMode mode) async {
    final current = ref.read(coreProvider).settings;
    if (current.routeMode == mode) return;
    await ref
        .read(coreProvider.notifier)
        .updateRuntimeConfig(current.copyWith(routeMode: mode));
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
