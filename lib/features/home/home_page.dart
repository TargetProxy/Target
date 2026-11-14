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
import 'package:prism_ui/prism_ui.dart' as prism;
import '../../core/ui/scaffold/scaffold.dart' as ui;
import 'presentation/dashboard/dashboard.dart';
import '../../l10n/app_localizations.dart';
import '../settings/application/settings_notifier.dart';
import 'presentation/widgets/connection_error_banner.dart';

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
    return ui.Scaffold(
      title: l10n.dashboard,
      body: Builder(
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            prism.BuildContextExtension(context).contentTopPadding,
            20,
            24 + prism.BuildContextExtension(context).bottomInset,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  if (capabilities.supportsManagedService &&
                      !_serviceChecking &&
                      (_serviceCheckFailed ||
                          _serviceStatus != TargetLibServiceStatus.running))
                    _ServiceStatusCard(
                      starting: _serviceStarting,
                      status: _serviceStatus,
                      checkFailed: _serviceCheckFailed,
                      error: _serviceError,
                      onAction: !_serviceCheckFailed &&
                              _serviceStatus == TargetLibServiceStatus.stopped
                          ? _startTargetLibService
                          : _checkTargetLibService,
                    ),
                  TargetDashboard(
                    core: core,
                    capabilities: capabilities,
                    appSettings: appSettings,
                    onProxyModeChanged: _changeProxyMode,
                    onRouteModeChanged: _changeRouteMode,
                    onSystemProxyChanged: (value) => ref
                        .read(settingsProvider.notifier)
                        .updateSettings((settings) => settings.copyWith(systemProxy: value)),
                    onServiceAction: () => core.running
                        ? ref.read(coreProvider.notifier).stop()
                        : _connect(),
                    ipInfo: _ipInfo,
                    ipLoading: _ipLoading,
                    ipError: _ipError,
                    onRefreshIp: _fetchIpInfo,
                  ),
                  if (core.message.isNotEmpty &&
                      (!core.available || core.lifecycle == CoreLifecycle.failed))
                    ConnectionErrorBanner(message: core.message),
                ],
              ),
            ),
          ),
        ),
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
