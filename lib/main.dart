import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/desktop_single_instance.dart';
import 'app/target_app.dart';
import 'core/logging/app_logger.dart';
import 'features/settings/data/settings_store.dart';
import 'data/models/app_settings.dart';

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

  if (!await DesktopSingleInstance.acquire()) {
    exit(0);
  }

  AppLogger.info('Target initialization started');
  final settingsStore = SharedPreferencesSettingsStore();
  var settings = await settingsStore.load();
  if (Platform.isAndroid && settings.proxyMode != ProxyMode.tun) {
    settings = settings.copyWith(
      proxyMode: ProxyMode.tun,
      systemProxy: false,
    );
    await settingsStore.save(settings);
  }

  AppLogger.info('Target initialization completed');
  runApp(
    TargetApp(initialSettings: settings, settingsStore: settingsStore),
  );
}
