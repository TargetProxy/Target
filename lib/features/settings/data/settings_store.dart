import '../../../data/models/app_settings.dart';
import '../../../data/storage/json_file_store.dart';

abstract class AppSettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SettingsStore implements AppSettingsStore {
  const SettingsStore(this._store);

  static const _schemaVersion = 1;

  final JsonFileStore _store;

  @override
  Future<AppSettings> load() async {
    final Map<String, dynamic>? root;
    try {
      root = await _store.readObject();
    } on Object {
      return const AppSettings();
    }
    if (root == null) {
      return const AppSettings();
    }

    final version = root['schemaVersion'] as int? ?? 1;
    if (version != _schemaVersion) {
      return const AppSettings();
    }

    final settings = root['settings'];
    if (settings is Map<String, dynamic>) {
      return AppSettings.fromJson(settings);
    }
    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) {
    return _store.writeObject({
      'schemaVersion': _schemaVersion,
      'settings': settings.toJson(),
    });
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
