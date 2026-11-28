import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/metrics.dart' show pageToolbarHeight;
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:target/app/target_app.dart';
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/features/home/home_page.dart';
import 'package:target/features/home/presentation/dashboard/start_toggle.dart';
import 'package:target/features/logs/presentation/logs_page.dart';
import 'package:target/features/logs/presentation/widgets/log_toolbar.dart';
import 'package:target/features/settings/data/settings_store.dart';

void main() {
  for (final (layout, width) in [('mobile', 360.0), ('desktop', 1200.0)]) {
    testWidgets('$layout app customizes the dashboard and opens Logs', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final store = MemorySettingsStore();
      await tester.pumpWidget(
        TargetApp(
          capabilities: const AppCapabilities(AppPlatform.unsupported),
          coreGateway: const UnavailableCoreGateway(),
          initialSettings: const AppSettings(
            themeMode: ThemeModeOption.dark,
            dashboardOrder: ['status', 'traffic', 'ip'],
            dashboardVisible: ['status', 'traffic', 'ip'],
          ),
          settingsStore: store,
        ),
      );
      await tester.pumpAndSettle();

      final home = find.byType(HomePage);
      expect(home, findsOneWidget);
      expect(prism.Theme.of(tester.element(home)).brightness, Brightness.dark);
      expect(find.text('IP information'), findsOneWidget);
      final start = tester.widget<StartToggle>(find.byType(StartToggle));
      expect(start.enabled, isFalse);

      await tester.tap(find.byTooltip('Customize dashboard'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Done'), findsOneWidget);
      expect(find.byType(SliverReorderableList), findsOneWidget);

      await tester.tap(find.byTooltip('Remove Live traffic'));
      await tester.pumpAndSettle();
      expect((await store.load()).dashboardVisible, ['status', 'ip']);
      tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!(0, 1);
      await tester.pumpAndSettle();
      expect((await store.load()).dashboardVisible, ['ip', 'status']);
      await tester.ensureVisible(find.byTooltip('Add Live traffic'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add Live traffic'));
      await tester.pumpAndSettle();
      expect((await store.load()).dashboardVisible, [
        'ip',
        'status',
        'traffic',
      ]);
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final navigation = width < 600
          ? find.byType(prism.NavigationDock)
          : find.byType(prism.NavigationSidebar);
      await tester.tap(
        find
            .descendant(of: navigation, matching: find.text('Logs'))
            .hitTestable()
            .first,
      );
      await tester.pumpAndSettle();

      final logs = find.byType(LogsPage);
      expect(logs, findsOneWidget);
      final title = find.descendant(of: logs, matching: find.text('Logs'));
      final toolbar = tester.getRect(find.byType(LogToolbar));
      expect(toolbar.left, tester.getTopLeft(title).dx);
      expect(toolbar.top, pageToolbarHeight);
    });
  }
}
