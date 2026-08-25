import 'dart:io';

import 'package:flutter_alone/flutter_alone.dart';

import '../core/logging/app_logger.dart';
import 'app_identity.dart';

class DesktopSingleInstance {
  const DesktopSingleInstance._();

  static const _lockFileName = '${AppIdentity.bundleIdentifier}.lock';

  /// Acquires the application-wide desktop lock. A false result means the
  /// native plugin has activated the existing instance and this process must
  /// exit before initializing application services.
  static Future<bool> acquire() async {
    final canRun = await FlutterAlone.instance.checkAndRun(
      config: _configForCurrentPlatform(),
    );
    if (!canRun) {
      AppLogger.info(
        'Existing Target instance activated; stopping duplicate launch',
        source: 'single-instance',
      );
    }
    return canRun;
  }

  static Future<void> release() async {
    await FlutterAlone.instance.dispose();
  }

  static FlutterAloneConfig _configForCurrentPlatform() {
    const duplicateCheck = DuplicateCheckConfig(enableInDebugMode: true);
    const window = WindowConfig(windowTitle: AppIdentity.displayName);
    const message = CustomMessageConfig(
      customTitle: AppIdentity.displayName,
      customMessage: '${AppIdentity.displayName} is already running.',
    );

    if (Platform.isWindows) {
      return FlutterAloneConfig.forWindows(
        duplicateCheckConfig: duplicateCheck,
        windowsConfig: const DefaultWindowsMutexConfig(
          packageId: AppIdentity.bundleIdentifier,
          appName: AppIdentity.displayName,
        ),
        windowConfig: window,
        messageConfig: message,
      );
    }
    if (Platform.isMacOS) {
      return FlutterAloneConfig.forMacOS(
        duplicateCheckConfig: duplicateCheck,
        macOSConfig: MacOSConfig(lockFileName: _lockFileName),
        windowConfig: window,
        messageConfig: message,
      );
    }
    return FlutterAloneConfig.forLinux(
      duplicateCheckConfig: duplicateCheck,
      linuxConfig: LinuxConfig(lockFileName: _lockFileName),
      windowConfig: window,
      messageConfig: message,
    );
  }
}
