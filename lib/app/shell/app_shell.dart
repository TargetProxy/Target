import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:prism_ui/prism_ui.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../../core/ui/app_glyphs.dart';
import '../../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  /// The shell's destinations and their order. Both the selected index and the
  /// navigation callback resolve through this single list, so destinations can
  /// never drift apart from the routes they navigate to.
  static const _destinations = [
    AppRoute.home,
    AppRoute.proxies,
    AppRoute.nodes,
    AppRoute.rules,
    AppRoute.connections,
    AppRoute.logs,
  ];

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _selectedIndex();

    return _NavigationScaffold(
      selectedIndex: selectedIndex,
      scrollUnderDock: location == AppRoute.home.path,
      onDestinationSelected: (index) => context.go(_destinations[index].path),
      items: [for (final route in _destinations) _destinationItem(route, l10n)],
      child: child,
    );
  }

  int _selectedIndex() {
    final index = _destinations.indexWhere((route) {
      return route.path == AppRoute.home.path
          ? location == route.path
          : location.startsWith(route.path);
    });
    return index < 0 ? 0 : index;
  }
}

typedef _NavigationItem = ({String label, Glyph glyph});

_NavigationItem _destinationItem(AppRoute route, AppLocalizations l10n) =>
    switch (route) {
      AppRoute.home => (label: l10n.dashboard, glyph: AppGlyphs.dashboard),
      AppRoute.proxies => (label: l10n.profiles, glyph: AppGlyphs.profiles),
      AppRoute.nodes => (label: l10n.nodeSelection, glyph: AppGlyphs.proxies),
      AppRoute.rules => (label: l10n.rules, glyph: AppGlyphs.rules),
      AppRoute.connections => (label: l10n.connections, glyph: AppGlyphs.connections),
      AppRoute.logs => (label: l10n.logs, glyph: AppGlyphs.logs),
    };

class _NavigationScaffold extends StatefulWidget {
  const _NavigationScaffold({
    required this.selectedIndex,
    required this.scrollUnderDock,
    required this.onDestinationSelected,
    required this.child,
    required this.items,
  });

  final int selectedIndex;
  final bool scrollUnderDock;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final List<_NavigationItem> items;

  @override
  State<_NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends State<_NavigationScaffold> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      body: Surface(
        color: SurfaceLevel.page.colorOf(context.colorScheme),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 600;
            if (!isMobile) {
              final canExpand = constraints.maxWidth > 840;
              return Row(
                children: [
                  NavigationSidebar(
                    destinations: [
                      for (final item in widget.items)
                        SidebarDestination(glyph: item.glyph, label: item.label),
                    ],
                    selectedIndex: widget.selectedIndex,
                    expanded: canExpand && _expanded,
                    onSelected: widget.onDestinationSelected,
                    onToggle: canExpand
                        ? () => setState(() => _expanded = !_expanded)
                        : null,
                  ),
                  Expanded(child: widget.child),
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: BottomInsetScope(
                    inset: widget.scrollUnderDock ? NavigationDock.insetOf(context) : 0,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: widget.scrollUnderDock ? 0 : NavigationDock.insetOf(context),
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: NavigationDock(
                    destinations: [
                      for (final item in widget.items)
                        NavigationDockDestination(
                          glyph: item.glyph,
                          label: item.label,
                        ),
                    ],
                    selectedIndex: widget.selectedIndex,
                    onSelected: widget.onDestinationSelected,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
