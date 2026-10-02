import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import '../core/theme/app_theme.dart';
import '../core/platform/app_platform.dart';
import '../core/platform/desktop_system_proxy.dart';
import '../core/runtime/core_gateway.dart';
import '../core/runtime/core_notifier.dart';
import '../data/models/app_settings.dart';
import '../data/models/runtime_settings.dart';
import '../features/settings/application/settings_notifier.dart';
import '../features/settings/data/settings_store.dart';
import '../features/subscriptions/application/subscriptions_notifier.dart';
import 'app_identity.dart';
import 'desktop_single_instance.dart';
import 'desktop_tray_controller.dart';
import 'router.dart';
import '../l10n/app_localizations.dart';

class TargetApp extends StatelessWidget {
  const TargetApp({
    super.key,
    this.capabilities,
    this.coreGateway,
    this.initialSettings,
    this.settingsStore,
    this.systemProxy,
  });

  final CoreGateway? coreGateway;
  final AppCapabilities? capabilities;
  final AppSettings? initialSettings;
  final AppSettingsStore? settingsStore;
  final DesktopSystemProxy? systemProxy;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (capabilities != null)
          appCapabilitiesProvider.overrideWithValue(capabilities!),
        if (coreGateway != null)
          coreGatewayProvider.overrideWithValue(coreGateway!),
        if (initialSettings != null)
          initialSettingsProvider.overrideWithValue(initialSettings!),
        if (settingsStore != null)
          settingsStoreProvider.overrideWithValue(settingsStore!),
      ],
      child: _TargetAppView(systemProxy: systemProxy),
    );
  }
}

class _TargetAppView extends ConsumerStatefulWidget {
  const _TargetAppView({this.systemProxy});

  final DesktopSystemProxy? systemProxy;

  @override
  ConsumerState<_TargetAppView> createState() => _TargetAppViewState();
}

class _TargetAppViewState extends ConsumerState<_TargetAppView> {
  late final AppRouter _appRouter = AppRouter();
  late final DesktopSystemProxy _systemProxy =
      widget.systemProxy ?? DesktopSystemProxy();
  DesktopTrayController? _trayController;

  @override
  void initState() {
    super.initState();
    ref.read(subscriptionsProvider.notifier).load();
    if (ref.read(appCapabilitiesProvider).supportsTray) {
      final controller = DesktopTrayController(
        onToggleConnection: _toggleConnection,
        onExit: _prepareExit,
      );
      _trayController = controller;
      unawaited(controller.initialize(ref.read(coreProvider)));
    }
  }

  @override
  void dispose() {
    _trayController?.dispose();
    unawaited(_systemProxy.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).settings;
    ref.listen<CoreState>(coreProvider, (_, next) {
      final controller = _trayController;
      if (controller != null) {
        unawaited(controller.updateCoreState(next));
      }
      unawaited(_synchronizeSystemProxy(core: next));
    });
    ref.listen<SettingsState>(settingsProvider, (_, next) {
      unawaited(
        _synchronizeSystemProxy(
          core: ref.read(coreProvider),
          settings: next.settings,
        ),
      );
    });

    return MaterialApp.router(
      title: AppIdentity.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeModeFor(settings.themeMode),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
      routerConfig: _appRouter.router,
    );
  }

  ThemeMode _themeModeFor(ThemeModeOption mode) {
    return switch (mode) {
      ThemeModeOption.system => ThemeMode.system,
      ThemeModeOption.light => ThemeMode.light,
      ThemeModeOption.dark => ThemeMode.dark,
    };
  }

  Future<void> _toggleConnection() async {
    final notifier = ref.read(coreProvider.notifier);
    if (ref.read(coreProvider).running) {
      await notifier.stop();
    } else {
      await notifier.start();
    }
  }

  Future<void> _stopCore() async {
    final core = ref.read(coreProvider);
    if (core.running || core.busy) {
      await ref.read(coreProvider.notifier).stop();
    }
  }

  Future<void> _prepareExit() async {
    try {
      await _stopCore();
      await _systemProxy.synchronize(enabled: false, host: '', port: 0);
    } finally {
      await DesktopSingleInstance.release();
    }
  }

  Future<void> _synchronizeSystemProxy({
    required CoreState core,
    AppSettings? settings,
  }) async {
    final capabilities = ref.read(appCapabilitiesProvider);
    final appSettings = settings ?? ref.read(settingsProvider).settings;
    final enabled =
        capabilities.supportsMixedProxy &&
        core.running &&
        core.settings.proxyMode == ProxyMode.mixed &&
        appSettings.systemProxy;
    try {
      await _systemProxy.synchronize(
        enabled: enabled,
        host: core.settings.listenAddress,
        port: core.settings.mixedPort,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        enabled
            ? 'Failed to enable the system proxy'
            : 'Failed to disable the system proxy',
        source: 'system-proxy',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
