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
    ProxyMode.mixed => 'System proxy',
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
    this.startOnBoot = false,
    this.enableNotifications = true,
    this.listenAddress = '127.0.0.1',
    this.mixedPort = 2080,
    this.proxyMode = ProxyMode.mixed,
    this.ipv6 = false,
    this.systemProxy = true,
    this.perAppProxy = false,
    this.serviceBasePath = '',
    this.serviceWorkingPath = '',
    this.serviceTempPath = '',
    this.serviceLocale = '',
  });

  final ThemeModeOption themeMode;
  final bool startOnBoot;
  final bool enableNotifications;
  final String listenAddress;
  final int mixedPort;
  final ProxyMode proxyMode;
  final bool ipv6;
  final bool systemProxy;
  final bool perAppProxy;
  final String serviceBasePath;
  final String serviceWorkingPath;
  final String serviceTempPath;
  final String serviceLocale;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    bool? startOnBoot,
    bool? enableNotifications,
    String? listenAddress,
    int? mixedPort,
    ProxyMode? proxyMode,
    bool? ipv6,
    bool? systemProxy,
    bool? perAppProxy,
    String? serviceBasePath,
    String? serviceWorkingPath,
    String? serviceTempPath,
    String? serviceLocale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      startOnBoot: startOnBoot ?? this.startOnBoot,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      listenAddress: listenAddress ?? this.listenAddress,
      mixedPort: mixedPort ?? this.mixedPort,
      proxyMode: proxyMode ?? this.proxyMode,
      ipv6: ipv6 ?? this.ipv6,
      systemProxy: systemProxy ?? this.systemProxy,
      perAppProxy: perAppProxy ?? this.perAppProxy,
      serviceBasePath: serviceBasePath ?? this.serviceBasePath,
      serviceWorkingPath: serviceWorkingPath ?? this.serviceWorkingPath,
      serviceTempPath: serviceTempPath ?? this.serviceTempPath,
      serviceLocale: serviceLocale ?? this.serviceLocale,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'startOnBoot': startOnBoot,
    'enableNotifications': enableNotifications,
    'listenAddress': listenAddress,
    'mixedPort': mixedPort,
    'proxyMode': proxyMode.name,
    'ipv6': ipv6,
    'systemProxy': systemProxy,
    'perAppProxy': perAppProxy,
    'serviceBasePath': serviceBasePath,
    'serviceWorkingPath': serviceWorkingPath,
    'serviceTempPath': serviceTempPath,
    'serviceLocale': serviceLocale,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final listenAddress = json['listenAddress'] as String?;
    final mixedPort = json['mixedPort'] as int?;

    return AppSettings(
      themeMode: ThemeModeOptionParsing.fromName(json['themeMode'] as String?),
      startOnBoot: json['startOnBoot'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      listenAddress: listenAddress == null || listenAddress.trim().isEmpty
          ? '127.0.0.1'
          : listenAddress.trim(),
      mixedPort: mixedPort == null || mixedPort <= 0 || mixedPort >= 65536
          ? 2080
          : mixedPort,
      proxyMode: ProxyModeParsing.fromName(json['proxyMode'] as String?),
      ipv6: json['ipv6'] as bool? ?? false,
      systemProxy: json['systemProxy'] as bool? ?? true,
      perAppProxy: json['perAppProxy'] as bool? ?? false,
      serviceBasePath: (json['serviceBasePath'] as String? ?? '').trim(),
      serviceWorkingPath: (json['serviceWorkingPath'] as String? ?? '').trim(),
      serviceTempPath: (json['serviceTempPath'] as String? ?? '').trim(),
      serviceLocale: (json['serviceLocale'] as String? ?? '').trim(),
    );
  }
}
