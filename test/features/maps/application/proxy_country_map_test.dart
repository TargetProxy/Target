import 'package:flutter_test/flutter_test.dart';
import 'package:target/data/models/proxy_node.dart';
import 'package:target/features/maps/application/proxy_country_map.dart';

void main() {
  group('proxyNodeCountryCode', () {
    test('prefers an explicit supported country code', () {
      const node = ProxyNode(
        id: '1',
        name: 'Any node',
        type: 'vmess',
        countryCode: 'sg',
      );

      expect(proxyNodeCountryCode(node), 'SG');
    });

    test('reads flag emoji and common location aliases', () {
      const flagNode = ProxyNode(
        id: '1',
        name: '🇯🇵 Premium 01',
        type: 'trojan',
      );
      const aliasNode = ProxyNode(
        id: '2',
        name: 'Los Angeles - 02',
        type: 'vless',
      );

      expect(proxyNodeCountryCode(flagNode), 'JP');
      expect(proxyNodeCountryCode(aliasNode), 'US');
    });

    test('does not match short aliases inside words', () {
      const node = ProxyNode(id: '1', name: 'Tokyo premium', type: 'hysteria2');

      expect(proxyNodeCountryCode(node), 'JP');
    });
  });

  test('aggregates nodes by country and ignores direct', () {
    const nodes = [
      ProxyNode(id: '1', name: '🇸🇬 01', type: 'vmess'),
      ProxyNode(id: '2', name: 'Singapore 02', type: 'trojan'),
      ProxyNode(id: '3', name: 'Direct', type: 'direct'),
    ];

    final entries = proxyCountryMapEntries(nodes);

    expect(entries, hasLength(1));
    expect(entries.single.countryCode, 'SG');
    expect(entries.single.nodeCount, 2);
  });

  test('filters nodes to the selected country', () {
    const nodes = [
      ProxyNode(id: '1', name: '🇸🇬 01', type: 'vmess'),
      ProxyNode(id: '2', name: 'Singapore 02', type: 'trojan'),
      ProxyNode(id: '3', name: '🇯🇵 01', type: 'vless'),
      ProxyNode(id: '4', name: 'Direct', type: 'direct'),
    ];

    final filtered = proxyNodesInCountry(nodes, 'SG');

    expect(filtered.map((node) => node.id), ['1', '2']);
  });
}
