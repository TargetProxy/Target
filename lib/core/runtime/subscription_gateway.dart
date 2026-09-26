/// Subscription data shapes exchanged with the core. The operations themselves
/// live on [CoreGateway]; there is one core, so there is one gateway type.
class RuntimeSubscriptionSnapshot {
  const RuntimeSubscriptionSnapshot({required this.subscriptions});

  final List<RuntimeSubscription> subscriptions;
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
    this.nodeCount = 0,
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

  /// Nodes this subscription contributed. The shared pool itself comes from
  /// the core's node pool, not from per-subscription profiles.
  final int nodeCount;
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
    required this.notModified,
    required this.duration,
    this.originalConfig = '',
    this.generatedConfig = '',
  });

  final RuntimeSubscription subscription;
  final bool notModified;
  final Duration duration;
  final String originalConfig;
  final String generatedConfig;
}
