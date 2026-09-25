import 'package:flutter_test/flutter_test.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/features/smart_connect/domain/smart_connect_models.dart';
import 'package:target/features/smart_connect/domain/smart_runtime_models.dart';

void main() {
  test('observed region overrides the declared region', () {
    const node = ProxyNode(
      id: 'a',
      name: 'A',
      type: 'vless',
      countryCode: 'sg',
      observedCountryCode: 'us',
    );
    expect(node.effectiveRegion, 'US');
  });
  test(
    'route edits retain candidate and probe settings through persistence',
    () {
      const original = SmartPolicy(
        id: 'disney',
        domains: {'disneyplus.com'},
        allowedRegions: {'US'},
        preferredRegions: {'US'},
        allowedSubscriptions: {'one'},
        excludedNodes: {'n1'},
        probeTargets: [
          SmartProbeTarget(
            url: 'https://disneyplus.com/',
            expectedStatus: {200, 204},
            bodyContains: 'ok',
            egressUrl: 'https://example.com/region',
          ),
        ],
        stickyDuration: Duration(minutes: 10),
      );
      final followed = original.copyWith(
        selectionMode: SmartSelectionMode.followDefault,
      );
      final restored = SmartPolicy.fromJson(followed.toJson());
      expect(restored.toJson(), followed.toJson());
      expect(restored.allowedRegions, original.allowedRegions);
      expect(restored.excludedNodes, original.excludedNodes);
      expect(restored.probeTargets.single.bodyContains, 'ok');
      expect(restored.stickyDuration, original.stickyDuration);
      expect(restored.validate(), isEmpty);
    },
  );
  test('manual, follow and direct routes do not require a probe', () {
    for (final mode in [
      SmartSelectionMode.manual,
      SmartSelectionMode.direct,
      SmartSelectionMode.followDefault,
    ]) {
      expect(
        SmartPolicy(
          id: 'x',
          domains: {'x.com'},
          selectionMode: mode,
        ).validate(),
        isEmpty,
      );
    }
    expect(
      const SmartPolicy(id: 'x', domains: {'x.com'}).validate(),
      contains('At least one service probe target is required'),
    );
  });
  test('validation rejects invalid domains and credentialed probe URLs', () {
    expect(
      const SmartPolicy(id: 'x', domains: {'https://x.com'}).validate(),
      isNotEmpty,
    );
    expect(validSmartProbeUrl('https://user:password@x.com'), false);
    expect(validSmartProbeUrl('file:///secret'), false);
    expect(validSmartDomain('a..com'), false);
  });
  test('Direct is an explicit successful selection', () {
    expect(const SmartSelection(direct: true, reason: 'x').succeeded, isTrue);
    expect(const SmartSelection(reason: 'none').succeeded, isFalse);
  });
}
