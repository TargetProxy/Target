import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/features/traffic/presentation/traffic_page.dart';
import 'package:target/l10n/app_localizations.dart';
import 'package:target/l10n/app_localizations_zh.dart';

void main() {
  testWidgets('shows live traffic without a fake history chart', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coreGatewayProvider.overrideWithValue(
            const _SnapshotGateway(
              CoreSnapshot(
                lifecycle: CoreLifecycle.running,
                traffic: TrafficSnapshot(
                  uploadBytes: 1024,
                  downloadBytes: 2048,
                  activeConnections: 3,
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
    expect(find.text('1.0 KB/s'), findsOneWidget);
    expect(find.text('2.0 KB/s'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Traffic history'), findsNothing);
    expect(find.textContaining('Collecting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('provides Chinese traffic labels', () {
    final l10n = AppLocalizationsZh();

    expect(l10n.liveTraffic, '实时流量');
    expect(l10n.uploadRate, '上传速率');
    expect(l10n.activeConnections, '活动连接');
  });
}

class _SnapshotGateway extends UnavailableCoreGateway {
  const _SnapshotGateway(this.snapshot);

  final CoreSnapshot snapshot;

  @override
  bool get isAvailable => true;

  @override
  Future<CoreSnapshot> current() async => snapshot;
}
