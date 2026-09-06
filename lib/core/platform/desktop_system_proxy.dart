import 'package:proxy_manager/proxy_manager.dart';

abstract interface class SystemProxyBackend {
  Future<void> set(ProxyTypes type, String host, int port);

  Future<void> clean();
}

final class ProxyManagerBackend implements SystemProxyBackend {
  ProxyManagerBackend([ProxyManager? manager])
    : _manager = manager ?? ProxyManager();

  final ProxyManager _manager;

  @override
  Future<void> set(ProxyTypes type, String host, int port) =>
      _manager.setAsSystemProxy(type, host, port);

  @override
  Future<void> clean() => _manager.cleanSystemProxy();
}

/// Keeps OS proxy mutations serialized and only clears settings it applied.
final class DesktopSystemProxy {
  DesktopSystemProxy({SystemProxyBackend? backend})
    : _backend = backend ?? ProxyManagerBackend();

  final SystemProxyBackend _backend;

  bool _desiredEnabled = false;
  String _desiredHost = '';
  int _desiredPort = 0;
  bool _ownsProxy = false;
  String _appliedHost = '';
  int _appliedPort = 0;
  int _revision = 0;
  Future<void>? _syncTask;

  Future<void> synchronize({
    required bool enabled,
    required String host,
    required int port,
  }) async {
    _desiredEnabled = enabled;
    _desiredHost = host;
    _desiredPort = port;
    _revision++;

    final activeTask = _syncTask;
    if (activeTask != null) {
      await activeTask;
      return;
    }

    final task = _drain();
    _syncTask = task;
    try {
      await task;
    } finally {
      if (identical(_syncTask, task)) {
        _syncTask = null;
      }
    }
  }

  Future<void> _drain() async {
    while (true) {
      final revision = _revision;
      final enabled = _desiredEnabled;
      final host = _desiredHost;
      final port = _desiredPort;

      if (enabled) {
        if (!_ownsProxy || _appliedHost != host || _appliedPort != port) {
          await _backend.set(ProxyTypes.http, host, port);
          _ownsProxy = true;
          await _backend.set(ProxyTypes.https, host, port);
          _appliedHost = host;
          _appliedPort = port;
        }
      } else if (_ownsProxy) {
        await _backend.clean();
        _ownsProxy = false;
        _appliedHost = '';
        _appliedPort = 0;
      }

      if (revision == _revision) return;
    }
  }

  Future<void> dispose() => synchronize(enabled: false, host: '', port: 0);
}
