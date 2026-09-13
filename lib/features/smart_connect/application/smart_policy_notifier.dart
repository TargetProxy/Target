import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/smart_policy_store.dart';
import '../domain/smart_connect_models.dart';

final smartPolicyStoreProvider = Provider((ref) => SmartPolicyStore());

class SmartPolicyNotifier extends AsyncNotifier<List<SmartPolicy>> {
  Future<void> _tail = Future.value();
  @override
  Future<List<SmartPolicy>> build() =>
      ref.read(smartPolicyStoreProvider).load();

  Future<void> _edit(List<SmartPolicy> Function(List<SmartPolicy>) edit) {
    final task = _tail.then((_) async {
      final current = await future;
      final next = edit([...current]);
      await ref.read(smartPolicyStoreProvider).save(next);
      if (ref.mounted) state = AsyncData(next);
    });
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> savePolicy(SmartPolicy policy) {
    final errors = policy.validate();
    if (errors.isNotEmpty) {
      return Future.error(FormatException(errors.join('; ')));
    }
    return _edit((current) {
      for (final other in current.where(
        (p) => p.id != policy.id && p.enabled && policy.enabled,
      )) {
        if (other.domains
            .map((d) => d.toLowerCase())
            .toSet()
            .intersection(policy.domains.map((d) => d.toLowerCase()).toSet())
            .isNotEmpty) {
          throw const FormatException(
            'A domain is already owned by another enabled service',
          );
        }
      }
      final index = current.indexWhere((p) => p.id == policy.id);
      if (index < 0) {
        current.add(policy);
      } else {
        current[index] = policy;
      }
      return current;
    });
  }

  Future<void> importPolicies(List<SmartPolicy> policies) => _edit((current) {
    final ids = <String>{};
    final domains = <String>{};
    for (final policy in policies) {
      final errors = policy.validate();
      if (errors.isNotEmpty) throw FormatException(errors.join('; '));
      if (!ids.add(policy.id)) {
        throw const FormatException('Duplicate service ID');
      }
      if (policy.enabled) {
        for (final domain in policy.domains) {
          if (!domains.add(domain.toLowerCase())) {
            throw const FormatException('Duplicate service domain');
          }
        }
      }
    }
    // Merge imported definitions; runtime bindings remain explicitly applied.
    final merged = [...current.where((p) => !ids.contains(p.id)), ...policies];
    final activeDomains = <String>{};
    for (final policy in merged.where((p) => p.enabled)) {
      for (final domain in policy.domains) {
        if (!activeDomains.add(domain.toLowerCase())) {
          throw const FormatException(
            'Domain conflicts with an existing policy',
          );
        }
      }
    }
    return merged;
  });
  Future<void> removePolicy(String id) =>
      _edit((current) => current..removeWhere((p) => p.id == id));
}

final smartPoliciesProvider =
    AsyncNotifierProvider<SmartPolicyNotifier, List<SmartPolicy>>(
      SmartPolicyNotifier.new,
    );
