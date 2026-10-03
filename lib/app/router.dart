import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/connections/presentation/connections_page.dart';
import '../features/home/home_page.dart';
import '../features/logs/presentation/logs_page.dart';
import '../features/profiles/presentation/profiles_workspace_page.dart';
import '../features/traffic/presentation/traffic_page.dart';
import '../features/proxies/presentation/node_pool_page.dart';
import '../features/rules/presentation/rules_page.dart';
import '../core/theme/app_motion.dart';
import 'shell/app_shell.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoute.home.path,
            pageBuilder: _fadePageBuilder(const HomePage()),
          ),
          GoRoute(
            path: AppRoute.proxies.path,
            pageBuilder: _fadePageBuilder(const ProfilesWorkspacePage()),
          ),
          GoRoute(
            path: AppRoute.nodes.path,
            pageBuilder: _fadePageBuilder(const NodePoolPage()),
          ),
          GoRoute(
            path: AppRoute.rules.path,
            pageBuilder: _fadePageBuilder(const RulesPage()),
          ),
          GoRoute(
            path: '/node-library',
            redirect: (_, _) => AppRoute.nodes.path,
          ),
          GoRoute(
            path: AppRoute.connections.path,
            pageBuilder: _fadePageBuilder(const ConnectionsPage()),
          ),
          GoRoute(
            path: AppRoute.traffic.path,
            pageBuilder: _fadePageBuilder(const TrafficPage()),
          ),
          GoRoute(
            path: AppRoute.logs.path,
            pageBuilder: _fadePageBuilder(const LogsPage()),
          ),
        ],
      ),
    ],
  );

  static Page<void> Function(BuildContext, GoRouterState) _fadePageBuilder(
    Widget child,
  ) {
    return (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.standard,
      reverseTransitionDuration: AppMotion.standard,
      transitionsBuilder: (context, animation, _, child) {
        if (AppMotion.reduced(context)) {
          return child;
        }
        final transition = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.5, 1, curve: AppMotion.easeOut),
        );
        return FadeTransition(
          opacity: transition,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.018, 0),
              end: Offset.zero,
            ).animate(transition),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(transition),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

enum AppRoute {
  home('/'),
  proxies('/proxies'),
  nodes('/nodes'),
  rules('/rules'),
  connections('/connections'),
  traffic('/traffic'),
  logs('/logs');

  const AppRoute(this.path);

  final String path;
}
