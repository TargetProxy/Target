import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app/app_identity.dart';
import 'app/bootstrap.dart';
import 'core/platform/desktop_instance.dart';
import 'core/platform/desktop_tray.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSingleDesktopInstance();
  DesktopTray? desktopTray;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    desktopTray = DesktopTray();
    await desktopTray.initialize(
      AppIdentity.displayName,
      chinese: PlatformDispatcher.instance.locale.languageCode == 'zh',
    );
  }
  runApp(await bootstrap(desktopTray: desktopTray));
}
