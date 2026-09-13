import 'package:flutter_test/flutter_test.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';

void main() {
  final now = DateTime.utc(2026, 9, 13);
  const policy = SmartPolicy(
    id: 'chatgpt',
    domains: {'chatgpt.com'},
    allowedRegions: {'SG'},
    preferredRegions: {'SG'},
    probeTargets: [SmartProbeTarget(url: 'https://chatgpt.com/')],
  );
  SmartNode node(
    String id, {
    String region = 'SG',
    String observed = '',
    double success = 1,
    int latency = 80,
    bool passed = true,
    DateTime? expires,
    String? revision,
    bool enabled = true,
    bool excluded = false,
    String subscription = '',
    Set<String> tags = const {},
  }) => SmartNode(
    id: id,
    region: region,
    observedRegion: observed,
    successRate: success,
    latencyMs: latency,
    enabled: enabled,
    excluded: excluded,
    subscriptionId: subscription,
    tags: tags,
    probePassed: passed,
    testedAt: now.subtract(const Duration(seconds: 1)),
    expiresAt: expires ?? now.add(const Duration(minutes: 5)),
    policyRevision: revision ?? policy.revision,
  );

  test('filters regions and ranks stability before latency', () {
    final result = selectSmartNode(policy, [
      node('US', region: 'US'),
      node('fast', success: .5, latency: 10),
      node('stable'),
    ], now: now);
    expect(result.node?.id, 'stable');
    expect(result.excluded['US'], 'region not allowed');
    expect(result.scores, contains('stable'));
  });
  test(
    'observed region overrides node name-derived country in both directions',
    () {
      final result = selectSmartNode(policy, [
        node('declaredSG', observed: 'US'),
        node('declaredUS', region: 'US', observed: 'SG'),
      ], now: now);
      expect(result.node?.id, 'declaredUS');
      expect(result.excluded['declaredSG'], 'region not allowed');
    },
  );
  test('rejects missing, expired, failed and policy-stale probes', () {
    final result = selectSmartNode(policy, [
      const SmartNode(id: 'untested', region: 'SG', successRate: 1),
      node('expired', expires: now),
      node('failed', passed: false),
      node('stale', revision: 'old'),
    ], now: now);
    expect(result.succeeded, false);
    expect(
      result.excluded.keys,
      containsAll(['untested', 'expired', 'failed', 'stale']),
    );
  });
  test(
    'node preference, subscription and tag exclusions cannot be bypassed',
    () {
      const restricted = SmartPolicy(
        id: 'restricted',
        allowedSubscriptions: {'a'},
        requiredTags: {'work'},
      );
      expect(
        smartCandidateExclusion(restricted, node('disabled', enabled: false)),
        'disabled',
      );
      expect(
        smartCandidateExclusion(restricted, node('excluded', excluded: true)),
        'excluded by policy',
      );
      expect(
        smartCandidateExclusion(restricted, node('b', subscription: 'b')),
        'subscription not allowed',
      );
      expect(
        smartCandidateExclusion(restricted, node('no-tag', subscription: 'a')),
        'required tags missing',
      );
      expect(
        smartCandidateExclusion(
          restricted,
          node('ok', subscription: 'a', tags: {'work'}),
        ),
        isNull,
      );
    },
  );
  test('direct is an explicit result and disabled direct never succeeds', () {
    expect(
      selectSmartNode(
        const SmartPolicy(id: 'd', selectionMode: SmartSelectionMode.direct),
        [],
      ).direct,
      true,
    );
    expect(
      selectSmartNode(
        const SmartPolicy(
          id: 'd',
          selectionMode: SmartSelectionMode.direct,
          enabled: false,
        ),
        [],
      ).succeeded,
      false,
    );
  });
  test('domain matching respects boundaries and canonical suffix length', () {
    final policies = {'OPENAI.COM.': policy, '.api.openai.com': policy};
    expect(policyForDomain('API.OPENAI.COM.', policies), '.api.openai.com');
    expect(policyForDomain('notopenai.com', policies), isNull);
  });
  test('full policy serialization and canonical revision', () {
    const full = SmartPolicy(
      id: 'x',
      name: 'Service',
      domains: {'x.com'},
      allowedRegions: {'JP', 'SG'},
      preferredRegions: {'SG'},
      allowedSubscriptions: {'one'},
      requiredTags: {'work'},
      excludedNodes: {'n1'},
      probeTargets: [
        SmartProbeTarget(
          url: 'https://x.com/',
          expectedStatus: {200, 204},
          bodyContains: 'ok',
          egressUrl: 'https://example.com/region',
          serviceCountryHeader: 'country',
        ),
      ],
      selectionMode: SmartSelectionMode.manual,
      stickyDuration: Duration(minutes: 10),
    );
    final restored = SmartPolicy.fromJson(full.toJson());
    expect(restored.toJson(), full.toJson());
    expect(restored.revision, full.revision);
    expect(restored.revision, isNot(contains('https')));
    expect(restored.validate(), isEmpty);
    final changed = SmartPolicy.fromJson({
      ...full.toJson(),
      'allowedRegions': ['SG', 'JP'],
    });
    expect(changed.revision, full.revision);
    expect(
      SmartPolicy.fromJson({
        ...full.toJson(),
        'domains': ['y.com'],
      }).revision,
      isNot(full.revision),
    );
  });
  test(
    'validation rejects malformed domains, credentials and empty probes',
    () {
      expect(
        const SmartPolicy(id: 'x', domains: {'https://x.com'}).validate(),
        isNotEmpty,
      );
      expect(validSmartProbeUrl('https://user:password@x.com'), false);
      expect(validSmartProbeUrl('file:///secret'), false);
      expect(validSmartDomain('a..com'), false);
      expect(validSmartDomain('-a.com'), false);
    },
  );
}
