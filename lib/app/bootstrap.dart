import 'package:flutter/foundation.dart';

import '../core/logging/app_logger.dart';
import '../core/platform/app_platform.dart';
import '../core/platform/platform_settings_policy.dart';
import '../features/settings/data/settings_store.dart';
import 'target_app.dart';

Future<TargetApp> bootstrap() async {
  _installErrorHandlers();

  final capabilities = AppCapabilities.current();
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
  return TargetApp(
    capabilities: capabilities,
    initialSettings: settings,
    settingsStore: settingsStore,
  );
}

void _installErrorHandlers() {
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
}
