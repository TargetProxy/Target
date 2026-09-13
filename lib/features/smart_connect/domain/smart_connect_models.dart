import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

enum SmartSelectionMode { automatic, manual, direct }

@immutable
class SmartProbeTarget {
  const SmartProbeTarget({
    required this.url,
    this.expectedStatus = const {200},
    this.bodyContains = '',
    this.egressUrl = '',
    this.serviceCountryHeader = '',
  });
  final String url, bodyContains, egressUrl, serviceCountryHeader;
  final Set<int> expectedStatus;
  Map<String, Object> toJson() => {
    'url': url,
    'expectedStatus': expectedStatus.toList()..sort(),
    'bodyContains': bodyContains,
    'egressUrl': egressUrl,
    'serviceCountryHeader': serviceCountryHeader,
  };
  factory SmartProbeTarget.fromJson(Map<String, dynamic> json) =>
      SmartProbeTarget(
        url: json['url'] as String,
        expectedStatus: {
          ...(json['expectedStatus'] as List? ?? [200]).cast<int>(),
        },
        bodyContains: json['bodyContains'] as String? ?? '',
        egressUrl: json['egressUrl'] as String? ?? '',
        serviceCountryHeader: json['serviceCountryHeader'] as String? ?? '',
      );
}

@immutable
class SmartNode {
  const SmartNode({
    required this.id,
    required this.region,
    this.name = '',
    this.subscriptionId = '',
    this.protocol = '',
    this.observedRegion = '',
    this.serviceRegion = '',
    this.tags = const {},
    this.favorite = false,
    this.subscriptionPriority = 0,
    this.latencyMs,
    this.successRate = 0,
    this.packetLoss,
    this.enabled = true,
    this.excluded = false,
    this.testedAt,
    this.expiresAt,
    this.probePassed = false,
    this.policyRevision = '',
    this.failureReason = '',
  });
  final String id,
      name,
      subscriptionId,
      protocol,
      region,
      observedRegion,
      serviceRegion,
      policyRevision,
      failureReason;
  final Set<String> tags;
  final bool enabled, excluded, favorite, probePassed;
  final int? latencyMs;
  final int subscriptionPriority;
  final double successRate;
  final double? packetLoss;
  final DateTime? testedAt, expiresAt;
  String get effectiveRegion =>
      (observedRegion.isEmpty
              ? (serviceRegion.isEmpty ? region : serviceRegion)
              : observedRegion)
          .toUpperCase();
}

@immutable
class SmartPolicy {
  const SmartPolicy({
    required this.id,
    this.name = '',
    this.domains = const {},
    this.allowedRegions = const {},
    this.preferredRegions = const {},
    this.excludedNodes = const {},
    this.allowedSubscriptions = const {},
    this.requiredTags = const {},
    this.probeTargets = const [],
    this.selectionMode = SmartSelectionMode.automatic,
    this.stickyDuration = const Duration(minutes: 30),
    this.probeValidity = const Duration(minutes: 5),
    this.enabled = true,
  });
  final String id, name;
  final Set<String> domains,
      allowedRegions,
      preferredRegions,
      excludedNodes,
      allowedSubscriptions,
      requiredTags;
  final List<SmartProbeTarget> probeTargets;
  final SmartSelectionMode selectionMode;
  final Duration stickyDuration, probeValidity;
  final bool enabled;
  // Canonical content identity also invalidates results after preference/domain edits.
  String get revision {
    final entries = toJson();
    String canonical(Object? value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return '{${keys.map((k) => '$k:${canonical(value[k])}').join(',')}}';
      }
      if (value is List) return '[${value.map(canonical).join(',')}]';
      return '$value';
    }

