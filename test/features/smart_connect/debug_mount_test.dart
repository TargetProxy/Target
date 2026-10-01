import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/features/smart_connect/application/smart_connect_notifier.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/presentation/smart_connect_page.dart';
import 'fake_intent_core.dart';

const disney = SmartPolicy(
  id: 'disney',
  domains: {'disneyplus.com'},
  selectionMode: SmartSelectionMode.followDefault,
  probeTargets: [SmartProbeTarget(url: 'https://disneyplus.com/')],
);

void main() {
  testWidgets('debug mount state', (tester) async {
    final errors = <String>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add('${details.exception}\n${details.stack}');
    };
    addTearDown(() {
      FlutterError.onError = oldOnError;
    });
    SharedPreferences.setMockInitialValues({
      'smart_connect.policies': jsonEncode([disney.toJson()]),
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 950);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final core = FakeIntentCore()
      ..effective = true
      ..pool = pb.NodePool(
        revision: 'pool1',
        nodes: [
          pb.ProfileNode(
            tag: 'hk',
            name: 'Hong Kong 01',
            type: 'vless',
            countryCode: 'HK',
          ),
        ],
      );
    core.config.selectors.add(
      pb.SelectorConfig(tag: 'proxy', selectedNodeId: 'hk'),
    );
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(core)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SmartConnectPage())),
      ),
    );
    await tester.pumpAndSettle();
    final state = container.read(smartConnectProvider);
    debugPrint('loaded=${state.snapshot.loaded} error=${state.error} '
        'nodes=${state.snapshot.nodes.length} '
        'default=${state.snapshot.defaultNodeId} '
        'running=${state.snapshot.running}');
    debugPrint('mode-direct: ${find.byKey(const ValueKey('mode-direct')).evaluate().length}');
    debugPrint('detail-default: ${find.byKey(const ValueKey('detail-default')).evaluate().length}');
    debugPrint('detail-disney: ${find.byKey(const ValueKey('detail-disney')).evaluate().length}');
    debugPrint('group-default: ${find.byKey(const ValueKey('group-default')).evaluate().length}');
    final exc = tester.takeException();
    debugPrint('exception: $exc');
    for (final e in errors) {
      debugPrint('FRAMEWORK ERROR:\n$e');
    }
  });
}
