import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/runtime/core_notifier.dart';
import '../../core/runtime/core_models.dart';
import '../../core/runtime/target_lib_service_manager.dart';
import '../../data/models/app_settings.dart' as settings_models;
import '../../data/storage/app_storage_paths.dart';
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
  bool _serviceNeedsInstall = false;
  bool _serviceCheckFailed = false;
  bool _serviceInstalling = false;
  TargetLibServiceStatus? _serviceStatus;
  String? _serviceInstallError;
  final _serviceManager = TargetLibServiceManager();

  @override
  void initState() {
    super.initState();
    _fetchIpInfo();
    _checkTargetLibService();
  }

  Future<void> _checkTargetLibService() async {
    try {
      final settings = ref.read(settingsProvider).settings;
      final paths = await AppStoragePaths.resolve();
      final result = await _serviceManager.run(
        'status',
        basePath: settings.serviceBasePath.isEmpty
            ? paths.coreDirectory.path
            : settings.serviceBasePath,
        // Status is queried without elevation (sc.exe on Windows), so this
        // never triggers a UAC prompt.
        elevated: false,
      );
      if (mounted) {
        setState(() {
          _serviceChecking = false;
          _serviceNeedsInstall =
              result.status == TargetLibServiceStatus.notInstalled;
          _serviceCheckFailed = false;
          _serviceStatus = result.status;
          _serviceInstallError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _serviceChecking = false;
          _serviceNeedsInstall = false;
          _serviceCheckFailed = true;
          _serviceStatus = null;
          _serviceInstallError = error.toString();
        });
      }
    }
  }

  Future<void> _refreshTargetLibService() async {
    TargetLibServiceManager.invalidateStatus();
    await _checkTargetLibService();
  }

  Future<void> _installTargetLibService() async {
    setState(() {
      _serviceInstalling = true;
      _serviceInstallError = null;
    });
    try {
      final settings = ref.read(settingsProvider).settings;
      final paths = await AppStoragePaths.resolve();
      await _serviceManager.installAndStart(
        basePath: settings.serviceBasePath.isEmpty
            ? paths.coreDirectory.path
            : settings.serviceBasePath,
        workingPath: settings.serviceWorkingPath,
        tempPath: settings.serviceTempPath,
        locale: settings.serviceLocale,
      );
      if (mounted) {
        setState(() {
          _serviceChecking = false;
          _serviceNeedsInstall = false;
          _serviceCheckFailed = false;
          _serviceStatus = TargetLibServiceStatus.running;
          _serviceInstallError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _serviceInstallError = error.toString());
    } finally {
      if (mounted) setState(() => _serviceInstalling = false);
    }
  }

  Future<void> _startTargetLibService() async {
    setState(() {
      _serviceInstalling = true;
      _serviceInstallError = null;
    });
    try {
      final settings = ref.read(settingsProvider).settings;
      final paths = await AppStoragePaths.resolve();
      await _serviceManager.run(
        'start',
        basePath: settings.serviceBasePath.isEmpty
            ? paths.coreDirectory.path
            : settings.serviceBasePath,
        workingPath: settings.serviceWorkingPath,
        tempPath: settings.serviceTempPath,
        locale: settings.serviceLocale,
      );
      if (mounted) {
        setState(() {
          _serviceStatus = TargetLibServiceStatus.running;
          _serviceCheckFailed = false;
          _serviceInstallError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _serviceInstallError = error.toString());
    } finally {
      if (mounted) setState(() => _serviceInstalling = false);
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
                    if (!_serviceChecking &&
                        (_serviceNeedsInstall ||
                            _serviceCheckFailed ||
                            _serviceStatus ==
                                TargetLibServiceStatus.stopped)) ...[
                      _ServiceInstallCard(
                        installing: _serviceInstalling,
                        installed:
                            _serviceStatus == TargetLibServiceStatus.stopped,
                        checkFailed: _serviceCheckFailed,
                        error: _serviceInstallError,
                        onAction: _serviceCheckFailed
                            ? _refreshTargetLibService
                            : _serviceStatus == TargetLibServiceStatus.stopped
                            ? _startTargetLibService
                            : _installTargetLibService,
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
                            SegmentedButton<settings_models.ProxyMode>(
                              segments: const [
                                ButtonSegment(
                                  value: settings_models.ProxyMode.mixed,
                                  icon: Icon(Icons.lan_outlined),
                                  label: Text('Mixed'),
                                ),
                                ButtonSegment(
                                  value: settings_models.ProxyMode.tun,
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
                    TrafficStatsCard(snapshot: core.traffic),
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

  Future<void> _changeProxyMode(settings_models.ProxyMode mode) async {
    final current = ref.read(settingsProvider).settings;
    if (current.proxyMode == mode) return;
    final settingsNotifier = ref.read(settingsProvider.notifier);
    settingsNotifier.setProxyMode(mode);
    final next = ref.read(settingsProvider).settings;
    await ref.read(coreProvider.notifier).configure(next);
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

class _ServiceInstallCard extends StatelessWidget {
  const _ServiceInstallCard({
    required this.installing,
    required this.installed,
    required this.checkFailed,
    required this.error,
    required this.onAction,
  });

  final bool installing;
  final bool installed;
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
                        ? 'Unable to check Libbox service'
                        : installed
                        ? 'Libbox service is stopped'
                        : 'Install the Libbox service',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              (checkFailed ? error : null) ??
                  (installed
                      ? 'Start the registered service to make targetlib available.'
                      : 'Administrator permission is required to register targetlib with the operating system.'),
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: installing ? null : onAction,
                icon: installing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        checkFailed
                            ? Icons.refresh
                            : installed
                            ? Icons.play_arrow
                            : Icons.download,
                      ),
                label: Text(
                  installing
                      ? (installed ? 'Starting…' : 'Installing…')
                      : checkFailed
                      ? 'Retry'
                      : (installed ? 'Start service' : 'Install'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
