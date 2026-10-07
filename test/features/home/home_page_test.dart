import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/features/home/home_page.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    testWidgets('home renders with an unavailable core at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appCapabilitiesProvider.overrideWithValue(
              const AppCapabilities(AppPlatform.unsupported),
            ),
            coreGatewayProvider.overrideWithValue(
              const UnavailableCoreGateway(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HomePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('IP information'), findsOneWidget);
      final start = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start'),
      );
      expect(start.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
