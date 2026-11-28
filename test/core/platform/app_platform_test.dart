import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/platform/platform_settings_policy.dart';
import 'package:target/data/models/app_settings.dart';

void main() {
  const cases = [
    ('android', AppPlatform.android, RuntimeHost.mobileVpn),
    ('ios', AppPlatform.ios, RuntimeHost.mobileVpn),
    ('windows', AppPlatform.windows, RuntimeHost.desktopService),
    ('macos', AppPlatform.macos, RuntimeHost.desktopService),
    ('linux', AppPlatform.linux, RuntimeHost.desktopService),
    ('fuchsia', AppPlatform.unsupported, RuntimeHost.unsupported),
  ];

  for (final (operatingSystem, platform, host) in cases) {
    test('$operatingSystem resolves its runtime and system proxy policy', () {
      final resolved = AppPlatform.fromOperatingSystem(operatingSystem);
      expect(resolved, platform);

      final capabilities = AppCapabilities(resolved);
      final vpnOnly = host == RuntimeHost.mobileVpn;
      final desktop = host == RuntimeHost.desktopService;
      expect(capabilities.runtimeHost, host);
      expect(capabilities.vpnOnly, vpnOnly);
      expect(capabilities.supportsMixedProxy, desktop);
      expect(capabilities.supportsManagedService, desktop);

      const settings = AppSettings(systemProxy: true);
      final normalized = PlatformSettingsPolicy.normalize(
        settings,
        capabilities,
      );
      expect(normalized.systemProxy, !vpnOnly);
    });
  }
}
