import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:targetlib/targetlib.dart' as pb;
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/presentation/smart_connect_page.dart';
import 'package:target/features/smart_connect/data/smart_policy_store.dart';
import 'fake_intent_core.dart';

const disney = SmartPolicy(
  id: 'disney',
  name: 'Disney+',
  domains: {'disneyplus.com'},
  selectionMode: SmartSelectionMode.followDefault,
  probeTargets: [SmartProbeTarget(url: 'https://disneyplus.com/')],
);

Future<({FakeIntentCore core, ProviderContainer container})> mount(
  WidgetTester tester,
  double width,
) async {
  SharedPreferences.setMockInitialValues({
    'smart_connect.policies': jsonEncode([disney.toJson()]),
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 950);
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
        pb.ProfileNode(
          tag: 'us',
          name: 'United States 02',
          type: 'vless',
          countryCode: 'US',
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
  return (core: core, container: container);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      key.startsWith('mode-') ? -200 : 200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('detail-disney')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 800.0, 1440.0]) {
    testWidgets('group-specific draft, apply and follow default at $width', (
      tester,
    ) async {
      final setup = await mount(tester, width);
      await tapKey(tester, 'group-disney');
      await tapKey(tester, 'mode-manual');
      await tapKey(tester, 'candidate-us');
      expect(setup.core.bindingWrites, 0);
      expect(setup.core.selections, isEmpty);
      await tapKey(tester, 'apply-group');
      expect(setup.core.forced.single.serviceId, 'target.smart.disney');
      expect(setup.core.forced.single.nodeId, 'us');
      expect(setup.core.config.selectors.single.selectedNodeId, 'hk');
      expect(
        (await SmartPolicyStore().load()).single.selectionMode,
        SmartSelectionMode.manual,
      );
      await tapKey(tester, 'mode-followDefault');
      await tapKey(tester, 'apply-group');
      expect(setup.core.config.serviceBindings, isEmpty);
      expect(setup.core.snapshot.policies, isEmpty);
      expect(
        (await SmartPolicyStore().load()).single.selectionMode,
        SmartSelectionMode.followDefault,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'leaving a draft asks before discarding, cancellation does not route',
    (tester) async {
      final setup = await mount(tester, 1440);
      await tapKey(tester, 'group-disney');
      await tapKey(tester, 'mode-direct');
      await tapKey(tester, 'group-default');
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(setup.core.bindingWrites, 0);
      await tapKey(tester, 'group-default');
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(setup.core.bindingWrites, 0);
      expect(find.text('Apply to Default'), findsOneWidget);
    },
  );
  testWidgets('failed binding retains the previous policy and the draft', (
    tester,
  ) async {
    final setup = await mount(tester, 1440);
    setup.core.failBinding = true;
    await tapKey(tester, 'group-disney');
    await tapKey(tester, 'mode-direct');
    await tapKey(tester, 'apply-group');
    expect(find.textContaining('Binding rejected'), findsOneWidget);
    expect(
      (await SmartPolicyStore().load()).single.selectionMode,
      SmartSelectionMode.followDefault,
    );
    expect(setup.core.config.serviceBindings, isEmpty);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('apply-group')))
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('recommendation waits for apply and leaves Default unchanged', (
    tester,
  ) async {
    final setup = await mount(tester, 1440);
    await tapKey(tester, 'group-disney');
    await tapKey(tester, 'mode-automatic');
    await tester.ensureVisible(find.text('Get recommendation'));
    await tester.tap(find.text('Get recommendation'));
    await tester.pumpAndSettle();
    expect(setup.core.bindingWrites, 0);
    expect(find.text('Recommendation only · not yet applied'), findsOneWidget);
    await tapKey(tester, 'apply-group');
    expect(setup.core.bindingWrites, 1);
    expect(setup.core.selections, isEmpty);
  });
  testWidgets('default Direct persists separately from service routing', (
    tester,
  ) async {
    final setup = await mount(tester, 1440);
    await tapKey(tester, 'mode-direct');
    expect(setup.core.selections, isEmpty);
    await tapKey(tester, 'apply-group');
    expect(setup.core.selections, [('proxy', 'direct')]);
    expect(setup.core.bindingWrites, 0);
    await tapKey(tester, 'mode-manual');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('apply-group')))
          .onPressed,
      isNull,
    );
    await tapKey(tester, 'candidate-us');
    await tapKey(tester, 'apply-group');
    expect(setup.core.selections.last, ('proxy', 'us'));
  });
  testWidgets('groups remain editable when the intent API is unavailable', (
    tester,
  ) async {
    final setup = await mount(tester, 1440);
    setup.core.intentApi = false;
    await tester.tap(find.byTooltip('Refresh runtime'));
    await tester.pumpAndSettle();
    expect(find.textContaining('intent API is unavailable'), findsOneWidget);
    await tester.tap(find.text('Add group'));
    await tester.pumpAndSettle();
    expect(find.text('Create group'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
