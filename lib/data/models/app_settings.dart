import 'package:flutter/foundation.dart';

enum ThemeModeOption {
  system,
  light,
  dark;

  String get label => switch (this) {
    ThemeModeOption.system => 'System',
    ThemeModeOption.light => 'Light',
    ThemeModeOption.dark => 'Dark',
  };
}

extension ThemeModeOptionParsing on ThemeModeOption {
  static ThemeModeOption fromName(String? name) {
    for (final value in ThemeModeOption.values) {
      if (value.name == name) {
        return value;
      }
    }
    return ThemeModeOption.system;
  }
}

enum ProxyMode {
  mixed,
  tun;

  String get label => switch (this) {
    ProxyMode.mixed => 'Mixed',
    ProxyMode.tun => 'TUN',
  };
}

extension ProxyModeParsing on ProxyMode {
  static ProxyMode fromName(String? name) {
    for (final value in ProxyMode.values) {
      if (value.name == name) {
        return value;
      }
    }
    return ProxyMode.mixed;
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeModeOption.system,
    this.listenAddress = '127.0.0.1',
    this.mixedPort = 2080,
    this.proxyMode = ProxyMode.mixed,
    this.ipv6 = false,
    this.systemProxy = true,
    this.serviceBasePath = '',
    this.serviceWorkingPath = '',
    this.serviceTempPath = '',
    this.serviceLocale = '',
  });

  final ThemeModeOption themeMode;
  final String listenAddress;
  final int mixedPort;
  final ProxyMode proxyMode;
  final bool ipv6;
  final bool systemProxy;
  final String serviceBasePath;
  final String serviceWorkingPath;
  final String serviceTempPath;
  final String serviceLocale;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    String? listenAddress,
    int? mixedPort,
    ProxyMode? proxyMode,
    bool? ipv6,
    bool? systemProxy,
    String? serviceBasePath,
    String? serviceWorkingPath,
    String? serviceTempPath,
    String? serviceLocale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      listenAddress: listenAddress ?? this.listenAddress,
      mixedPort: mixedPort ?? this.mixedPort,
      proxyMode: proxyMode ?? this.proxyMode,
      ipv6: ipv6 ?? this.ipv6,
      systemProxy: systemProxy ?? this.systemProxy,
      serviceBasePath: serviceBasePath ?? this.serviceBasePath,
      serviceWorkingPath: serviceWorkingPath ?? this.serviceWorkingPath,
      serviceTempPath: serviceTempPath ?? this.serviceTempPath,
      serviceLocale: serviceLocale ?? this.serviceLocale,
    );
  }
}
