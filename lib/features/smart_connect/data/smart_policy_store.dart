import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/smart_connect_models.dart';

/// Separate keys ensure ordinary proxy settings never change with feature data.
class SmartPolicyStore {
  SmartPolicyStore({this.key = 'smart_connect.policies'});
  final String key;

  Future<bool> hasManagedRuntime() async =>
      (await SharedPreferences.getInstance()).getBool('$key.runtime_owned') ??
      false;
  Future<void> markManagedRuntime() async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      '$key.runtime_owned',
      true,
    )) {
      throw StateError('Could not persist Smart Connect runtime ownership');
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

  Future<Map<String, SmartNodePreference>> nodePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonDecode(prefs.getString('$key.nodes') ?? '{}')
            as Map<String, dynamic>;
    return json.map(
      (key, value) => MapEntry(
        key,
        SmartNodePreference.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> saveNodePreference(
    String id,
    SmartNodePreference preference,
  ) async {
    final nodes = await nodePreferences();
    nodes[id] = preference;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      '$key.nodes',
      jsonEncode(nodes.map((k, v) => MapEntry(k, v.toJson()))),
    )) {
      throw StateError('Could not save node preference');
    }
  }

  Future<Map<String, int>> subscriptionPriorities() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString('$key.priorities') ?? '{}')
            as Map<String, dynamic>)
        .cast<String, int>();
  }

  Future<void> saveSubscriptionPriority(String id, int priority) async {
    final priorities = await subscriptionPriorities();
    priorities[id] = priority;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('$key.priorities', jsonEncode(priorities))) {
      throw StateError('Could not save subscription priority');
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
