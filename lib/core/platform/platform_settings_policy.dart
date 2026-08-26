import '../../data/models/app_settings.dart';
import 'app_platform.dart';

final class PlatformSettingsPolicy {
  const PlatformSettingsPolicy._();

  static AppSettings normalize(
    AppSettings settings,
    AppCapabilities capabilities,
  ) {
    if (!capabilities.vpnOnly || !settings.systemProxy) {
      return settings;
    }
    return settings.copyWith(systemProxy: false);
  }
}
