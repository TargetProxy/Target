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
    this.lastUpdatedAt,
    this.expiresAt,
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
  final DateTime? lastUpdatedAt;
  final DateTime? expiresAt;
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
    DateTime? lastUpdatedAt,
    DateTime? expiresAt,
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
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
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
