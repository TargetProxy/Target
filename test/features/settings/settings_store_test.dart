import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/features/settings/data/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dashboard order and visibility persist', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesSettingsStore();
    const settings = AppSettings(
      dashboardOrder: [
        'traffic',
        'status',
        'ip',
        'outboundMode',
        'networkTakeover',
        'connections',
      ],
      dashboardVisible: ['traffic', 'status', 'connections'],
    );

    await store.save(settings);
    final restored = await store.load();

    expect(restored.dashboardOrder, settings.dashboardOrder);
    expect(restored.dashboardVisible, settings.dashboardVisible);
  });
}
