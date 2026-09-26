import 'package:flutter_test/flutter_test.dart';
import 'package:target/l10n/app_localizations_en.dart';
import 'package:target/l10n/app_localizations_zh.dart';

void main() {
  test('English map strings apply plural forms', () {
    final l10n = AppLocalizationsEn();

    expect(l10n.countryMarkerNodeCount('SG', 1), 'SG · 1 node');
    expect(l10n.countryMarkerNodeCount('SG', 3), 'SG · 3 nodes');
    expect(l10n.fitMapToNodes, 'Fit map to nodes');
  });

  test('Chinese map strings interpolate counts', () {
    final l10n = AppLocalizationsZh();

    expect(l10n.countryMarkerNodeCount('SG', 3), 'SG · 3 个节点');
    expect(l10n.fitMapToNodes, '适配所有节点');
  });
}
