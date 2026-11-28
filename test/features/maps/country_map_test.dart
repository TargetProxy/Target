import 'package:country_flags/country_flags.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/features/maps/application/proxy_country_map.dart';
import 'package:target/features/maps/presentation/widgets/abstract_world_map.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  group('proxyNodeCountryCode', () {
    test('prefers an explicit supported country code', () {
      const node = ProxyNode(
        id: '1',
        name: 'Any node',
        type: 'vmess',
        countryCode: 'sg',
      );

      expect(proxyNodeCountryCode(node), 'SG');
    });

    test('reads flag emoji and common location aliases', () {
      const flagNode = ProxyNode(
        id: '1',
        name: '🇯🇵 Premium 01',
        type: 'trojan',
      );
      const aliasNode = ProxyNode(
        id: '2',
        name: 'Los Angeles - 02',
        type: 'vless',
      );

      expect(proxyNodeCountryCode(flagNode), 'JP');
      expect(proxyNodeCountryCode(aliasNode), 'US');
    });

    test('does not match short aliases inside words', () {
      const node = ProxyNode(id: '1', name: 'Tokyo premium', type: 'hysteria2');

      expect(proxyNodeCountryCode(node), 'JP');
    });
  });

  test('groups nodes by country and filters out other countries', () {
    const nodes = [
      ProxyNode(id: '1', name: '🇸🇬 01', type: 'vmess'),
      ProxyNode(id: '2', name: 'Singapore 02', type: 'trojan'),
      ProxyNode(id: '3', name: '🇯🇵 01', type: 'vless'),
      ProxyNode(id: '4', name: 'Direct', type: 'direct'),
    ];

    final entries = proxyCountryMapEntries(nodes);
    expect(
      {for (final entry in entries) entry.countryCode: entry.nodeCount},
      {'SG': 2, 'JP': 1},
    );
    expect(proxyNodesInCountry(nodes, 'SG').map((node) => node.id), ['1', '2']);
  });

  testWidgets('configures the shape layer and dispatches marker selection', (
    tester,
  ) async {
    String? selectedCountry;
    const singapore = ProxyCountryMapEntry(
      countryCode: 'SG',
      latitude: 1.35,
      longitude: 103.82,
      nodeCount: 2,
    );

    await tester.pumpWidget(
      PrismApp(
        theme: PrismTheme.light,
        localizationsDelegates: targetLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Surface(
          child: Center(
            child: SizedBox(
              width: 800,
              child: AbstractWorldMap(
                nodes: const [singapore],
                selectedId: 'SG',
                onSelect: (country) => selectedCountry = country,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SfMaps), findsOneWidget);
    final layer = tester.widget<MapShapeLayer>(find.byType(MapShapeLayer));
    expect(layer.initialMarkersCount, 1);
    final zoom = layer.zoomPanBehavior!;
    expect(zoom.enableMouseWheelZooming, isFalse);
    expect(zoom.enableDoubleTapZooming, isTrue);
    final bounds = zoom.latLngBounds!;
    expect(bounds.northeast.latitude, greaterThan(singapore.latitude));
    expect(bounds.northeast.longitude, greaterThan(singapore.longitude));
    expect(bounds.southwest.latitude, lessThan(singapore.latitude));
    expect(bounds.southwest.longitude, lessThan(singapore.longitude));
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Fit map to nodes'), findsOneWidget);
    final marker = layer.markerBuilder!(
      tester.element(find.byType(MapShapeLayer)),
      0,
    );
    expect(marker.latitude, singapore.latitude);
    expect(marker.longitude, singapore.longitude);

    await tester.pumpWidget(
      PrismApp(
        theme: PrismTheme.light,
        localizationsDelegates: targetLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Surface(child: Center(child: marker.child)),
      ),
    );
    expect(find.byType(CountryFlag), findsOneWidget);
    final markerGesture = find.ancestor(
      of: find.byKey(const ValueKey('country-flag-SG')),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(markerGesture);
    expect(selectedCountry, 'SG');
  });
}
