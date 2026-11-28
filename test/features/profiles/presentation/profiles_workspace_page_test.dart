import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/features/profiles/presentation/widgets/subscription_card.dart';
import 'package:target/features/proxies/presentation/widgets/proxy_card.dart';
import 'package:target/app/router.dart';
import 'package:target/app/shell/app_shell.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/core/runtime/subscription_gateway.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/maps/presentation/widgets/abstract_world_map.dart';
import 'package:target/features/profiles/presentation/profiles_workspace_page.dart';
import 'package:target/features/proxies/presentation/node_pool_page.dart';
import 'package:target/features/proxies/application/proxies_notifier.dart';
import 'package:target/features/subscriptions/application/subscriptions_notifier.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester,
    _ProfilesGateway gateway, {
    Widget page = const ProfilesWorkspacePage(),
    Size size = const Size(1200, 900),
    Locale locale = const Locale('en'),
    prism.ThemeMode themeMode = prism.ThemeMode.dark,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final container = ProviderContainer(
      overrides: [coreGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: prism.PrismApp(
          theme: PrismTheme.light,
          darkTheme: PrismTheme.dark,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: targetLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => prism.ViewScope(
            size: size,
            isMobile: size.width <= 600,
            child: child!,
          ),
          home: AppShell(
            location: page is NodePoolPage
                ? AppRoute.nodes.path
                : AppRoute.proxies.path,
            child: page,
          ),
        ),
      ),
    );
    await container.read(subscriptionsProvider.notifier).load();
    await tester.pumpAndSettle();
    return container;
  }

  SubscriptionCard subscriptionCard(WidgetTester tester, String id) =>
      tester.widget<SubscriptionCard>(find.byKey(ValueKey('subscription-$id')));

  for (final mode in [prism.ThemeMode.light, prism.ThemeMode.dark]) {
    testWidgets('subscription controls and dialog use the app theme in $mode', (
      tester,
    ) async {
      await mount(
        tester,
        _ProfilesGateway(),
        locale: const Locale('zh'),
        themeMode: mode,
      );
      final context = tester.element(
        find.byKey(const ValueKey('subscription-primary')),
      );
      final expected = mode == prism.ThemeMode.dark
          ? PrismTheme.dark
          : PrismTheme.light;
      expect(
        prism.Theme.of(context).colorScheme.primary,
        expected.colorScheme.primary,
      );
      await tester.tap(find.byTooltip('添加订阅'));
      await tester.pumpAndSettle();
      expect(find.byType(prism.TextFormField), findsNWidgets(2));
      final fieldContext = tester.element(
        find.byType(prism.TextFormField).first,
      );
      expect(prism.Theme.of(fieldContext).brightness, expected.brightness);
      final l10n = AppLocalizations.of(fieldContext);
      await tester.tap(find.text(l10n.add));
      await tester.pumpAndSettle();
      expect(find.text(l10n.urlRequired), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'subscriptions can be independently enabled and refresh the shared pool',
    (tester) async {
      final gateway = _ProfilesGateway();
      final container = await mount(tester, gateway);
      final card = find.byKey(const ValueKey('subscription-primary'));
      final actions = find.descendant(
        of: card,
        matching: find.byType(prism.IconButton),
      );
      final badge = find.descendant(
        of: card,
        matching: find.byType(prism.SelectionBadge),
      );
      final detailsCenter = tester.getCenter(actions.first);
      final updateCenter = tester.getCenter(actions.last);
      final badgeCenter = tester.getCenter(badge);
      expect(updateCenter - detailsCenter, badgeCenter - updateCenter);
      expect(badgeCenter.dy, detailsCenter.dy);
      expect(subscriptionCard(tester, 'primary').profile.enabled, isTrue);
      expect(subscriptionCard(tester, 'backup').profile.enabled, isTrue);
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes,
        hasLength(2),
      );

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
      expect(tester.getCenter(actions.first), detailsCenter);
      expect(tester.getCenter(actions.last), updateCenter);
      expect(gateway.changes, [('primary', false)]);
      expect(subscriptionCard(tester, 'primary').profile.enabled, isFalse);
      expect(subscriptionCard(tester, 'backup').profile.enabled, isTrue);
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes.single.id,
        'jp-1',
      );

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes,
        hasLength(2),
      );
      expect(subscriptionCard(tester, 'backup').profile.enabled, isTrue);
    },
  );

  testWidgets(
    'a rejected subscription change preserves the checkboxes and nodes',
    (tester) async {
      final gateway = _ProfilesGateway()..failChange = true;
      final container = await mount(tester, gateway);
      await tester.tap(find.byKey(const ValueKey('subscription-primary')));
      await tester.pumpAndSettle();
      expect(subscriptionCard(tester, 'primary').profile.enabled, isTrue);
      expect(subscriptionCard(tester, 'backup').profile.enabled, isTrue);
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes,
        hasLength(2),
      );
      expect(
        find.textContaining('Failed to change subscription'),
        findsOneWidget,
      );
    },
  );

  testWidgets('disabling the selected source never selects another node', (
    tester,
  ) async {
    final gateway = _ProfilesGateway();
    final container = await mount(tester, gateway);
    await container.read(proxiesProvider.notifier).selectNode('sg-1');
    await container
        .read(subscriptionsProvider.notifier)
        .setEnabled('primary', false);
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      isNull,
    );
    await container.read(subscriptionsProvider.notifier).load();
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      isNull,
    );
    await container
        .read(subscriptionsProvider.notifier)
        .setEnabled('backup', false);
    await tester.pumpAndSettle();
    expect(container.read(proxiesProvider).groups, isEmpty);
    expect(find.text('0 subscriptions enabled · 0 nodes'), findsOneWidget);
    gateway.runtimeChanges.add(const CoreSnapshot());
    await tester.pumpAndSettle();
    expect(container.read(proxiesProvider).groups, isEmpty);
  });

  testWidgets('node selection persists while filtering the shared pool', (
    tester,
  ) async {
    final container = await mount(
      tester,
      _ProfilesGateway(),
      page: const NodePoolPage(),
    );
    var map = tester.widget<AbstractWorldMap>(find.byType(AbstractWorldMap));
    expect(
      map.nodes.map((entry) => entry.countryCode),
      containsAll(['SG', 'JP']),
    );
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      isNull,
    );
    map.onSelect!('JP');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('node-sg-1')), findsNothing);
    expect(find.byKey(const ValueKey('node-jp-1')), findsOneWidget);
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      isNull,
    );
    final card = find.byKey(const ValueKey('node-jp-1'));
    final action = find.descendant(
      of: card,
      matching: find.byType(prism.TextButton),
    );
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final title = find.descendant(
      of: card,
      matching: find.text(tester.widget<ProxyCard>(card).proxy.displayName),
    );
    final cardCenter = tester.getCenter(card);
    final actionPosition = tester.getCenter(action);
    expect(tester.getCenter(title).dx, closeTo(cardCenter.dx, 1));
    expect(actionPosition.dx, closeTo(cardCenter.dx, 1));
    expect(
      (tester.getTopLeft(title).dy + tester.getBottomLeft(action).dy) / 2,
      closeTo(cardCenter.dy, 1),
    );
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(tester.getCenter(action), actionPosition);
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      'jp-1',
    );
    expect(
      tester
          .widget<ProxyCard>(
            find.byWidgetPredicate(
              (widget) => widget is ProxyCard && widget.proxy.id == 'jp-1',
            ),
          )
          .selected,
      isTrue,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('source-primary')));
    await tester.tap(find.byKey(const ValueKey('source-primary')));
    await tester.pumpAndSettle();
    map = tester.widget<AbstractWorldMap>(find.byType(AbstractWorldMap));
    expect(map.nodes.single.countryCode, 'SG');
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      'jp-1',
    );
    await tester.enterText(find.byType(EditableText), 'no-match');
    await tester.pumpAndSettle();
    expect(find.text('No matching nodes'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    map = tester.widget<AbstractWorldMap>(find.byType(AbstractWorldMap));
    expect(map.nodes, hasLength(2));
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      'jp-1',
    );
  });

  testWidgets('node pool streams latency results and cancels pending probes', (
    tester,
  ) async {
    final gateway = _ProfilesGateway();
    final container = await mount(tester, gateway, page: const NodePoolPage());
    final card = find.byKey(const ValueKey('node-sg-1'));
    final single = find.descendant(
      of: card,
      matching: find.byType(prism.TextButton),
    );
    Finder toolbar(String tooltip) => find.byWidgetPredicate(
      (widget) => widget is prism.IconButton && widget.tooltip == tooltip,
    );

    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(single);
    await tester.pump();
    expect(gateway.latencyRequests.single, ['sg-1']);
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      isNull,
    );
    gateway.latencyResults.add(
      const CoreLatencyResult(
        outboundId: 'sg-1',
        status: CoreLatencyStatus.success,
        delayMilliseconds: 42,
      ),
    );
    unawaited(gateway.latencyResults.close());
    await tester.pumpAndSettle();
    expect(find.text('42 ms'), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(single));
    await tester.pumpAndSettle();
    final tooltip = find.byElementPredicate((element) {
      final widget = element.widget;
      return widget is Text &&
          widget.data == 'Test latency' &&
          element.findAncestorWidgetOfExactType<prism.TextButton>() == null;
    });
    expect(
      tester.getTopLeft(tooltip).dy,
      greaterThan(tester.getCenter(single).dy),
    );
    await mouse.removePointer();

    await tester.pump();
    expect(container.read(proxiesProvider).testing, isFalse);
    await tester.tap(toolbar('Test all nodes').first);
    await tester.pump();
    expect(gateway.latencyRequests.last, unorderedEquals(['sg-1', 'jp-1']));
    gateway.latencyResults.add(
      const CoreLatencyResult(
        outboundId: 'sg-1',
        status: CoreLatencyStatus.failed,
      ),
    );
    await tester.pump();
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('42 ms'), findsNothing);
    expect(container.read(proxiesProvider).testingNodeIds, {'jp-1'});

    await tester.tap(toolbar('Cancel').first);
    await tester.pumpAndSettle();
    expect(gateway.latencyResults.hasListener, isFalse);
    expect(container.read(proxiesProvider).testingNodeIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'node pool displays an actionable empty state when all sources are disabled',
    (tester) async {
      await mount(
        tester,
        _ProfilesGateway()..enabled.updateAll((_, _) => false),
        page: const NodePoolPage(),
      );
      expect(find.text('Your node pool is empty'), findsOneWidget);
      expect(find.byType(AbstractWorldMap), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 800.0, 1440.0]) {
    for (final nodePage in [false, true]) {
      testWidgets(
        '${nodePage ? 'nodes' : 'subscriptions'} fit width $width in Chinese',
        (tester) async {
          await mount(
            tester,
            _ProfilesGateway(),
            page: nodePage
                ? const NodePoolPage()
                : const ProfilesWorkspacePage(),
            size: Size(width, 900),
            locale: const Locale('zh'),
          );
          expect(tester.takeException(), isNull);
          await tester.drag(
            nodePage
                ? find.byType(CustomScrollView)
                : find.byType(ListView).first,
            const Offset(0, -650),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _ProfilesGateway extends UnavailableCoreGateway {
  final _subscriptionChanges = StreamController<void>.broadcast(sync: true);
  final runtimeChanges = StreamController<CoreSnapshot>.broadcast(sync: true);
  final enabled = {'primary': true, 'backup': true};
  final changes = <(String, bool)>[];
  final latencyRequests = <List<String>>[];
  late StreamController<CoreLatencyResult> latencyResults;
  bool failChange = false;

  @override
  bool get isAvailable => true;
  @override
  Stream<CoreSnapshot> get snapshots => runtimeChanges.stream;
  @override
  Stream<void> get subscriptionChanges => _subscriptionChanges.stream;
  @override
  Future<RuntimeSettings> getRuntimeConfig() async => const RuntimeSettings();
  @override
  Future<CoreSnapshot> current() async => const CoreSnapshot();

  List<RuntimeSubscription> get subscriptions => [
    _subscription(id: 'primary', name: 'Primary'),
    _subscription(id: 'backup', name: 'Backup'),
  ];

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() async =>
      RuntimeSubscriptionSnapshot(subscriptions: subscriptions);

  @override
  Future<List<CoreNode>> getNodePool() async => [
    for (final sub in subscriptions.where((sub) => sub.enabled))
      CoreNode(
        id: sub.id == 'primary' ? 'sg-1' : 'jp-1',
        name: sub.id == 'primary' ? 'Singapore' : 'Tokyo',
        type: 'vmess',
        countryCode: sub.id == 'primary' ? 'SG' : 'JP',
        subscriptionId: sub.id,
      ),
  ];

  @override
  Stream<CoreLatencyResult> testLatencies(Iterable<String> outboundIds) {
    latencyRequests.add(outboundIds.toList());
    latencyResults = StreamController<CoreLatencyResult>();
    return latencyResults.stream;
  }

  @override
  Future<RuntimeSubscription> setSubscriptionEnabled(
    String id,
    bool value,
  ) async {
    changes.add((id, value));
    if (failChange) throw StateError('Change rejected');
    enabled[id] = value;
    _subscriptionChanges.add(null);
    return subscriptions.firstWhere((sub) => sub.id == id);
  }

  RuntimeSubscription _subscription({
    required String id,
    required String name,
  }) => RuntimeSubscription(
    id: id,
    name: name,
    source: '$id.example.test',
    enabled: enabled[id]!,
    autoUpdate: false,
    updateIntervalSeconds: 86400,
    status: RuntimeSubscriptionStatus.ready,
    nodeCount: 1,
  );

  @override
  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
    bool updateNow = false,
  }) => throw UnimplementedError();
  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) =>
      throw UnimplementedError();
  @override
  Future<void> dispose() async {
    if (latencyRequests.isNotEmpty) await latencyResults.close();
    await _subscriptionChanges.close();
    await runtimeChanges.close();
  }
}
