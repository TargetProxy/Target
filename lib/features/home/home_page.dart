import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/runtime/core_notifier.dart';
import '../../core/runtime/core_models.dart';
import '../../core/platform/app_platform.dart';
import 'package:targetlib/targetlib.dart';
import '../../data/models/runtime_settings.dart' as runtime_models;
import '../settings/application/settings_notifier.dart';
import '../../data/models/ip_info.dart';
import '../../core/widgets/target_page_layout.dart';
import '../proxies/application/proxies_notifier.dart';
import 'presentation/widgets/connection_error_banner.dart';
import 'presentation/widgets/current_profile_card.dart';
import 'presentation/widgets/ip_info_card.dart';
import 'presentation/widgets/quick_actions_grid.dart';
import 'presentation/widgets/traffic_stats_card.dart';

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
    final theme = Theme.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TargetPageHeader(
                      title: 'Dashboard',
                      subtitle:
                          'Monitor your local network service and runtime health.',
                    ),
                    const SizedBox(height: 20),
                    if (capabilities.supportsManagedService &&
                        !_serviceChecking &&
                        (_serviceCheckFailed ||
                            _serviceStatus !=
                                TargetLibServiceStatus.running)) ...[
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
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  core.running
                                      ? Icons.check_circle
                                      : Icons.circle,
                                  size: 18,
                                  color: core.running
                                      ? Colors.green
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  core.status,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: core.running
                                        ? Colors.green
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              core.running
                                  ? 'Service is running'
                                  : 'Service is stopped',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              core.available
                                  ? (core.running
                                        ? 'Traffic is being routed through the active profile.'
                                        : 'Start the service to begin routing traffic.')
                                  : 'The local core is unavailable on this platform.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Proxy mode',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            if (capabilities.vpnOnly)
                              const Row(
                                children: [
                                  Icon(Icons.vpn_lock_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('VPN (TUN)'),
                                ],
                              )
                            else
                              SegmentedButton<runtime_models.ProxyMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: runtime_models.ProxyMode.mixed,
                                    icon: Icon(Icons.lan_outlined),
                                    label: Text('Mixed'),
                                  ),
                                  ButtonSegment(
                                    value: runtime_models.ProxyMode.tun,
                                    icon: Icon(Icons.vpn_lock_outlined),
                                    label: Text('TUN'),
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
                            const SizedBox(height: 14),
                            Text(
                              'Routing mode',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<runtime_models.RouteMode>(
                              segments: const [
                                ButtonSegment(
                                  value: runtime_models.RouteMode.rule,
                                  icon: Icon(Icons.account_tree_outlined),
                                  label: Text('Rule'),
                                ),
                                ButtonSegment(
                                  value: runtime_models.RouteMode.direct,
                                  icon: Icon(Icons.flash_on_outlined),
                                  label: Text('Direct'),
                                ),
                                ButtonSegment(
                                  value: runtime_models.RouteMode.all,
                                  icon: Icon(Icons.public),
                                  label: Text('All'),
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
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: core.busy || !core.available
                                  ? null
                                  : () => core.running
                                        ? ref.read(coreProvider.notifier).stop()
                                        : _connect(),
                              child: Text(
                                core.busy
                                    ? 'Working…'
                                    : core.running
                                    ? 'Stop'
                                    : 'Start',
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: wide ? 472 : double.infinity,
                          child: CurrentProfileCard(core: core),
                        ),
                        SizedBox(
                          width: wide ? 472 : double.infinity,
                          child: IpInfoCard(
                            ipInfo: _ipInfo,
                            loading: _ipLoading,
                            error: _ipError,
                            onRefresh: _fetchIpInfo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TrafficStatsCard(
                      snapshot: core.traffic,
                      running: core.running,
                    ),
                    const SizedBox(height: 18),
                    QuickActionsGrid(
                      enabled: core.running && !core.busy,
                      onTestLatency: _testProxies,
                      onRefreshRuleSets: _refreshRuleSets,
                      onCloseConnections: _closeConnections,
                    ),
                  ],
                ),
              ),
            ),
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

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          content: Text(core.message),
          action: SnackBarAction(
            label: 'View logs',
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
    if (mode == runtime_models.ProxyMode.tun) {
      ref
          .read(settingsProvider.notifier)
          .updateSettings((settings) => settings.copyWith(systemProxy: false));
    }
    await ref
        .read(coreProvider.notifier)
        .updateRuntimeConfig(current.copyWith(proxyMode: mode));
    if (!mounted) return;
    final core = ref.read(coreProvider);
    if (core.lifecycle == CoreLifecycle.failed) {
      _showMessage(core.message, error: true);
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
      _showMessage(core.message, error: true);
    }
  }

  Future<void> _testProxies() async {
    final notifier = ref.read(proxiesProvider.notifier);
    await notifier.testAllLatency();
    if (!mounted) return;
    final error = ref.read(proxiesProvider).lastError;
    _showMessage(error ?? 'Proxy URLTest completed.', error: error != null);
  }

  Future<void> _refreshRuleSets() async {
    final count = await ref.read(coreProvider.notifier).refreshRuleSets();
    if (!mounted) return;
    final message = ref.read(coreProvider).message;
    _showMessage(
      count == null
          ? message
          : count == 0
          ? 'No remote rule sets are configured.'
          : 'Requested refresh for $count rule set${count == 1 ? '' : 's'}.',
      error: count == null,
    );
  }

  Future<void> _closeConnections() async {
    final active = ref.read(coreProvider).traffic.activeConnections;
    if (active == 0) {
      _showMessage('There are no active connections.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close all connections?'),
        content: Text(
          '$active active connection${active == 1 ? '' : 's'} will be interrupted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Close all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final count = await ref.read(coreProvider.notifier).closeAllConnections();
    if (!mounted) return;
    final message = ref.read(coreProvider).message;
    _showMessage(
      count == null
          ? message
          : 'Closed $count active connection${count == 1 ? '' : 's'}.',
      error: count == null,
    );
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
                        ? 'Unable to check TargetLib service'
                        : status == TargetLibServiceStatus.stopped
                        ? 'TargetLib service is stopped'
                        : status == TargetLibServiceStatus.notInstalled
                        ? 'TargetLib service is not installed'
                        : 'TargetLib service status is unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              (checkFailed ? error : null) ??
                  (status == TargetLibServiceStatus.stopped
                      ? 'Start the registered service to make TargetLib available.'
                      : 'Install or repair TargetLib using the platform installer, then check again.'),
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
                      ? 'Starting…'
                      : !checkFailed && status == TargetLibServiceStatus.stopped
                      ? 'Start service'
                      : 'Check again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
