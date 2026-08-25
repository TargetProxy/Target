import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/platform/platform_settings_policy.dart';
import 'package:target/data/models/app_settings.dart';

void main() {
  const mixedSettings = AppSettings(
    proxyMode: ProxyMode.mixed,
    systemProxy: true,
  );

  for (final platform in [AppPlatform.android, AppPlatform.ios]) {
    test('$platform is normalized to VPN-only settings', () {
      final normalized = PlatformSettingsPolicy.normalize(
        mixedSettings,
        AppCapabilities(platform),
      );

      expect(normalized.proxyMode, ProxyMode.tun);
      expect(normalized.systemProxy, isFalse);
    });
  }

  test('desktop settings remain selectable', () {
    final normalized = PlatformSettingsPolicy.normalize(
      mixedSettings,
      const AppCapabilities(AppPlatform.windows),
    );

    expect(identical(normalized, mixedSettings), isTrue);
  });
}
