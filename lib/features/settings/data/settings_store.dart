import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/app_settings.dart';

abstract class AppSettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// 单键 KV 直存：每个字段独立 key，无 JSON 包装
/// 旧的 settings.json 文件已废弃，不再读写
class SharedPreferencesSettingsStore implements AppSettingsStore {
  SharedPreferencesSettingsStore({this.keyPrefix = 'app_settings.'});

  final String keyPrefix;

  String _k(String name) => '$keyPrefix$name';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    // 若没有任何 key，返回默认值（首次启动）
    // 兼容旧 JSON 文件的读取已移除，按你的要求直接按字段存取
    return AppSettings(
      themeMode: ThemeModeOptionParsing.fromName(
        prefs.getString(_k('themeMode')),
      ),
      systemProxy: prefs.getBool(_k('systemProxy')) ?? true,
      serviceBasePath: (prefs.getString(_k('serviceBasePath')) ?? '').trim(),
      serviceWorkingPath: (prefs.getString(_k('serviceWorkingPath')) ?? '')
          .trim(),
      serviceTempPath: (prefs.getString(_k('serviceTempPath')) ?? '').trim(),
      serviceLocale: (prefs.getString(_k('serviceLocale')) ?? '').trim(),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_k('themeMode'), settings.themeMode.name),
      prefs.setBool(_k('systemProxy'), settings.systemProxy),
      prefs.setString(_k('serviceBasePath'), settings.serviceBasePath),
      prefs.setString(_k('serviceWorkingPath'), settings.serviceWorkingPath),
      prefs.setString(_k('serviceTempPath'), settings.serviceTempPath),
      prefs.setString(_k('serviceLocale'), settings.serviceLocale),
    ]);
  }
}

class MemorySettingsStore implements AppSettingsStore {
  MemorySettingsStore([AppSettings initialSettings = const AppSettings()])
    : _settings = initialSettings;

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
