import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

// Keep the native tray handle alive for the lifetime of the app.
final _trayIcon = TrayIcon.create()!;

void initializeDesktopTray(String tooltip) {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    _trayIcon
      ..icon = ImageAsset.fromAsset('assets/TargetAppIcon.png')
      ..setTooltip(tooltip)
      ..setVisible(true);
  }
}
