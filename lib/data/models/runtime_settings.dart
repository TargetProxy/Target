import 'package:flutter/foundation.dart';

enum ProxyMode {
  mixed,
  tun;

  String get label => switch (this) {
    ProxyMode.mixed => 'Mixed',
    ProxyMode.tun => 'TUN',
  };
}

enum RouteMode {
  all,
  rule,
  direct;

  String get label => switch (this) {
    RouteMode.all => 'All',
    RouteMode.rule => 'Rule',
    RouteMode.direct => 'Direct',
  };
}

@immutable
class RuntimeSettings {
  const RuntimeSettings({
    this.listenAddress = '127.0.0.1',
    this.mixedPort = 2080,
    this.proxyMode = ProxyMode.mixed,
    this.routeMode = RouteMode.rule,
    this.ipv6 = false,
  });

  final String listenAddress;
  final int mixedPort;
  final ProxyMode proxyMode;
  final RouteMode routeMode;
  final bool ipv6;

  RuntimeSettings copyWith({
    String? listenAddress,
    int? mixedPort,
    ProxyMode? proxyMode,
    RouteMode? routeMode,
    bool? ipv6,
  }) => RuntimeSettings(
    listenAddress: listenAddress ?? this.listenAddress,
    mixedPort: mixedPort ?? this.mixedPort,
    proxyMode: proxyMode ?? this.proxyMode,
    routeMode: routeMode ?? this.routeMode,
    ipv6: ipv6 ?? this.ipv6,
  );
}
