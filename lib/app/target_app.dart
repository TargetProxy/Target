import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/platform/app_platform.dart';
import '../core/runtime/core_gateway.dart';
import '../core/runtime/core_notifier.dart';
import '../data/models/app_settings.dart';
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
  });

  final CoreGateway? coreGateway;
  final AppCapabilities? capabilities;
  final AppSettings? initialSettings;
  final AppSettingsStore? settingsStore;

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
      child: const _TargetAppView(),
    );
  }
}

class _TargetAppView extends ConsumerStatefulWidget {
  const _TargetAppView();

  @override
  ConsumerState<_TargetAppView> createState() => _TargetAppViewState();
}

class _TargetAppViewState extends ConsumerState<_TargetAppView> {
  late final AppRouter _appRouter = AppRouter();
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
    } finally {
      await DesktopSingleInstance.release();
    }
  }
}
