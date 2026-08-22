import 'package:flutter/foundation.dart';

@immutable
class IpInfo {
  const IpInfo({
    required this.ip,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.isp,
    required this.org,
    required this.asName,
  });

  final String ip;
  final String country;
  final String countryCode;
  final String city;
  final String isp;
  final String org;
  final String asName;

  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ip: json['query'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      isp: json['isp'] as String? ?? '',
      org: json['org'] as String? ?? '',
      asName: json['as'] as String? ?? '',
    );
  }

  String get flagEmoji {
    if (countryCode.length != 2) return '';
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
