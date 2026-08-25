import '../../../data/models/proxy_node.dart';

class ProxyCountryMapEntry {
  const ProxyCountryMapEntry({
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.nodeCount,
  });

  final String countryCode;
  final double latitude;
  final double longitude;
  final int nodeCount;
}

const _locations = <String, ({double latitude, double longitude})>{
  'AR': (latitude: -38.42, longitude: -63.62),
  'AU': (latitude: -25.27, longitude: 133.78),
  'BR': (latitude: -14.24, longitude: -51.93),
  'CA': (latitude: 56.13, longitude: -106.35),
  'CH': (latitude: 46.82, longitude: 8.23),
  'CL': (latitude: -33.45, longitude: -70.67),
  'CN': (latitude: 35.86, longitude: 104.20),
  'DE': (latitude: 51.17, longitude: 10.45),
  'EG': (latitude: 26.82, longitude: 30.80),
  'ES': (latitude: 40.46, longitude: -3.75),
  'FI': (latitude: 61.92, longitude: 25.75),
  'FR': (latitude: 46.23, longitude: 2.21),
  'GB': (latitude: 54.00, longitude: -2.00),
  'HK': (latitude: 22.32, longitude: 114.17),
  'ID': (latitude: -0.79, longitude: 113.92),
  'IE': (latitude: 53.14, longitude: -7.69),
  'IL': (latitude: 31.05, longitude: 34.85),
  'IN': (latitude: 20.59, longitude: 78.96),
  'IT': (latitude: 41.87, longitude: 12.57),
  'JP': (latitude: 36.20, longitude: 138.25),
  'KR': (latitude: 35.91, longitude: 127.77),
  'MO': (latitude: 22.20, longitude: 113.54),
  'MX': (latitude: 23.63, longitude: -102.55),
  'MY': (latitude: 4.21, longitude: 101.98),
  'NL': (latitude: 52.13, longitude: 5.29),
  'NO': (latitude: 60.47, longitude: 8.47),
  'NZ': (latitude: -40.90, longitude: 174.89),
  'PH': (latitude: 12.88, longitude: 121.77),
  'PL': (latitude: 51.92, longitude: 19.15),
  'RU': (latitude: 61.52, longitude: 105.32),
  'SE': (latitude: 60.13, longitude: 18.64),
  'SG': (latitude: 1.35, longitude: 103.82),
  'TH': (latitude: 15.87, longitude: 100.99),
  'TR': (latitude: 38.96, longitude: 35.24),
  'TW': (latitude: 23.70, longitude: 120.96),
  'UA': (latitude: 48.38, longitude: 31.17),
  'US': (latitude: 39.83, longitude: -98.58),
  'VN': (latitude: 14.06, longitude: 108.28),
  'ZA': (latitude: -30.56, longitude: 22.94),
};

