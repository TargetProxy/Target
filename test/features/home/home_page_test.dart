import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/features/home/presentation/dashboard/start_toggle.dart';
import 'package:target/features/home/home_page.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/features/settings/application/settings_notifier.dart';
import 'package:target/features/settings/data/settings_store.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final width in [360.0, 1440.0]) {
    testWidgets('home renders with an unavailable core at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = MemorySettingsStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialSettingsProvider.overrideWithValue(
              const AppSettings(
                dashboardOrder: ['status', 'traffic', 'ip'],
                dashboardVisible: ['status', 'traffic', 'ip'],
              ),
            ),
            settingsStoreProvider.overrideWithValue(store),
            appCapabilitiesProvider.overrideWithValue(
              const AppCapabilities(AppPlatform.unsupported),
            ),
            coreGatewayProvider.overrideWithValue(
              const UnavailableCoreGateway(),
            ),
          ],
          child: prism.PrismApp(
            theme: PrismTheme.light,
            darkTheme: PrismTheme.dark,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              TargetUiLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => prism.ViewScope(
              size: Size(width, 900),
              isMobile: width <= 600,
              child: child!,
            ),
            home: const Scaffold(body: HomePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('IP information'), findsOneWidget);
      final start = tester.widget<StartToggle>(find.byType(StartToggle));
      expect(start.enabled, isFalse);

      await tester.tap(find.byTooltip('Customize dashboard'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byTooltip('Done'), findsOneWidget);
      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Remove Live traffic'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect((await store.load()).dashboardVisible, ['status', 'ip']);
      tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!(0, 1);
      await tester.pump(const Duration(milliseconds: 600));
      expect((await store.load()).dashboardVisible, ['ip', 'status']);
      await tester.ensureVisible(find.byTooltip('Add Live traffic'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byTooltip('Add Live traffic'));
      await tester.pump(const Duration(milliseconds: 600));
      expect((await store.load()).dashboardVisible, [
        'ip',
        'status',
        'traffic',
      ]);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
