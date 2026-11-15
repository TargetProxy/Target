import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/features/logs/presentation/logs_page.dart';
import 'package:target/features/logs/presentation/widgets/log_toolbar.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:prism_ui/metrics.dart' show pageToolbarHeight;
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final width in [360.0, 900.0]) {
    testWidgets('logs page renders at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: prism.PrismApp(
            theme: PrismTheme.light,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              TargetUiLocalizations.delegate,
            ],
            builder: (context, child) => prism.ViewScope(
              size: Size(width, 700),
              isMobile: width <= 600,
              child: child!,
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logs'), findsOneWidget);
      final titleLeft = tester.getTopLeft(find.text('Logs')).dx;
      final toolbarRect = tester.getRect(find.byType(LogToolbar));
      final contentLeft = toolbarRect.left;
      expect(contentLeft, titleLeft);
      expect(toolbarRect.top, pageToolbarHeight);
      expect(tester.takeException(), isNull);
    });
  }
}
