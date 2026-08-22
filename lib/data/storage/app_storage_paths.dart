import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/app_identity.dart';
import '../../core/logging/app_logger.dart';

class AppStoragePaths {
  const AppStoragePaths._(this.root);

  final Directory root;

  File get settingsFile =>
      File('${root.path}${Platform.pathSeparator}settings.json');

  Directory get coreDirectory =>
      Directory('${root.path}${Platform.pathSeparator}core');

  /// Persistent cache file for sing-box / libbox cache_file experimental.
  File get cacheFile =>
      File('${coreDirectory.path}${Platform.pathSeparator}cache.db');

  static Future<AppStoragePaths> resolve() async {
    final root = await _resolveRootDirectory();
    final paths = AppStoragePaths._(root);
    await paths.ensureCreated();
    return paths;
  }

  static Future<AppStoragePaths> fromRoot(Directory root) async {
    final paths = AppStoragePaths._(root);
    await paths.ensureCreated();
    return paths;
  }

  Future<void> ensureCreated() async {
    await root.create(recursive: true);
    await coreDirectory.create(recursive: true);
  }

  /// Resolves the canonical root using `path_provider` as primary source.
  /// Falls back to the manual XDG / APPDATA heuristic when the plugin is
  /// unavailable (e.g. unit tests or unsupported platform).
  static Future<Directory> _resolveRootDirectory() async {
    try {
      final providerDir = await getApplicationSupportDirectory();
      final path = providerDir.path.trim();
      if (path.isNotEmpty) {
        // `path_provider` already returns an app-scoped directory:
        // - Windows: %APPDATA%/top.loafman.target
        // - macOS: ~/Library/Application Support/top.loafman.target
        // - Linux: $XDG_DATA_HOME/top.loafman.target or ~/.local/share
        // Use it directly to honour platform conventions.
        AppLogger.info(
          'AppStoragePaths using provider directory: $path',
          source: 'storage',
        );
        return Directory(path);
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'path_provider unavailable, using manual fallback',
        source: 'storage',
        error: error,
        stackTrace: stackTrace,
      );
    }
    final manual = _manualRootPath();
    AppLogger.info(
      'AppStoragePaths using manual fallback: $manual',
      source: 'storage',
    );
    return Directory(manual);
  }

  static String _manualRootPath() => _defaultRootPath();

  static String _defaultRootPath() {
    final separator = Platform.pathSeparator;
    if (Platform.isWindows) {
      final roaming = Platform.environment['APPDATA'];
      if (roaming != null && roaming.trim().isNotEmpty) {
        return '$roaming$separator${AppIdentity.storageDirectoryName}';
      }
    }
    if (Platform.isMacOS) {
      final home = _homeDirectoryPath();
      if (home != null) {
        return '$home${separator}Library${separator}Application Support'
            '$separator${AppIdentity.storageDirectoryName}';
      }
    }
    if (Platform.isLinux) {
      final dataHome = Platform.environment['XDG_DATA_HOME'];
      if (dataHome != null && dataHome.trim().isNotEmpty) {
        return '$dataHome$separator${AppIdentity.storageDirectoryName}';
      }
      final home = _homeDirectoryPath();
      if (home != null) {
        return '$home$separator.local${separator}share'
            '$separator${AppIdentity.storageDirectoryName}';
      }
    }

    final base = _applicationSupportDirectoryFallback();
    return '${base.path}$separator${AppIdentity.storageDirectoryName}';
  }

  static Directory _applicationSupportDirectoryFallback() {
    try {
      final home = _homeDirectoryPath() ?? Directory.current.path;
      return Directory('$home${Platform.pathSeparator}.target');
    } catch (_) {
      return Directory.current;
    }
  }

  static String? _homeDirectoryPath() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.trim().isEmpty) {
      return null;
    }
    return home;
  }

  /// Helper for callers that need a temporary directory via path_provider.
  static Future<Directory> resolveTempDirectory() async {
    try {
      final temp = await getTemporaryDirectory();
      if (temp.path.trim().isNotEmpty) return temp;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'getTemporaryDirectory failed, using systemTemp',
        source: 'storage',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return Directory.systemTemp;
  }

  /// Helper for libbox working/cache locations that prefer the support dir.
  static Future<Directory> resolveCacheDirectory() async {
    try {
      final cache = await getApplicationCacheDirectory();
      if (cache.path.trim().isNotEmpty) return cache;
    } on Object catch (_) {
      // Not critical; fall back to support
    }
    return (await resolve()).coreDirectory;
  }
}
