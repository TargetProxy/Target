import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import '../core/ui/prism_theme.dart';
import '../core/ui/ui_localizations.dart';

import '../core/logging/app_logger.dart';
import '../core/platform/app_platform.dart';
import '../core/platform/desktop_system_proxy.dart';
import '../core/platform/desktop_tray.dart';
import '../core/runtime/core_gateway.dart';
import '../core/runtime/core_notifier.dart';
import '../data/models/app_settings.dart';
import '../data/models/runtime_settings.dart';
import '../features/settings/application/settings_notifier.dart';
import '../features/settings/data/settings_store.dart';
import '../features/subscriptions/application/subscriptions_notifier.dart';
import 'app_identity.dart';
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
    this.desktopTray,
  });

  final CoreGateway? coreGateway;
  final AppCapabilities? capabilities;
  final AppSettings? initialSettings;
  final AppSettingsStore? settingsStore;
  final DesktopSystemProxy? systemProxy;
  final DesktopTray? desktopTray;

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
      child: _TargetAppView(systemProxy: systemProxy, desktopTray: desktopTray),
    );
  }
}

class _TargetAppView extends ConsumerStatefulWidget {
  const _TargetAppView({this.systemProxy, this.desktopTray});

  final DesktopSystemProxy? systemProxy;
  final DesktopTray? desktopTray;

  @override
  ConsumerState<_TargetAppView> createState() => _TargetAppViewState();
}

class _TargetAppViewState extends ConsumerState<_TargetAppView> {
  late final AppRouter _appRouter = AppRouter();
  late final DesktopSystemProxy _systemProxy =
      widget.systemProxy ?? DesktopSystemProxy();
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    widget.desktopTray?.onExit = _quit;
    ref.read(subscriptionsProvider.notifier).load();
  }

  @override
  void dispose() {
    widget.desktopTray?.onExit = null;
    unawaited(_systemProxy.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).settings;
    ref.listen<CoreState>(coreProvider, (_, next) {
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

    return WidgetsApp.router(
      title: AppIdentity.displayName,
      debugShowCheckedModeBanner: false,
      color: PrismTheme.light.colorScheme.primary,
      localizationsDelegates: targetLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
      builder: (context, child) => prism.PrismApp(
        title: AppIdentity.displayName,
        debugShowCheckedModeBanner: false,
        theme: PrismTheme.light,
        darkTheme: PrismTheme.dark,
        liquidGlass: prism.LiquidGlassQuality.standard,
        themeMode: _themeModeFor(settings.themeMode),
        locale: Localizations.localeOf(context),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: targetLocalizationsDelegates,
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          return prism.ViewScope(
            size: size,
            isMobile: size.width <= 600,
            child: child!,
          );
        },
      ),
      routerConfig: _appRouter.router,
    );
  }

  prism.ThemeMode _themeModeFor(ThemeModeOption mode) {
    return switch (mode) {
      ThemeModeOption.system => prism.ThemeMode.system,
      ThemeModeOption.light => prism.ThemeMode.light,
      ThemeModeOption.dark => prism.ThemeMode.dark,
    };
  }

  Future<void> _synchronizeSystemProxy({
    required CoreState core,
    AppSettings? settings,
  }) async {
    if (_exiting) return;
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

  Future<void> _quit() async {
    if (_exiting) return;
    _exiting = true;
    try {
      await ref.read(coreGatewayProvider).dispose();
      await _systemProxy.dispose();
      await widget.desktopTray!.quit();
    } on Object catch (error, stackTrace) {
      _exiting = false;
      AppLogger.error(
        'Failed to quit Target',
        source: 'desktop',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
