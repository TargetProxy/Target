import 'dart:io';

import 'package:flutter_alone/flutter_alone.dart';

import '../../app/app_identity.dart';

Future<void> ensureSingleDesktopInstance() async {
  const message = EnMessageConfig(showMessageBox: false);
  const window = WindowConfig(windowTitle: AppIdentity.displayName);
  const duplicateCheck = DuplicateCheckConfig(enableInDebugMode: true);
  const lockFile = '${AppIdentity.bundleIdentifier}.lock';
  final config = switch (Platform.operatingSystem) {
    'windows' => FlutterAloneConfig.forWindows(
      windowsConfig: const DefaultWindowsMutexConfig(
        packageId: AppIdentity.bundleIdentifier,
        appName: AppIdentity.displayName,
      ),
      messageConfig: message,
      windowConfig: window,
      duplicateCheckConfig: duplicateCheck,
    ),
    'macos' => FlutterAloneConfig.forMacOS(
      macOSConfig: MacOSConfig(lockFileName: lockFile),
      messageConfig: message,
      windowConfig: window,
      duplicateCheckConfig: duplicateCheck,
    ),
    'linux' => FlutterAloneConfig.forLinux(
      linuxConfig: LinuxConfig(lockFileName: lockFile),
      messageConfig: message,
      windowConfig: window,
      duplicateCheckConfig: duplicateCheck,
    ),
    _ => null,
  };
  if (config != null &&
      !await FlutterAlone.instance.checkAndRun(config: config)) {
    exit(0);
  }
}
