import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/platform/app_platform.dart';

void main() {
  group('AppCapabilities', () {
    for (final platform in [AppPlatform.android, AppPlatform.ios]) {
      test('$platform exposes only the mobile VPN runtime', () {
        final capabilities = AppCapabilities(platform);

        expect(capabilities.runtimeHost, RuntimeHost.mobileVpn);
        expect(capabilities.vpnOnly, isTrue);
        expect(capabilities.supportsMixedProxy, isFalse);
        expect(capabilities.supportsManagedService, isFalse);
        expect(capabilities.supportsTray, isFalse);
        expect(capabilities.supportsSingleInstance, isFalse);
      });
    }

    for (final platform in [
      AppPlatform.windows,
      AppPlatform.macos,
      AppPlatform.linux,
    ]) {
      test('$platform exposes the desktop runtime', () {
        final capabilities = AppCapabilities(platform);

        expect(capabilities.runtimeHost, RuntimeHost.desktopService);
        expect(capabilities.vpnOnly, isFalse);
        expect(capabilities.supportsMixedProxy, isTrue);
        expect(capabilities.supportsManagedService, isTrue);
        expect(capabilities.supportsTray, isTrue);
        expect(capabilities.supportsSingleInstance, isTrue);
      });
    }
  });

  test('maps Dart operating-system names', () {
    expect(AppPlatform.fromOperatingSystem('android'), AppPlatform.android);
    expect(AppPlatform.fromOperatingSystem('ios'), AppPlatform.ios);
    expect(AppPlatform.fromOperatingSystem('windows'), AppPlatform.windows);
    expect(AppPlatform.fromOperatingSystem('macos'), AppPlatform.macos);
    expect(AppPlatform.fromOperatingSystem('linux'), AppPlatform.linux);
    expect(AppPlatform.fromOperatingSystem('fuchsia'), AppPlatform.unsupported);
  });
}
