// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Target';

  @override
  String get workspace => '工作区';

  @override
  String get dashboard => '仪表盘';

  @override
  String get profiles => '配置';

  @override
  String get connections => '连接';

  @override
  String get traffic => '流量';

  @override
  String get trafficSubtitle => '实时吞吐量与内核运行状态。';

  @override
  String get liveTraffic => '实时流量';

  @override
  String get upload => '上传';

  @override
  String get download => '下载';

  @override
  String get uploadRate => '上传速率';

  @override
  String get downloadRate => '下载速率';

  @override
  String get activeConnections => '活动连接';

  @override
  String get running => '运行中';

  @override
  String get stopped => '已停止';

  @override
  String get logs => '日志';

  @override
  String get nodeMap => '节点地图';

  @override
  String mapSummary(int regionCount, int nodeCount) {
    return '$regionCount 个地区 · $nodeCount 个节点';
  }

  @override
  String get proxyNodeWorldMap => '代理节点世界地图';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get fitMapToNodes => '适配所有节点';

  @override
  String countryMarkerNodeCount(String countryCode, int nodeCount) {
    return '$countryCode · $nodeCount 个节点';
  }

  @override
  String get outboundPolicy => '出站策略';

  @override
  String get testLatency => '测试延迟';

  @override
  String get selectCountry => '选择国家';

  @override
  String countryCount(int count) {
    return '国家 · $count';
  }

  @override
  String get selectionSavedForNextCoreStart => '下次启动内核时会使用已保存的选择。';

  @override
  String get noOutboundGroupsAvailable => '暂无可用的出站分组。';

  @override
  String groupMembers(int count, String type) {
    return '$count 个成员 · $type';
  }
}
