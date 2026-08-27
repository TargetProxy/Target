import '../../data/models/proxy_group.dart';
import '../../data/models/proxy_node.dart';

class RuntimeSubscriptionSnapshot {
  const RuntimeSubscriptionSnapshot({
    required this.subscriptions,
    required this.activeId,
  });

  final List<RuntimeSubscription> subscriptions;
  final String? activeId;
}

enum RuntimeSubscriptionStatus { idle, updating, ready, failed }

class RuntimeSubscription {
  const RuntimeSubscription({
    required this.id,
    required this.name,
    required this.source,
    required this.enabled,
    required this.autoUpdate,
    required this.updateIntervalSeconds,
    required this.status,
    this.profile = const RuntimeProfile(),
    this.errorCode,
    this.errorMessage,
    this.updatedAt,
    this.expiresAt,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes,
    this.title,
    this.webPageUrl,
    this.supportUrl,
    this.movedPermanentlyTo,
  });

  final String id;
  final String name;
  final String source;
  final bool enabled;
  final bool autoUpdate;
  final int updateIntervalSeconds;
  final RuntimeSubscriptionStatus status;
  final RuntimeProfile profile;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final int uploadBytes;
  final int downloadBytes;
  final int? totalBytes;
  final String? title;
  final String? webPageUrl;
  final String? supportUrl;
  final String? movedPermanentlyTo;
}

class RuntimeProfile {
  const RuntimeProfile({this.nodes = const [], this.groups = const []});

  final List<ProxyNode> nodes;

  /// Client-owned runtime selector groups built from TargetLib's node-only
  /// profile view.
  final List<ProxyGroup> groups;
}

class RuntimeSubscriptionUpdate {
  const RuntimeSubscriptionUpdate({
    required this.subscription,
    required this.changed,
    required this.notModified,
    required this.duration,
    this.originalConfig = '',
    this.generatedConfig = '',
  });

  final RuntimeSubscription subscription;
  final bool changed;
  final bool notModified;
  final Duration duration;
  final String originalConfig;
  final String generatedConfig;
}

abstract interface class SubscriptionGateway {
  Stream<void> get subscriptionChanges;

  Future<RuntimeSubscriptionSnapshot> listSubscriptions();

  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
    bool activate = false,
    bool updateNow = false,
  });

  Future<void> removeSubscription(String id);

  Future<RuntimeSubscription> renameSubscription(String id, String name);

  Future<RuntimeSubscriptionUpdate> updateSubscription(String id);

  /// Selects the subscription used by TargetLib runtime configuration.
  Future<void> activateSubscription(String? id);
}