    return sha256.convert(utf8.encode(canonical(entries))).toString();
  }

  List<String> validate() {
    final errors = <String>[];
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      errors.add('Service ID must contain only letters, numbers, _ or -');
    }
    if (domains.isEmpty || domains.any((d) => !validSmartDomain(d))) {
      errors.add('Enter valid DNS domains without schemes or paths');
    }
    if ([
      ...allowedRegions,
      ...preferredRegions,
    ].any((r) => !RegExp(r'^[A-Z]{2}$').hasMatch(r))) {
      errors.add('Regions must be uppercase ISO country codes');
    }
    if (stickyDuration <= Duration.zero || probeValidity <= Duration.zero) {
      errors.add('Durations must be positive');
    }
    if (selectionMode != SmartSelectionMode.direct && probeTargets.isEmpty) {
      errors.add('At least one service probe target is required');
    }
    for (final target in probeTargets) {
      if (!validSmartProbeUrl(target.url) ||
          (target.egressUrl.isNotEmpty &&
              !validSmartProbeUrl(target.egressUrl))) {
        errors.add(
          'Probe URLs must be HTTP(S), without credentials or fragments',
        );
      }
      if (target.expectedStatus.isEmpty ||
          target.expectedStatus.any((s) => s < 100 || s > 599)) {
        errors.add('Enter valid expected HTTP status codes');
      }
    }
    return errors;
  }

  Map<String, Object> toJson() {
    List<String> sorted(Set<String> values) => values.toList()..sort();
    return {
      'id': id,
      'name': name,
      'domains': sorted(domains),
      'allowedRegions': sorted(allowedRegions),
      'preferredRegions': sorted(preferredRegions),
      'excludedNodes': sorted(excludedNodes),
      'allowedSubscriptions': sorted(allowedSubscriptions),
      'requiredTags': sorted(requiredTags),
      'probeTargets': probeTargets.map((t) => t.toJson()).toList(),
      'selectionMode': selectionMode.name,
      'stickySeconds': stickyDuration.inSeconds,
      'validitySeconds': probeValidity.inSeconds,
      'enabled': enabled,
    };
  }

  factory SmartPolicy.fromJson(Map<String, dynamic> json) {
    Set<String> strings(String key) => {
      ...(json[key] as List? ?? []).cast<String>(),
    };
    return SmartPolicy(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      domains: strings('domains'),
      allowedRegions: strings('allowedRegions'),
      preferredRegions: strings('preferredRegions'),
      excludedNodes: strings('excludedNodes'),
      allowedSubscriptions: strings('allowedSubscriptions'),
      requiredTags: strings('requiredTags'),
      probeTargets: [
        for (final t in json['probeTargets'] as List? ?? [])
          SmartProbeTarget.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
      selectionMode: SmartSelectionMode.values.byName(
        json['selectionMode'] as String? ?? 'automatic',
      ),
      stickyDuration: Duration(seconds: json['stickySeconds'] as int? ?? 1800),
      probeValidity: Duration(seconds: json['validitySeconds'] as int? ?? 300),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

bool validSmartDomain(String value) =>
    value.length <= 253 &&
    value.isNotEmpty &&
    value
        .split('.')
        .every(
          (label) => RegExp(
            r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
          ).hasMatch(label),
        );
bool validSmartProbeUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment;
}

@immutable
class SmartSelection {
  const SmartSelection({
    this.node,
    required this.reason,
    this.excluded = const {},
    this.scores = const {},
    this.direct = false,
  });
  final SmartNode? node;
  final String reason;
  final Map<String, String> excluded;
  final Map<String, double> scores;
  final bool direct;
  bool get succeeded => direct || node != null;
}

String? policyForDomain(
  String host,
  Map<String, SmartPolicy> policiesByDomain,
) {
  final normalized = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  String? selected;
  var longest = -1;
  for (final entry in policiesByDomain.entries) {
    if (!entry.value.enabled) continue;
    final suffix = entry.key
        .toLowerCase()
        .replaceFirst(RegExp(r'^\.'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    if (validSmartDomain(suffix) &&
        (normalized == suffix || normalized.endsWith('.$suffix')) &&
        suffix.length > longest) {
      selected = entry.key;
      longest = suffix.length;
    }
  }
  return selected;
}

/// Pre-probe filtering never treats a name-derived region as observed evidence.
String? smartCandidateExclusion(SmartPolicy policy, SmartNode node) {
  if (!policy.enabled) return 'policy disabled';
  if (!node.enabled) return 'disabled';
  if (node.excluded || policy.excludedNodes.contains(node.id)) {
    return 'excluded by policy';
  }
  if (policy.allowedSubscriptions.isNotEmpty &&
      !policy.allowedSubscriptions.contains(node.subscriptionId)) {
    return 'subscription not allowed';
  }
  if (!node.tags.containsAll(policy.requiredTags)) {
    return 'required tags missing';
  }
  return null;
}

SmartSelection selectSmartNode(
  SmartPolicy policy,
  Iterable<SmartNode> nodes, {
  DateTime? now,
}) {
  final time = now ?? DateTime.now();
  if (!policy.enabled) return const SmartSelection(reason: 'Policy disabled');
  if (policy.selectionMode == SmartSelectionMode.direct) {
    return const SmartSelection(direct: true, reason: 'Explicit Direct policy');
  }
  final excluded = <String, String>{};
  final scores = <String, double>{};
  final candidates = <SmartNode>[];
  for (final node in nodes) {
    String? reason = smartCandidateExclusion(policy, node);
    if (reason == null &&
        policy.allowedRegions.isNotEmpty &&
        !policy.allowedRegions.contains(node.effectiveRegion)) {
      reason = 'region not allowed';
    }
    if (reason == null &&
        (!node.probePassed ||
            node.successRate <= 0 ||
            !node.successRate.isFinite ||
            node.successRate > 1)) {
      reason = node.failureReason.isEmpty
          ? 'service probe failed'
          : node.failureReason;
    }
    if (reason == null &&
        (node.testedAt == null ||
            node.expiresAt == null ||
            !time.isBefore(node.expiresAt!) ||
            node.testedAt!.isAfter(time))) {
      reason = 'probe missing or expired';
    }
    if (reason == null && node.policyRevision != policy.revision) {
      reason = 'policy changed; re-evaluation required';
    }
    if (reason != null) {
      excluded[node.id] = reason;
      continue;
    }
    candidates.add(node);
    // Display score; selection below preserves the documented priority order.
    scores[node.id] =
        node.successRate * 70 +
        (1 - (node.packetLoss ?? 1).clamp(0, 1)) * 15 +
        10 / (1 + (node.latencyMs ?? 10000) / 100) +
        (node.favorite ? 2 : 0) +
        (policy.preferredRegions.contains(node.effectiveRegion) ? 3 : 0);
  }
  candidates.sort((a, b) {
    final comparisons = [
      (b.observedRegion.isNotEmpty ? 1 : 0).compareTo(
        a.observedRegion.isNotEmpty ? 1 : 0,
      ),
      b.successRate.compareTo(a.successRate),
      (a.packetLoss ?? 1).compareTo(b.packetLoss ?? 1),
      (policy.preferredRegions.contains(b.effectiveRegion) ? 1 : 0).compareTo(
        policy.preferredRegions.contains(a.effectiveRegion) ? 1 : 0,
      ),
      (a.latencyMs ?? 1 << 30).compareTo(b.latencyMs ?? 1 << 30),
      (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0),
      b.subscriptionPriority.compareTo(a.subscriptionPriority),
      a.id.compareTo(b.id),
    ];
    return comparisons.firstWhere((v) => v != 0, orElse: () => 0);
  });
  if (candidates.isEmpty) {
    return SmartSelection(
      reason: 'No eligible node; manual re-evaluation required',
      excluded: excluded,
    );
  }
  final node = candidates.first;
  return SmartSelection(
    node: node,
    scores: scores,
    excluded: excluded,
    reason:
        'All service targets passed; region ${node.effectiveRegion} (${node.observedRegion.isNotEmpty ? "observed exit" : node.serviceRegion.isNotEmpty ? "service response" : "declared"}), success ${(node.successRate * 100).toStringAsFixed(0)}%, latency ${node.latencyMs ?? "unknown"} ms',
  );
}

class SmartNodePreference {
  const SmartNodePreference({
    this.enabled = true,
    this.excluded = false,
    this.favorite = false,
    this.tags = const {},
  });
  final bool enabled, excluded, favorite;
  final Set<String> tags;
  Map<String, Object> toJson() => {
    'enabled': enabled,
    'excluded': excluded,
    'favorite': favorite,
    'tags': tags.toList()..sort(),
  };
  factory SmartNodePreference.fromJson(Map<String, dynamic> json) =>
      SmartNodePreference(
        enabled: json['enabled'] as bool? ?? true,
        excluded: json['excluded'] as bool? ?? false,
        favorite: json['favorite'] as bool? ?? false,
        tags: {...(json['tags'] as List? ?? []).cast<String>()},
      );
}

