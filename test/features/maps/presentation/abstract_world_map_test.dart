import 'package:country_flags/country_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:target/features/maps/application/proxy_country_map.dart';
import 'package:target/features/maps/presentation/widgets/abstract_world_map.dart';
import 'package:target/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

void main() {
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 800)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SfMaps), findsOneWidget);
    final layer = tester.widget<MapShapeLayer>(find.byType(MapShapeLayer));
    expect(layer.initialMarkersCount, 1);
    expect(layer.zoomPanBehavior, isNotNull);
    expect(layer.zoomPanBehavior!.enableMouseWheelZooming, isFalse);
    expect(layer.zoomPanBehavior!.enableDoubleTapZooming, isTrue);
    final bounds = layer.zoomPanBehavior!.latLngBounds!;
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: marker.child)),
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
