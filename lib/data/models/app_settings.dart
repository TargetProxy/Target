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

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeModeOption.system,
    this.systemProxy = true,
    this.serviceBasePath = '',
    this.serviceWorkingPath = '',
    this.serviceTempPath = '',
    this.serviceLocale = '',
  });

  final ThemeModeOption themeMode;
  final bool systemProxy;
  final String serviceBasePath;
  final String serviceWorkingPath;
  final String serviceTempPath;
  final String serviceLocale;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    bool? systemProxy,
    String? serviceBasePath,
    String? serviceWorkingPath,
    String? serviceTempPath,
    String? serviceLocale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      systemProxy: systemProxy ?? this.systemProxy,
      serviceBasePath: serviceBasePath ?? this.serviceBasePath,
      serviceWorkingPath: serviceWorkingPath ?? this.serviceWorkingPath,
      serviceTempPath: serviceTempPath ?? this.serviceTempPath,
      serviceLocale: serviceLocale ?? this.serviceLocale,
    );
  }
}
