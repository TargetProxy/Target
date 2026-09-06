import 'package:flutter_test/flutter_test.dart';
import 'package:proxy_manager/proxy_manager.dart';
import 'package:target/core/platform/desktop_system_proxy.dart';

void main() {
  test('sets HTTP and HTTPS and cleans when disabled', () async {
    final backend = _FakeSystemProxyBackend();
    final proxy = DesktopSystemProxy(backend: backend);

    await proxy.synchronize(enabled: true, host: '127.0.0.1', port: 2080);
    await proxy.synchronize(enabled: false, host: '127.0.0.1', port: 2080);

    expect(backend.operations, [
      'set:http:127.0.0.1:2080',
      'set:https:127.0.0.1:2080',
      'clean',
    ]);
  });

  test('does not clean a proxy it did not apply', () async {
    final backend = _FakeSystemProxyBackend();
    final proxy = DesktopSystemProxy(backend: backend);

    await proxy.synchronize(enabled: false, host: '127.0.0.1', port: 2080);

    expect(backend.operations, isEmpty);
  });

  test('reapplies the proxy when its endpoint changes', () async {
    final backend = _FakeSystemProxyBackend();
    final proxy = DesktopSystemProxy(backend: backend);

    await proxy.synchronize(enabled: true, host: '127.0.0.1', port: 2080);
    await proxy.synchronize(enabled: true, host: '127.0.0.1', port: 2081);

    expect(backend.operations, [
      'set:http:127.0.0.1:2080',
      'set:https:127.0.0.1:2080',
      'set:http:127.0.0.1:2081',
      'set:https:127.0.0.1:2081',
    ]);
  });
}

final class _FakeSystemProxyBackend implements SystemProxyBackend {
  final List<String> operations = [];

  @override
  Future<void> clean() async {
    operations.add('clean');
  }

  @override
  Future<void> set(ProxyTypes type, String host, int port) async {
    operations.add('set:${type.name}:$host:$port');
  }
}
