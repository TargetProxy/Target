import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/features/settings/application/settings_notifier.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/presentation/smart_connect_page.dart';
import 'smart_connect_repository_test.dart' show FakeSmartGateway;

void main() {
  for (final width in [360.0, 800.0, 1440.0]) {
    testWidgets('Smart Connect service actions fit width $width', (
      tester,
    ) async {
      const policy = SmartPolicy(
        id: 'direct',
        name: 'Local Direct',
        domains: {'example.cn'},
        selectionMode: SmartSelectionMode.direct,
      );
      SharedPreferences.setMockInitialValues({
        'smart_connect.policies': jsonEncode([policy.toJson()]),
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final gateway = FakeSmartGateway();
      final container = ProviderContainer(
        overrides: [
          coreGatewayProvider.overrideWithValue(gateway),
          initialSettingsProvider.overrideWithValue(
            const AppSettings(smartConnectEnabled: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SmartConnectPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Local Direct'));
      await tester.tap(find.text('Local Direct'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Re-evaluate'));
      await tester.tap(find.text('Re-evaluate'));
      await tester.pumpAndSettle();
      expect(gateway.writes, 0);
      await tester.ensureVisible(find.text('Apply result'));
      await tester.tap(find.text('Apply result'));
      await tester.pumpAndSettle();
      expect(gateway.writes, 1);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Not effective'), findsOneWidget);
    });
  }
  testWidgets(
    'off page is inert and policies can be configured without native support',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeSmartGateway()..supported = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [coreGatewayProvider.overrideWithValue(gateway)],
          child: const MaterialApp(home: SmartConnectPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Smart Connect is off.'), findsOneWidget);
      await tester.tap(find.text('Add service'));
      await tester.pumpAndSettle();
      expect(find.text('Add service policy'), findsOneWidget);
      expect(gateway.writes, 0);
      expect(gateway.requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
