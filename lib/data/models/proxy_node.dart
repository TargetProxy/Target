import 'package:flutter/foundation.dart';

/// The single node model. Runtime pool data, latency results and Smart Connect
/// preferences all describe the same node, so they share one type.
@immutable
class ProxyNode {
  const ProxyNode({
    required this.id,
    required this.name,
    required this.type,
    this.subscriptionId = '',
    this.countryCode,
    this.observedCountryCode = '',
    this.server = '',
    this.port = 0,
    this.errorMessage = '',
    this.latencyMs,
    this.latencyTimedOut = false,
    this.testedAt,
    this.failureReason = '',
    this.isSelected = false,
    this.isAvailable = true,
    this.enabled = true,
    this.excluded = false,
    this.favorite = false,
    this.tags = const {},
    this.subscriptionPriority = 0,
  });

  final String id;
  final String name;
  final String type;
  final String subscriptionId;
  final String? countryCode;

  /// Region measured by a probe, which overrides the declared one.
  final String observedCountryCode;
  final String server;
  final int port;
  final String errorMessage;
  final int? latencyMs;
  final bool latencyTimedOut;
  final DateTime? testedAt;
  final String failureReason;
  final bool isSelected;
  final bool isAvailable;
  final bool enabled;
  final bool excluded;
  final bool favorite;
  final Set<String> tags;
  final int subscriptionPriority;

  String get typeLabel => type.toUpperCase();

  String get displayName => name.isEmpty ? id : name;

  String get effectiveCountryCode =>
      (observedCountryCode.isEmpty ? countryCode ?? '' : observedCountryCode)
          .toUpperCase();

  String get effectiveRegion => effectiveCountryCode;

  bool get hasLatencyResult => latencyMs != null || latencyTimedOut;

  ProxyNode copyWith({
    String? name,
    String? type,
    String? subscriptionId,
    String? countryCode,
    String? observedCountryCode,
    int? latencyMs,
    bool? latencyTimedOut,
    DateTime? testedAt,
    String? failureReason,
    bool? isSelected,
    bool? isAvailable,
    bool? enabled,
    bool? excluded,
    bool? favorite,
    Set<String>? tags,
    int? subscriptionPriority,
  }) {
    return ProxyNode(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      countryCode: countryCode ?? this.countryCode,
      observedCountryCode: observedCountryCode ?? this.observedCountryCode,
      server: server,
      port: port,
      errorMessage: errorMessage,
      latencyMs: latencyMs ?? this.latencyMs,
      latencyTimedOut: latencyTimedOut ?? this.latencyTimedOut,
      testedAt: testedAt ?? this.testedAt,
      failureReason: failureReason ?? this.failureReason,
      isSelected: isSelected ?? this.isSelected,
      isAvailable: isAvailable ?? this.isAvailable,
      enabled: enabled ?? this.enabled,
      excluded: excluded ?? this.excluded,
      favorite: favorite ?? this.favorite,
      tags: tags ?? this.tags,
      subscriptionPriority: subscriptionPriority ?? this.subscriptionPriority,
    );
  }
}

/// Smart Connect node preferences, owned by the core.
@immutable
class NodePreference {
  const NodePreference({
    this.enabled = true,
    this.excluded = false,
    this.favorite = false,
    this.tags = const {},
    this.subscriptionPriority = 0,
  });

  final bool enabled;
  final bool excluded;
  final bool favorite;
  final Set<String> tags;
  final int subscriptionPriority;
}
