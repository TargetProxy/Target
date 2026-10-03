import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../app_identity.dart';
import '../router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/app_animate.dart';

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
    AppRoute.nodes,
    AppRoute.rules,
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

typedef _Destination = ({String label, IconData icon, IconData selectedIcon});

List<_Destination> _destinations(AppLocalizations l10n) => [
  (
    label: l10n.dashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  (label: l10n.profiles, icon: Icons.hub_outlined, selectedIcon: Icons.hub),
  (
    label: l10n.nodeSelection,
    icon: Icons.alt_route,
    selectedIcon: Icons.alt_route,
  ),
  (
    label: l10n.rules,
    icon: Icons.rule_folder_outlined,
    selectedIcon: Icons.rule_folder,
  ),
  (
    label: l10n.connections,
    icon: Icons.cable_outlined,
    selectedIcon: Icons.cable,
  ),
  (label: l10n.traffic, icon: Icons.show_chart, selectedIcon: Icons.show_chart),
  (
    label: l10n.logs,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
];

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
            destinations: [
              for (final destination in _destinations(
                AppLocalizations.of(context),
              ))
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
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
    final destinations = _destinations(AppLocalizations.of(context));

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
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
              for (var index = 0; index < destinations.length; index++)
                _SidebarItem(
                  index: index,
                  destination: destinations[index],
                  selected: selectedIndex == index,
                  onSelect: onSelect,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.index,
    required this.destination,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final _Destination destination;
  final bool selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(10);
    final titleStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
          color: selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: Colors.transparent,
          leading: _SidebarIcon(destination: destination, selected: selected),
          title: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            curve: AppMotion.easeOut,
            style: titleStyle,
            child: Text(destination.label),
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          onTap: () => onSelect(index),
        ),
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({required this.destination, required this.selected});

  final _Destination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = selected ? destination.selectedIcon : destination.icon;
    final color = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: Icon(icon, key: ValueKey(icon), size: 20, color: color),
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
      child: AppAnimate(
        effects: [
          FadeEffect(duration: AppMotion.emphasized, curve: AppMotion.easeOut),
          ScaleEffect(
            duration: AppMotion.emphasized,
            curve: AppMotion.emphasizedCurve,
            begin: const Offset(0.7, 0.7),
          ),
          ShimmerEffect(
            delay: const Duration(milliseconds: 240),
            duration: const Duration(milliseconds: 700),
            color: colorScheme.onPrimary.withValues(alpha: 0.5),
            padding: 0,
          ),
        ],
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
      ),
    );
  }
}
