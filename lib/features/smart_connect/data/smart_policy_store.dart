import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/smart_connect_models.dart';

/// Local persistence for the editable policy documents and the selection audit.
///
/// Node preferences and subscription priorities are not here: the core owns
/// those, so a second copy would need reconciling.
class SmartPolicyStore {
  SmartPolicyStore({this.key = 'smart_connect.policies'});
  final String key;

  Future<void> ensureDefaultPolicies() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) return;
    if (!await prefs.setString(
      key,
      jsonEncode([for (final policy in defaultSmartPolicies) policy.toJson()]),
    )) {
      throw StateError('Could not initialize Smart Connect policies');
    }
  }

  Future<List<SmartPolicy>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return const [];
    final values = jsonDecode(raw);
    if (values is! List) {
      throw const FormatException('Invalid saved Smart Connect policies');
    }
    return [
      for (final value in values)
        SmartPolicy.fromJson(Map<String, dynamic>.from(value as Map)),
    ];
  }

  Future<void> save(Iterable<SmartPolicy> policies) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      key,
      jsonEncode([for (final p in policies) p.toJson()]),
    )) {
      throw StateError('Could not save Smart Connect policies');
    }
  }

  Future<List<Map<String, Object>>> loadAudit() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final row
          in jsonDecode(prefs.getString('$key.audit') ?? '[]') as List)
        Map<String, Object>.from(row as Map),
    ];
  }

  Future<void> saveAudit(List<Map<String, Object>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('$key.audit', jsonEncode(rows))) {
      throw StateError('Could not save selection audit');
    }
  }
}
