import 'package:flutter/foundation.dart';

@immutable
class ProxyNode {
  const ProxyNode({
    required this.id,
    required this.name,
    required this.type,
    this.countryCode,
    this.latencyMs,
    this.isSelected = false,
    this.isAvailable = true,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final String type;
  final String? countryCode;
  final int? latencyMs;
  final bool isSelected;
  final bool isAvailable;
  final Map<String, dynamic> metadata;

  String get displayName => name;

  String get typeLabel => type.toUpperCase();

  ProxyNode copyWith({
    String? id,
    String? name,
    String? type,
    String? countryCode,
    int? latencyMs,
    bool? isSelected,
    bool? isAvailable,
    Map<String, dynamic>? metadata,
  }) {
    return ProxyNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      countryCode: countryCode ?? this.countryCode,
      latencyMs: latencyMs ?? this.latencyMs,
      isSelected: isSelected ?? this.isSelected,
      isAvailable: isAvailable ?? this.isAvailable,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'countryCode': countryCode,
    'latencyMs': latencyMs,
    'isSelected': isSelected,
    'isAvailable': isAvailable,
    'metadata': metadata,
  };

  factory ProxyNode.fromJson(Map<String, dynamic> json) {
    return ProxyNode(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      countryCode: json['countryCode'] as String?,
      latencyMs: json['latencyMs'] as int?,
      isSelected: json['isSelected'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}
