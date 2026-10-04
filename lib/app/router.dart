import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/connections/presentation/connections_page.dart';
import '../features/home/home_page.dart';
import '../features/logs/presentation/logs_page.dart';
import '../features/profiles/presentation/profiles_workspace_page.dart';
import '../features/traffic/presentation/traffic_page.dart';
import '../features/proxies/presentation/node_pool_page.dart';
import '../features/rules/presentation/rules_page.dart';
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
            pageBuilder: _pageBuilder(const HomePage()),
          ),
          GoRoute(
            path: AppRoute.proxies.path,
            pageBuilder: _pageBuilder(const ProfilesWorkspacePage()),
          ),
          GoRoute(
            path: AppRoute.nodes.path,
            pageBuilder: _pageBuilder(const NodePoolPage()),
          ),
          GoRoute(
            path: AppRoute.rules.path,
            pageBuilder: _pageBuilder(const RulesPage()),
          ),
          GoRoute(
            path: '/node-library',
            redirect: (_, _) => AppRoute.nodes.path,
          ),
          GoRoute(
            path: AppRoute.connections.path,
            pageBuilder: _pageBuilder(const ConnectionsPage()),
          ),
          GoRoute(
            path: AppRoute.traffic.path,
            pageBuilder: _pageBuilder(const TrafficPage()),
          ),
          GoRoute(
            path: AppRoute.logs.path,
            pageBuilder: _pageBuilder(const LogsPage()),
          ),
        ],
      ),
    ],
  );

  static Page<void> Function(BuildContext, GoRouterState) _pageBuilder(
    Widget child,
  ) {
    return (context, state) =>
        NoTransitionPage<void>(key: state.pageKey, child: child);
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