const _aliases = <String, List<String>>{
  'AR': ['argentina', 'argentine', '阿根廷'],
  'AU': ['australia', 'aussie', '澳大利亚', '澳洲'],
  'BR': ['brazil', '巴西'],
  'CA': ['canada', '加拿大'],
  'CH': ['switzerland', 'swiss', '瑞士'],
  'CL': ['chile', '智利'],
  'CN': ['china', 'mainland', '中国', '大陆'],
  'DE': ['germany', 'frankfurt', '德国', '法兰克福'],
  'EG': ['egypt', '埃及'],
  'ES': ['spain', 'madrid', '西班牙', '马德里'],
  'FI': ['finland', '芬兰'],
  'FR': ['france', 'paris', '法国', '巴黎'],
  'GB': ['united kingdom', 'britain', 'england', 'london', 'uk', '英国', '伦敦'],
  'HK': ['hong kong', 'hongkong', 'hk', '香港'],
  'ID': ['indonesia', 'jakarta', '印尼', '雅加达'],
  'IE': ['ireland', '爱尔兰'],
  'IL': ['israel', '以色列'],
  'IN': ['india', 'mumbai', '印度', '孟买'],
  'IT': ['italy', 'milan', '意大利', '米兰'],
  'JP': ['japan', 'tokyo', 'osaka', 'jp', '日本', '东京', '大阪'],
  'KR': ['south korea', 'korea', 'seoul', 'kr', '韩国', '首尔'],
  'MO': ['macao', 'macau', '澳门'],
  'MX': ['mexico', '墨西哥'],
  'MY': ['malaysia', 'kuala lumpur', 'my', '马来西亚', '吉隆坡'],
  'NL': ['netherlands', 'holland', 'amsterdam', '荷兰', '阿姆斯特丹'],
  'NO': ['norway', '挪威'],
  'NZ': ['new zealand', '新西兰'],
  'PH': ['philippines', 'manila', '菲律宾', '马尼拉'],
  'PL': ['poland', 'warsaw', '波兰', '华沙'],
  'RU': ['russia', 'moscow', '俄罗斯', '莫斯科'],
  'SE': ['sweden', 'stockholm', '瑞典', '斯德哥尔摩'],
  'SG': ['singapore', 'sg', '新加坡', '狮城'],
  'TH': ['thailand', 'bangkok', '泰国', '曼谷'],
  'TR': ['turkey', 'istanbul', '土耳其', '伊斯坦布尔'],
  'TW': ['taiwan', 'taipei', 'tw', '台湾', '台北'],
  'UA': ['ukraine', '乌克兰'],
  'US': [
    'united states',
    'america',
    'los angeles',
    'san jose',
    'new york',
    'us',
    'usa',
    '美国',
    '洛杉矶',
    '圣何塞',
    '纽约',
  ],
  'VN': ['vietnam', 'hanoi', '越南', '河内'],
  'ZA': ['south africa', '南非'],
};

List<ProxyCountryMapEntry> proxyCountryMapEntries(Iterable<ProxyNode> nodes) {
  final counts = <String, int>{};
  for (final node in nodes.where(
    (node) => node.type.toLowerCase() != 'direct',
  )) {
    final code = proxyNodeCountryCode(node);
    if (code != null) {
      counts.update(code, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  final entries = [
    for (final entry in counts.entries)
      ProxyCountryMapEntry(
        countryCode: entry.key,
        latitude: _locations[entry.key]!.latitude,
        longitude: _locations[entry.key]!.longitude,
        nodeCount: entry.value,
      ),
  ];
  entries.sort((a, b) => a.longitude.compareTo(b.longitude));
  return entries;
}

String? proxyNodeCountryCode(ProxyNode node) {
  final explicit = node.countryCode?.trim().toUpperCase();
  if (explicit != null && _locations.containsKey(explicit)) {
    return explicit;
  }

  final name = node.name.toLowerCase();
  final flagCode = _countryCodeFromFlag(name);
  if (flagCode != null && _locations.containsKey(flagCode)) {
    return flagCode;
  }

  for (final entry in _aliases.entries) {
    if (entry.value.any((alias) => _containsAlias(name, alias))) {
      return entry.key;
    }
  }
  return null;
}

ProxyNode? firstProxyNodeInCountry(
  Iterable<ProxyNode> nodes,
  String countryCode,
) {
  for (final node in nodes) {
    if (proxyNodeCountryCode(node) == countryCode) return node;
  }
  return null;
}

List<ProxyNode> proxyNodesInCountry(
  Iterable<ProxyNode> nodes,
  String countryCode,
) {
  return [
    for (final node in nodes)
      if (proxyNodeCountryCode(node) == countryCode) node,
  ];
}

String? _countryCodeFromFlag(String text) {
  final runes = text.runes.toList();
  for (var index = 0; index < runes.length - 1; index++) {
    final first = runes[index];
    final second = runes[index + 1];
    if (first >= 0x1F1E6 &&
        first <= 0x1F1FF &&
        second >= 0x1F1E6 &&
        second <= 0x1F1FF) {
      return String.fromCharCodes([
        first - 0x1F1E6 + 0x41,
        second - 0x1F1E6 + 0x41,
      ]);
    }
  }
  return null;
}

bool _containsAlias(String name, String alias) {
  if (alias.runes.any((rune) => rune > 0x7F) || alias.contains(' ')) {
    return name.contains(alias);
  }
  return RegExp('(^|[^a-z])${RegExp.escape(alias)}([^a-z]|\$)').hasMatch(name);
}
