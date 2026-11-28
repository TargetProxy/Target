import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart';
import 'package:target/core/ui/chip_title.dart';
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final (language, count, label) in [
    ('en', 1, 'SG · 1 node'),
    ('en', 3, 'SG · 3 nodes'),
    ('zh', 3, 'SG · 3 个节点'),
  ]) {
    test('$language formats a map marker with $count nodes', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      expect(l10n.countryMarkerNodeCount('SG', count), label);
    });
  }

  testWidgets('Chinese expiry date renders in Prism', (tester) async {
    await tester.pumpWidget(
      PrismApp(
        theme: PrismTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: targetLocalizationsDelegates,
        home: Surface(child: ExpireChip(expire: DateTime(2026, 11, 28))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026/11/28'), findsOneWidget);
  });
}
