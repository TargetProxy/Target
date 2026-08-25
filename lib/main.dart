import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/desktop_single_instance.dart';
import 'app/target_app.dart';
import 'core/logging/app_logger.dart';
import 'core/platform/app_platform.dart';
import 'core/platform/platform_settings_policy.dart';
import 'features/settings/data/settings_store.dart';

export 'app/target_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Uncaught Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.fatal(
      'Uncaught asynchronous platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  final capabilities = AppCapabilities.current();
  if (capabilities.supportsSingleInstance &&
      !await DesktopSingleInstance.acquire()) {
    exit(0);
  }

  AppLogger.info('Target initialization started');
  final settingsStore = SharedPreferencesSettingsStore();
  final loadedSettings = await settingsStore.load();
  final settings = PlatformSettingsPolicy.normalize(
    loadedSettings,
    capabilities,
  );
  if (!identical(settings, loadedSettings)) {
    await settingsStore.save(settings);
  }

  AppLogger.info('Target initialization completed');
  runApp(
    TargetApp(
      capabilities: capabilities,
      initialSettings: settings,
      settingsStore: settingsStore,
    ),
  );
}
