import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/runtime/core_gateway.dart';
import 'package:target/core/runtime/core_models.dart';
import 'package:target/core/theme/app_theme.dart';
import 'package:target/app/shell/app_shell.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/core/runtime/subscription_gateway.dart';
import 'package:target/data/models/proxy_group.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/maps/presentation/widgets/abstract_world_map.dart';
import 'package:target/features/profiles/presentation/profiles_workspace_page.dart';
import 'package:target/features/proxies/presentation/node_pool_page.dart';
import 'package:target/features/proxies/application/proxies_notifier.dart';
import 'package:target/features/subscriptions/application/subscriptions_notifier.dart';
import 'package:target/l10n/app_localizations.dart';
import 'package:targetlib/targetlib.dart' as targetlib;

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester,
    _ProfilesGateway gateway, {
    Widget page = const ProfilesWorkspacePage(),
    Size size = const Size(1200, 900),
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.dark,
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
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdaptiveScaffold(
            selectedIndex: page is NodePoolPage ? 2 : 1,
            onDestinationSelected: (_) {},
            child: page,
          ),
        ),
      ),
    );
    await container.read(subscriptionsProvider.notifier).load();
    await tester.pumpAndSettle();
    return container;
  }

  CheckboxListTile checkbox(WidgetTester tester, String id) =>
      tester.widget<CheckboxListTile>(find.byKey(ValueKey('enable-$id')));

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
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
        find.byKey(const ValueKey('enable-primary')),
      );
      final expected = mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
      expect(Theme.of(context).colorScheme, expected.colorScheme);
      expect(MaterialLocalizations.of(context).copyButtonLabel, '复制');
      await tester.tap(find.text('添加订阅'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      final fieldContext = tester.element(find.byType(TextFormField).first);
      expect(Theme.of(fieldContext).colorScheme, expected.colorScheme);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('URL is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'subscriptions can be independently enabled and refresh the shared pool',
    (tester) async {
      final gateway = _ProfilesGateway();
      final container = await mount(tester, gateway);
      expect(checkbox(tester, 'primary').value, isTrue);
      expect(checkbox(tester, 'backup').value, isTrue);
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes,
        hasLength(2),
      );

      await tester.tap(find.byKey(const ValueKey('enable-primary')));
      await tester.pumpAndSettle();
      expect(gateway.changes, [('primary', false)]);
      expect(checkbox(tester, 'primary').value, isFalse);
      expect(checkbox(tester, 'backup').value, isTrue);
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes.single.id,
        'jp-1',
      );

      await tester.tap(find.byKey(const ValueKey('enable-primary')));
      await tester.pumpAndSettle();
      expect(
        container.read(proxiesProvider).selectedGroup?.nodes,
        hasLength(2),
      );
      expect(checkbox(tester, 'backup').value, isTrue);
    },
  );

  testWidgets(
    'a rejected subscription change preserves the checkboxes and nodes',
    (tester) async {
      final gateway = _ProfilesGateway()..failChange = true;
      final container = await mount(tester, gateway);
      await tester.tap(find.byKey(const ValueKey('enable-primary')));
      await tester.pumpAndSettle();
      expect(checkbox(tester, 'primary').value, isTrue);
      expect(checkbox(tester, 'backup').value, isTrue);
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

  testWidgets('pending changes cannot be submitted twice', (tester) async {
    final gateway = _ProfilesGateway()..changeGate = Completer<void>();
    await mount(tester, gateway);
    await tester.tap(find.byKey(const ValueKey('enable-primary')));
    await tester.pump();
    expect(checkbox(tester, 'primary').onChanged, isNull);
    expect(checkbox(tester, 'primary').value, isTrue);
    expect(gateway.changes, hasLength(1));
    gateway.changeGate!.complete();
    await tester.pumpAndSettle();
    expect(checkbox(tester, 'primary').value, isFalse);
  });

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
    gateway.runtimeChanges.add(
      CoreSnapshot(proxyGroups: gateway.subscriptions.first.profile.groups),
    );
    await tester.pumpAndSettle();
    expect(container.read(proxiesProvider).groups, isEmpty);
  });

  testWidgets('map filters the shared pool before explicit node selection', (
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
    await tester.ensureVisible(find.byKey(const ValueKey('node-jp-1')));
    await tester.tap(find.byKey(const ValueKey('node-jp-1')));
    await tester.pumpAndSettle();
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      'jp-1',
    );
    expect(
      tester.widget<ListTile>(find.byKey(const ValueKey('node-jp-1'))).selected,
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
    await tester.enterText(find.byType(TextField), 'no-match');
    await tester.pumpAndSettle();
    expect(find.text('No matching nodes'), findsOneWidget);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    map = tester.widget<AbstractWorldMap>(find.byType(AbstractWorldMap));
    expect(map.nodes, hasLength(2));
    expect(
      container.read(proxiesProvider).selectedGroup?.selectedNodeId,
      'jp-1',
    );
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
                : find.byType(SingleChildScrollView),
            const Offset(0, -650),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _ProfilesGateway extends UnavailableCoreGateway
    implements SubscriptionGateway {
  final _subscriptionChanges = StreamController<void>.broadcast(sync: true);
  final runtimeChanges = StreamController<CoreSnapshot>.broadcast(sync: true);
  final enabled = {'primary': true, 'backup': true};
  final changes = <(String, bool)>[];
  bool failChange = false;
  Completer<void>? changeGate;

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
    _subscription(
      id: 'primary',
      name: 'Primary',
      node: const ProxyNode(
        id: 'sg-1',
        name: 'Singapore',
        type: 'vmess',
        countryCode: 'SG',
      ),
    ),
    _subscription(
      id: 'backup',
      name: 'Backup',
      node: const ProxyNode(
        id: 'jp-1',
        name: 'Tokyo',
        type: 'vmess',
        countryCode: 'JP',
      ),
    ),
  ];

  @override
  Future<RuntimeSubscriptionSnapshot> listSubscriptions() async =>
      RuntimeSubscriptionSnapshot(subscriptions: subscriptions);

  @override
  Future<targetlib.NodePool> getNodePool() async => targetlib.NodePool(
    nodes: [
      for (final sub in subscriptions.where((sub) => sub.enabled))
        for (final node in sub.profile.nodes)
          targetlib.ProfileNode(
            tag: node.id,
            name: node.name,
            type: node.type,
            countryCode: node.countryCode,
            subscriptionId: sub.id,
          ),
    ],
  );

  @override
  Future<RuntimeSubscription> setSubscriptionEnabled(
    String id,
    bool value,
  ) async {
    changes.add((id, value));
    if (changeGate != null) await changeGate!.future;
    if (failChange) throw StateError('Change rejected');
    enabled[id] = value;
    _subscriptionChanges.add(null);
    return subscriptions.firstWhere((sub) => sub.id == id);
  }

  RuntimeSubscription _subscription({
    required String id,
    required String name,
    required ProxyNode node,
  }) => RuntimeSubscription(
    id: id,
    name: name,
    source: '$id.example.test',
    enabled: enabled[id]!,
    autoUpdate: false,
    updateIntervalSeconds: 86400,
    status: RuntimeSubscriptionStatus.ready,
    profile: RuntimeProfile(
      nodes: [node],
      groups: [
        ProxyGroup(
          id: ProxyGroup.runtimeSelectorGroupId,
          name: 'proxy',
          type: 'selector',
          nodes: [node],
        ),
      ],
    ),
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
  Future<void> removeSubscription(String id) => throw UnimplementedError();
  @override
  Future<RuntimeSubscription> renameSubscription(String id, String name) =>
      throw UnimplementedError();
  @override
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id) =>
      throw UnimplementedError();
  @override
  Future<void> dispose() async {
    await _subscriptionChanges.close();
    await runtimeChanges.close();
  }
}
