import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/app_identity.dart';
import 'app/bootstrap.dart';
import 'core/platform/desktop_instance.dart';
import 'core/platform/desktop_tray.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSingleDesktopInstance();
  DesktopTray? desktopTray;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    desktopTray = DesktopTray();
    final locale = PlatformDispatcher.instance.locale;
    await desktopTray.initialize(
      AppIdentity.displayName,
      l10n: lookupAppLocalizations(
        AppLocalizations.supportedLocales.any(
              (supported) => supported.languageCode == locale.languageCode,
            )
            ? locale
            : const Locale('en'),
      ),
    );
  }
  runApp(await bootstrap(desktopTray: desktopTray));
}
