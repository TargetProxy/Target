import 'package:flutter/foundation.dart';

import '../../data/models/proxy_group.dart';

enum CoreLifecycle { unavailable, stopped, starting, running, stopping, failed }

@immutable
class TrafficSnapshot {
  const TrafficSnapshot({
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.activeConnections = 0,
  });

  final int uploadBytes;
  final int downloadBytes;
  final int activeConnections;

  static const zero = TrafficSnapshot();
}

enum CoreLatencyStatus { success, failed, timeout, notFound }

@immutable
class CoreLatencyResult {
  const CoreLatencyResult({
    required this.outboundId,
    required this.status,
    this.delayMilliseconds,
    this.testedAt,
    this.errorMessage = '',
  });

  final String outboundId;
  final CoreLatencyStatus status;
  final int? delayMilliseconds;
  final DateTime? testedAt;
  final String errorMessage;

  bool get succeeded => status == CoreLatencyStatus.success;
}

@immutable
class CoreConnection {
  const CoreConnection({
    required this.id,
    required this.destination,
    this.domain = '',
    this.outbound = '',
    this.network = '',
    this.protocol = '',
    this.uplinkTotal = 0,
    this.downlinkTotal = 0,
    this.createdAt = 0,
    this.closedAt = 0,
  });

  final String id;
  final String destination;
  final String domain;
  final String outbound;
  final String network;
  final String protocol;
  final int uplinkTotal;
  final int downlinkTotal;
  final int createdAt;
  final int closedAt;
}

@immutable
class CoreSnapshot {
  const CoreSnapshot({
    this.lifecycle = CoreLifecycle.stopped,
    this.message = '',
    this.traffic = TrafficSnapshot.zero,
    this.connections = const [],
    this.proxyGroups = const [],
  });

  final CoreLifecycle lifecycle;
  final String message;
  final TrafficSnapshot traffic;
  final List<CoreConnection> connections;
  final List<ProxyGroup> proxyGroups;
}
