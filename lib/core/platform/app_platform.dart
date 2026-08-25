import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPlatform {
  android,
  ios,
  windows,
  macos,
  linux,
  unsupported;

  static AppPlatform fromOperatingSystem(String operatingSystem) =>
      switch (operatingSystem) {
        'android' => AppPlatform.android,
        'ios' => AppPlatform.ios,
        'windows' => AppPlatform.windows,
        'macos' => AppPlatform.macos,
        'linux' => AppPlatform.linux,
        _ => AppPlatform.unsupported,
      };

  static AppPlatform get current =>
      fromOperatingSystem(Platform.operatingSystem);
}

enum RuntimeHost { mobileVpn, desktopService, unsupported }

final class AppCapabilities {
  const AppCapabilities(this.platform);

  factory AppCapabilities.current() => AppCapabilities(AppPlatform.current);

  final AppPlatform platform;

  RuntimeHost get runtimeHost => switch (platform) {
    AppPlatform.android || AppPlatform.ios => RuntimeHost.mobileVpn,
    AppPlatform.windows ||
    AppPlatform.macos ||
    AppPlatform.linux => RuntimeHost.desktopService,
    AppPlatform.unsupported => RuntimeHost.unsupported,
  };

  bool get vpnOnly => runtimeHost == RuntimeHost.mobileVpn;
  bool get supportsMixedProxy => runtimeHost == RuntimeHost.desktopService;
  bool get supportsManagedService => runtimeHost == RuntimeHost.desktopService;
  bool get supportsTray => runtimeHost == RuntimeHost.desktopService;
  bool get supportsSingleInstance => runtimeHost == RuntimeHost.desktopService;
}

final appCapabilitiesProvider = Provider<AppCapabilities>(
  (ref) => AppCapabilities.current(),
);
