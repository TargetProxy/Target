import 'package:flutter/foundation.dart';

enum SmartSelectionMode { automatic, manual, direct, followDefault }

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

/// A service routing policy. The core owns the authoritative copy once the
/// policy is synced; the local store keeps the editable document and the two
/// fields the core contract has no home for ([selectionMode] beyond
/// Direct/Manual, and [enabled]).
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
      allowedSubscriptions;
  final List<SmartProbeTarget> probeTargets;
  final SmartSelectionMode selectionMode;
  final Duration stickyDuration, probeValidity;
  final bool enabled;

  SmartPolicy copyWith({SmartSelectionMode? selectionMode, bool? enabled}) =>
      SmartPolicy(
        id: id,
        name: name,
        domains: domains,
        allowedRegions: allowedRegions,
        preferredRegions: preferredRegions,
        excludedNodes: excludedNodes,
        allowedSubscriptions: allowedSubscriptions,
        probeTargets: probeTargets,
        selectionMode: selectionMode ?? this.selectionMode,
        stickyDuration: stickyDuration,
        probeValidity: probeValidity,
        enabled: enabled ?? this.enabled,
      );

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
    if (selectionMode == SmartSelectionMode.automatic && probeTargets.isEmpty) {
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

/// Policies available on a new installation. They are ordinary local data,
/// so users can edit or remove them without changing the runtime contract.
const defaultSmartPolicies = <SmartPolicy>[
  SmartPolicy(
    id: 'chatgpt',
    name: 'ChatGPT',
    selectionMode: SmartSelectionMode.followDefault,
    domains: {'chatgpt.com', 'openai.com'},
    allowedRegions: {'SG', 'JP', 'US'},
    preferredRegions: {'SG'},
    probeTargets: [
      SmartProbeTarget(
        url: 'https://chatgpt.com/',
        egressUrl: 'https://api.country.is/',
      ),
    ],
  ),
  SmartPolicy(
    id: 'disney',
    name: 'Disney+',
    selectionMode: SmartSelectionMode.followDefault,
    domains: {'disneyplus.com'},
    allowedRegions: {'US'},
    probeTargets: [
      SmartProbeTarget(
        url: 'https://www.disneyplus.com/',
        egressUrl: 'https://api.country.is/',
      ),
    ],
  ),
  SmartPolicy(
    id: 'youtube',
    name: 'YouTube',
    selectionMode: SmartSelectionMode.followDefault,
    domains: {'youtube.com', 'googlevideo.com'},
    preferredRegions: {'JP'},
    probeTargets: [
      SmartProbeTarget(
        url: 'https://www.youtube.com/',
        egressUrl: 'https://api.country.is/',
      ),
    ],
  ),
  SmartPolicy(
    id: 'direct',
    name: 'Direct',
    domains: {'example.cn'},
    selectionMode: SmartSelectionMode.direct,
  ),
];

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
