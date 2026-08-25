import '../../data/models/app_settings.dart';
import 'app_platform.dart';

final class PlatformSettingsPolicy {
  const PlatformSettingsPolicy._();

  static AppSettings normalize(
    AppSettings settings,
    AppCapabilities capabilities,
  ) {
    if (!capabilities.vpnOnly ||
        (settings.proxyMode == ProxyMode.tun && !settings.systemProxy)) {
      return settings;
    }
    return settings.copyWith(proxyMode: ProxyMode.tun, systemProxy: false);
  }
}
