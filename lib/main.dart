import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/desktop_single_instance.dart';
import 'app/target_app.dart';
import 'core/logging/app_logger.dart';
import 'data/storage/app_storage_paths.dart';
import 'data/storage/json_file_store.dart';
import 'features/settings/data/settings_store.dart';
import 'data/models/app_settings.dart';

export 'app/target_app.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      // Binding initialization and runApp must happen in the same zone.
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
      final paths = await AppStoragePaths.resolve();
      final settingsStore = SettingsStore(JsonFileStore(paths.settingsFile));
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
    },
    (error, stackTrace) {
      AppLogger.fatal(
        'Uncaught error in application zone',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
