import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/target_app.dart';
import 'core/logging/app_logger.dart';
import 'data/storage/app_storage_paths.dart';
import 'data/storage/json_file_store.dart';
import 'features/settings/data/settings_store.dart';

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

      AppLogger.info('Target initialization started');
      final paths = await AppStoragePaths.resolve();
      final settingsStore = SettingsStore(JsonFileStore(paths.settingsFile));
      final settings = await settingsStore.load();

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
