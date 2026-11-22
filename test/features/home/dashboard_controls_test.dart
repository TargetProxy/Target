import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:target/core/platform/app_platform.dart';
import 'package:target/core/runtime/core_notifier.dart';
import 'package:target/core/ui/prism_theme.dart';
import 'package:target/core/ui/ui_localizations.dart';
import 'package:target/data/models/app_settings.dart';
import 'package:target/data/models/runtime_settings.dart';
import 'package:target/features/home/presentation/dashboard/card.dart';
import 'package:target/features/home/presentation/dashboard/layout.dart';
import 'package:target/features/home/presentation/dashboard/network_takeover.dart';
import 'package:target/features/home/presentation/dashboard/outbound_mode.dart';
import 'package:target/l10n/app_localizations.dart';

void main() {
  for (final desktop in [false, true]) {
    testWidgets(
      'dashboard controls stay stable while busy (desktop: $desktop)',
      (tester) async {
        var core = const CoreState(available: true);
        var settings = const AppSettings();
        final requests = <Object>[];
        late StateSetter redraw;

        await tester.pumpWidget(
          prism.PrismApp(
            theme: desktop ? PrismTheme.dark : PrismTheme.light,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              TargetUiLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: StatefulBuilder(
              builder: (context, setState) {
                redraw = setState;
                void request(Object value) => setState(() {
                  requests.add(value);
                  core = core.copyWith(busy: true);
                });
                void changeSystemProxy(bool value) => setState(() {
                  requests.add(value);
                  settings = settings.copyWith(systemProxy: value);
                });
                return DashboardDensityScope(
                  density: desktop
                      ? DashboardDensity.standard
                      : DashboardDensity.mobile,
                  scale: 1,
                  child: Center(
                    child: SizedBox(
                      width: desktop ? 680 : 360,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (desktop) ...[
                            for (final kind in TakeoverSwitch.values)
                              SizedBox(
                                height: 68,
                                child: NetworkTakeoverTile(
                                  kind,
                                  core: core,
                                  settings: settings,
                                  capabilities: const AppCapabilities(
                                    AppPlatform.windows,
                                  ),
                                  onProxyModeChanged: request,
                                  onSystemProxyChanged: changeSystemProxy,
                                ),
                              ),
                            SizedBox(
                              height: 68,
                              child: OutboundModeBar(
                                core: core,
                                onChanged: request,
                              ),
                            ),
                          ] else ...[
                            NetworkTakeoverCard(
                              core: core,
                              settings: settings,
                              capabilities: const AppCapabilities(
                                AppPlatform.windows,
                              ),
                              onProxyModeChanged: request,
                              onSystemProxyChanged: changeSystemProxy,
                            ),
                            OutboundModeCard(core: core, onChanged: request),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        Finder switchNamed(String label) => find.byWidgetPredicate(
          (widget) => widget is prism.Switch && widget.semanticLabel == label,
        );
        Color switchTrack(Finder finder) {
          final track = find
              .descendant(
                of: finder,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is DecoratedBox &&
                      widget.decoration is ShapeDecoration,
                ),
              )
              .first;
          return (tester.widget<DecoratedBox>(track).decoration
                  as ShapeDecoration)
              .color!;
        }

        ({Color foreground, Color background}) routeColors(String label) {
          final text = find.text(label);
          final button = find.ancestor(
            of: text,
            matching: find.byType(DashboardConnectedButton),
          );
          final fill = find
              .descendant(
                of: button,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container &&
                      widget.decoration is ShapeDecoration,
                ),
              )
              .first;
          return (
            foreground: tester.widget<Text>(text).style!.color!,
            background:
                (tester.widget<Container>(fill).decoration! as ShapeDecoration)
                    .color!,
          );
        }

        final tun = switchNamed('TUN');
        final proxy = switchNamed('System proxy');
        await tester.tap(proxy);
        await tester.pumpAndSettle();
        expect(tester.widget<prism.Switch>(proxy).value, isFalse);

        final tunState = tester.state(tun);
        final proxyState = tester.state(proxy);
        final tunTrack = switchTrack(tun);
        final proxyTrack = switchTrack(proxy);
        final all = find.text('All');
        final initialAll = routeColors('All');

        await tester.tap(tun);
        await tester.pump();
        expect(tester.widget<prism.Switch>(tun).value, isFalse);
        expect(tester.state(tun), same(tunState));
        expect(tester.state(proxy), same(proxyState));
        expect(switchTrack(tun), tunTrack);
        expect(switchTrack(proxy), proxyTrack);
        expect(routeColors('All'), initialAll);
        for (final control in [tun, proxy, all]) {
          await tester.tap(control, warnIfMissed: false);
        }
        expect(requests, [false, ProxyMode.tun]);

        redraw(
          () => core = core.copyWith(
            busy: false,
            settings: core.settings.copyWith(proxyMode: ProxyMode.tun),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<prism.Switch>(tun).value, isTrue);
        expect(tester.state(tun), same(tunState));

        await tester.tap(all);
        await tester.pump();
        expect(requests, [false, ProxyMode.tun, RouteMode.all]);
        expect(routeColors('All'), initialAll);

        redraw(
          () => core = core.copyWith(
            busy: false,
            settings: core.settings.copyWith(routeMode: RouteMode.all),
          ),
        );
        await tester.pump();
        expect(routeColors('All'), initialAll);

        for (var frame = 0; frame < 15; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          for (final label in ['Rule', 'All']) {
            final colors = routeColors(label);
            final foreground = colors.foreground.computeLuminance();
            final background = colors.background.computeLuminance();
            final contrast =
                (math.max(foreground, background) + 0.05) /
                (math.min(foreground, background) + 0.05);
            expect(contrast, greaterThanOrEqualTo(4.5));
          }
        }
        expect(routeColors('All').background, isNot(initialAll.background));
      },
    );
  }
}
