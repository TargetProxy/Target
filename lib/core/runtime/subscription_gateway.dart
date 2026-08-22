import '../../data/models/proxy_node.dart';

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
    this.nodes = const [],
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
  final List<ProxyNode> nodes;
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

class RuntimeSubscriptionUpdate {
  const RuntimeSubscriptionUpdate({
    required this.subscription,
    required this.changed,
    required this.notModified,
    required this.duration,
  });

  final RuntimeSubscription subscription;
  final bool changed;
  final bool notModified;
  final Duration duration;
}

abstract interface class SubscriptionGateway {
  Stream<void> get subscriptionChanges;

  Future<List<RuntimeSubscription>> listSubscriptions();

  Future<RuntimeSubscription> addSubscription({
    required String id,
    required String name,
    required String url,
    required bool enabled,
    required bool autoUpdate,
    required int updateIntervalSeconds,
    required Map<String, String> headers,
  });

  Future<void> removeSubscription(String id);
  Future<RuntimeSubscription> renameSubscription(String id, String name);
  Future<RuntimeSubscription> setSubscriptionEnabled(String id, bool enabled);
  Future<RuntimeSubscriptionUpdate> updateSubscription(String id);

  /// Selects the subscription used by TargetLib BuildConfig. The state is
  /// persisted by the backend; [activeSubscriptionId] reads it back.
  Future<void> activateSubscription(String? id);
  Future<String?> activeSubscriptionId();
}
