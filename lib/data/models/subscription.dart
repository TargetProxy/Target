import 'package:flutter/foundation.dart';

enum SubscriptionFormat {
  auto,
  clashYaml,
  singBoxJson,
  v2rayBase64,
  surgeConf,
  quantumultX,
  unknown,
}

enum SubscriptionUpdateStatus { idle, updating, updated, noChange, failed }

class SubscriptionRequestDefaults {
  const SubscriptionRequestDefaults._();

  // Match SFM/SFI's versioned User-Agent so providers can select a config
  // compatible with the embedded sing-box runtime.
  static const userAgent =
      'SFM/0.2.0 (Build 0.2.0; sing-box 1.13.19; language zh_CN)';

  static const headers = <String, String>{
    'Accept': '*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };
}

@immutable
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.formatHint = SubscriptionFormat.auto,
    this.updateStatus = SubscriptionUpdateStatus.idle,
    this.autoUpdate = true,
    this.updateIntervalSeconds = 43200,
    this.headers = const {},
    this.userAgent = SubscriptionRequestDefaults.userAgent,
    this.allowInsecureHttp = false,
    this.lastUpdatedAt,
    this.expiresAt,
    this.lastEtag,
    this.lastModified,
    this.activeProfileId,
    this.profileTitle,
    this.webPageUrl,
    this.supportUrl,
    this.movedPermanentlyTo,
    this.lastError,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes,
    this.nodeCount = 0,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String url;
  final SubscriptionFormat formatHint;
  final SubscriptionUpdateStatus updateStatus;
  final bool autoUpdate;
  final int updateIntervalSeconds;
  final Map<String, String> headers;
  final String userAgent;
  final bool allowInsecureHttp;
  final DateTime? lastUpdatedAt;
  final DateTime? expiresAt;
  final String? lastEtag;
  final DateTime? lastModified;
  final String? activeProfileId;
  final String? profileTitle;
  final String? webPageUrl;
  final String? supportUrl;
  final String? movedPermanentlyTo;
  final String? lastError;
  final int uploadBytes;
  final int downloadBytes;
  final int? totalBytes;
  final int nodeCount;
  final bool enabled;

  double? get usagePercent {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (uploadBytes + downloadBytes) / total;
  }

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  String get safeUrl {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return _maskSensitiveText(url);
    }

    final userInfo = uri.userInfo.isEmpty ? '' : 'redacted';
    final query = uri.queryParameters.entries
        .map((entry) {
          final key = entry.key;
          final value = _isSensitiveKey(key) ? '***' : entry.value;
          return '$key=$value';
        })
        .join('&');

    return uri.replace(userInfo: userInfo, query: query).toString();
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    SubscriptionFormat? formatHint,
    SubscriptionUpdateStatus? updateStatus,
    bool? autoUpdate,
    int? updateIntervalSeconds,
    Map<String, String>? headers,
    String? userAgent,
    bool? allowInsecureHttp,
    DateTime? lastUpdatedAt,
    DateTime? expiresAt,
    String? lastEtag,
    DateTime? lastModified,
    String? activeProfileId,
    String? profileTitle,
    String? webPageUrl,
    String? supportUrl,
    String? movedPermanentlyTo,
    String? lastError,
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    int? nodeCount,
    bool? enabled,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      formatHint: formatHint ?? this.formatHint,
      updateStatus: updateStatus ?? this.updateStatus,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      updateIntervalSeconds:
          updateIntervalSeconds ?? this.updateIntervalSeconds,
      headers: headers ?? this.headers,
      userAgent: userAgent ?? this.userAgent,
      allowInsecureHttp: allowInsecureHttp ?? this.allowInsecureHttp,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastEtag: lastEtag ?? this.lastEtag,
      lastModified: lastModified ?? this.lastModified,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      profileTitle: profileTitle ?? this.profileTitle,
      webPageUrl: webPageUrl ?? this.webPageUrl,
      supportUrl: supportUrl ?? this.supportUrl,
      movedPermanentlyTo: movedPermanentlyTo ?? this.movedPermanentlyTo,
      lastError: lastError ?? this.lastError,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      nodeCount: nodeCount ?? this.nodeCount,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'formatHint': formatHint.name,
    'updateStatus': updateStatus.name,
    'autoUpdate': autoUpdate,
    'updateIntervalSeconds': updateIntervalSeconds,
    'headers': headers,
    'userAgent': userAgent,
    'allowInsecureHttp': allowInsecureHttp,
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'lastEtag': lastEtag,
    'lastModified': lastModified?.toIso8601String(),
    'activeProfileId': activeProfileId,
    'profileTitle': profileTitle,
    'webPageUrl': webPageUrl,
    'supportUrl': supportUrl,
    'movedPermanentlyTo': movedPermanentlyTo,
    'lastError': lastError,
    'uploadBytes': uploadBytes,
    'downloadBytes': downloadBytes,
    'totalBytes': totalBytes,
    'nodeCount': nodeCount,
    'enabled': enabled,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      formatHint: SubscriptionFormat.values.byName(
        json['formatHint'] as String? ?? SubscriptionFormat.auto.name,
      ),
      updateStatus: SubscriptionUpdateStatus.values.byName(
        json['updateStatus'] as String? ?? SubscriptionUpdateStatus.idle.name,
      ),
      autoUpdate: json['autoUpdate'] as bool? ?? true,
      updateIntervalSeconds: json['updateIntervalSeconds'] as int? ?? 43200,
      headers: Map<String, String>.from(json['headers'] as Map? ?? const {}),
      userAgent:
          json['userAgent'] as String? ?? SubscriptionRequestDefaults.userAgent,
      allowInsecureHttp: json['allowInsecureHttp'] as bool? ?? false,
      lastUpdatedAt: _parseDate(json['lastUpdatedAt'] as String?),
      expiresAt: _parseDate(json['expiresAt'] as String?),
      lastEtag: json['lastEtag'] as String?,
      lastModified: _parseDate(json['lastModified'] as String?),
      activeProfileId: json['activeProfileId'] as String?,
      profileTitle: json['profileTitle'] as String?,
      webPageUrl: json['webPageUrl'] as String?,
      supportUrl: json['supportUrl'] as String?,
      movedPermanentlyTo: json['movedPermanentlyTo'] as String?,
      lastError: json['lastError'] as String?,
      uploadBytes: json['uploadBytes'] as int? ?? 0,
      downloadBytes: json['downloadBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int?,
      nodeCount: json['nodeCount'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('token') ||
        normalized.contains('key') ||
        normalized.contains('secret') ||
        normalized.contains('password') ||
        normalized.contains('passwd') ||
        normalized == 'auth';
  }

  static String _maskSensitiveText(String value) {
    return value.replaceAllMapped(
      RegExp(
        r'(token|key|secret|password|passwd|auth)=([^&\s]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=***',
    );
  }
}
