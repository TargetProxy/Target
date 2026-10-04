import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../app_identity.dart';
import '../router.dart';
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
            body: Row(
              children: [
                _buildDesktopSidebar(context, selectedIndex),
                const VerticalDivider(width: 1),
                Expanded(child: child),
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

  Widget _buildDesktopSidebar(BuildContext context, int selectedIndex) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 20),
                child: Text(
                  AppIdentity.displayName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (var i = 0; i < items.length; i++)
                Builder(
                  builder: (context) {
                    final item = items[i];
                    final selected = selectedIndex == i;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: colors.secondaryContainer,
                      leading: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: selected
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? colors.onSecondaryContainer
                              : colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () => onDestinationSelected(i),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
