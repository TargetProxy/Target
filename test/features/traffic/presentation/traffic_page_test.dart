import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/traffic/presentation/traffic_page.dart';
import 'package:target/l10n/app_localizations.dart';
import 'package:target/l10n/app_localizations_zh.dart';

void main() {
  testWidgets('shows live traffic chart from a real sample', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coreGatewayProvider.overrideWithValue(
            _SnapshotGateway(
              CoreSnapshot(
                lifecycle: CoreLifecycle.running,
                traffic: TrafficSnapshot(
                  uploadBytes: 1024,
                  downloadBytes: 2048,
                  activeConnections: 3,
                  available: true,
                  sampledAt: DateTime.utc(2026, 1, 1, 12),
                  intervalMilliseconds: 1000,
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TrafficPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live traffic'), findsOneWidget);
    expect(find.text('Upload rate'), findsOneWidget);
    expect(find.text('Download rate'), findsOneWidget);
    expect(find.text('1.0 KB/s'), findsOneWidget);
    expect(find.text('2.0 KB/s'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(SfCartesianChart), findsOneWidget);
    final trafficCard = find.ancestor(
      of: find.text('1.0 KB/s'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: trafficCard, matching: find.byType(SfCartesianChart)),
      findsOneWidget,
    );
    await tester.binding.setSurfaceSize(const Size(960, 700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the chart current after its history fills and clears on stop',
    (tester) async {
      final gateway = _SnapshotGateway(
        const CoreSnapshot(lifecycle: CoreLifecycle.stopped),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [coreGatewayProvider.overrideWithValue(gateway)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: TrafficPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SfCartesianChart), findsNothing);

      for (var sample = 0; sample <= 62; sample++) {
        gateway.controller.add(
          CoreSnapshot(
            lifecycle: CoreLifecycle.running,
            traffic: TrafficSnapshot(
              uploadBytes: sample * 1024,
              downloadBytes: sample * 2048,
              activeConnections: 3,
              available: true,
              sampledAt: DateTime.utc(2026, 1, 1, 12, 0, sample),
              intervalMilliseconds: 250,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();

      final renderers = tester.allRenderObjects
          .whereType<SplineAreaSeriesRenderer>()
          .toList();
      expect(renderers, hasLength(2));
      expect(renderers.first.yValues, hasLength(60));
      expect(renderers.first.yValues.first, 3 * 1024);
      expect(renderers.first.yValues.last, 62 * 1024);
      expect(renderers.last.yValues.last, 62 * 2048);
      expect(find.text('62.0 KB/s'), findsOneWidget);
      expect(find.text('124.0 KB/s'), findsOneWidget);
      expect(tester.takeException(), isNull);

      gateway.controller.add(
        const CoreSnapshot(lifecycle: CoreLifecycle.stopped),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SfCartesianChart), findsNothing);
      expect(find.text('--'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  test('provides Chinese traffic labels', () {
    final l10n = AppLocalizationsZh();

    expect(l10n.liveTraffic, '实时流量');
    expect(l10n.uploadRate, '上传速率');
    expect(l10n.activeConnections, '活动连接');
  });
}

class _SnapshotGateway extends UnavailableCoreGateway {
  _SnapshotGateway(this.snapshot);

  final CoreSnapshot snapshot;
  final controller = StreamController<CoreSnapshot>();

  @override
  Stream<CoreSnapshot> get snapshots => controller.stream;

  @override
  Future<void> dispose() => controller.close();

  @override
  bool get isAvailable => true;

  @override
  Future<RuntimeSettings> getRuntimeConfig() async => const RuntimeSettings();

  @override
  Future<CoreSnapshot> current() async => snapshot;
}
