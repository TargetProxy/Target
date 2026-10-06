import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../app_identity.dart';
import '../router.dart';
import '../../features/connections/presentation/widgets/connections_sidebar.dart';
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
    AppRoute.traffic,
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

typedef _NavigationItem = ({
  String label,
  IconData icon,
  IconData selectedIcon,
});

_NavigationItem _destinationItem(AppRoute route, AppLocalizations l10n) {
  return switch (route) {
    AppRoute.home => (
      label: l10n.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AppRoute.proxies => (
      label: l10n.profiles,
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
    ),
    AppRoute.nodes => (
      label: l10n.nodeSelection,
      icon: Icons.alt_route,
      selectedIcon: Icons.alt_route,
    ),
    AppRoute.rules => (
      label: l10n.rules,
      icon: Icons.rule_folder_outlined,
      selectedIcon: Icons.rule_folder,
    ),
    AppRoute.connections => (
      label: l10n.connections,
      icon: Icons.cable_outlined,
      selectedIcon: Icons.cable,
    ),
    AppRoute.traffic => (
      label: l10n.traffic,
      icon: Icons.show_chart,
      selectedIcon: Icons.show_chart,
    ),
    AppRoute.logs => (
      label: l10n.logs,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
  };
}

class _NavigationScaffold extends StatelessWidget {
  const _NavigationScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final List<_NavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktop = constraints.maxWidth >= 720;

        if (useDesktop) {
          return Scaffold(
            body: Column(
              children: [
                _TopToolbar(
                  selectedIndex: selectedIndex,
                  items: items,
                  onDestinationSelected: onDestinationSelected,
                ),
                Expanded(
                  child: Row(
                    children: [
                      ConnectionsSidebar(
                        onOpenConnections: () =>
                            context.go(AppRoute.connections.path),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TopToolbar extends StatelessWidget {
  const _TopToolbar({
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<_NavigationItem> items;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final visibleCount = items.length < 4 ? items.length : 4;
    final selected = selectedIndex < visibleCount ? {selectedIndex} : <int>{};
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text(AppIdentity.displayName),
      actions: [
        SegmentedButton<int>(
          segments: [
            for (var i = 0; i < visibleCount; i++)
              ButtonSegment<int>(
                value: i,
                icon: Icon(items[i].icon, size: 18),
                label: Text(items[i].label),
              ),
          ],
          selected: selected,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          onSelectionChanged: (values) {
            if (values.isNotEmpty) onDestinationSelected(values.first);
          },
        ),
        if (items.length > visibleCount)
          PopupMenuButton<int>(
            tooltip: Localizations.localeOf(context).languageCode == 'zh'
                ? '更多'
                : 'More',
            onSelected: onDestinationSelected,
            itemBuilder: (context) => [
              for (var i = visibleCount; i < items.length; i++)
                PopupMenuItem<int>(
                  value: i,
                  child: Row(
                    children: [
                      Icon(items[i].icon),
                      const SizedBox(width: 12),
                      Text(items[i].label),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(width: 12),
      ],
    );
  }
}
