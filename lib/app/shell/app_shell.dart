import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../app_identity.dart';
import '../router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFor(location);

    return AdaptiveScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        context.go(_navigationRoutes[index].path);
      },
      child: child,
    );
  }

  static const _navigationRoutes = [
    AppRoute.home,
    AppRoute.proxies,
    AppRoute.connections,
    AppRoute.traffic,
    AppRoute.logs,
  ];

  int _selectedIndexFor(String location) {
    final index = _navigationRoutes.indexWhere((route) {
      if (route.path == AppRoute.home.path) {
        return location == route.path;
      }
      return location.startsWith(route.path);
    });
    return index < 0 ? 0 : index;
  }
}

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.hub_outlined),
      selectedIcon: Icon(Icons.hub),
      label: 'Profiles',
    ),
    NavigationDestination(
      icon: Icon(Icons.cable_outlined),
      selectedIcon: Icon(Icons.cable),
      label: 'Connections',
    ),
    NavigationDestination(
      icon: Icon(Icons.show_chart),
      selectedIcon: Icon(Icons.show_chart),
      label: 'Traffic',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Logs',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                _DesktopSidebar(
                  selectedIndex: selectedIndex,
                  onSelect: onDestinationSelected,
                ),
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
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(int index, String label, IconData icon) => ListTile(
      dense: true,
      selected: selectedIndex == index,
      leading: Icon(icon, size: 20),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => onSelect(index),
    );
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 20),
                child: _BrandMark(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 6),
                child: Text(
                  'WORKSPACE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              item(0, 'Dashboard', Icons.dashboard_outlined),
              item(1, 'Profiles', Icons.hub_outlined),
              item(2, 'Connections', Icons.cable_outlined),
              item(3, 'Traffic', Icons.show_chart),
              item(4, 'Logs', Icons.receipt_long_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: AppIdentity.displayName,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'T',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
