import 'package:material_ui/material_ui.dart';

import 'app/app_identity.dart';
import 'app/bootstrap.dart';
import 'core/platform/desktop_tray.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDesktopTray(AppIdentity.displayName);
  runApp(await bootstrap());
}
