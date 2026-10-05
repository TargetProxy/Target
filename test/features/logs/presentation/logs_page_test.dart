import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/features/logs/presentation/logs_page.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final width in [360.0, 900.0]) {
    testWidgets('logs page renders at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: LogsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
