import 'package:flutter/foundation.dart';

enum ThemeModeOption { system, light, dark }

const defaultDashboardOrder = [
  'status',
  'traffic',
  'outboundMode',
  'networkTakeover',
  'ip',
  'profiles',
  'service',
  'memory',
  'connections',
  'proxyGroups',
];

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
    this.dashboardOrder = defaultDashboardOrder,
    this.dashboardVisible = defaultDashboardOrder,
  });

  final ThemeModeOption themeMode;
  final bool systemProxy;
  final List<String> dashboardOrder;
  final List<String> dashboardVisible;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    bool? systemProxy,
    List<String>? dashboardOrder,
    List<String>? dashboardVisible,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      systemProxy: systemProxy ?? this.systemProxy,
      dashboardOrder: dashboardOrder ?? this.dashboardOrder,
      dashboardVisible: dashboardVisible ?? this.dashboardVisible,
    );
  }
}
