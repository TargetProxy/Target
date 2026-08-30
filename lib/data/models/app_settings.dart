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
  });

  final ThemeModeOption themeMode;
  final bool systemProxy;

  AppSettings copyWith({ThemeModeOption? themeMode, bool? systemProxy}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      systemProxy: systemProxy ?? this.systemProxy,
    );
  }
}
