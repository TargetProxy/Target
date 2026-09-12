// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get dashboard => '仪表盘';

  @override
  String get profiles => '订阅';

  @override
  String get nodeSelection => '节点选择';

  @override
  String get subscriptionsHint => '复选订阅，将它们的节点汇入 Smart Connect 统一节点池。';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get updateSubscription => '更新订阅';

  @override
  String get refreshPool => '刷新节点池';

  @override
  String get includedInPool => '已加入节点池';

  @override
  String get excludedFromPool => '未加入';

  @override
  String get noSubscriptionsHint => '添加订阅后，勾选一个或多个来源，构建你的节点池。';

  @override
  String poolSummary(int subscriptions, int nodes) {
    return '已启用 $subscriptions 个订阅 · $nodes 个节点';
  }

  @override
  String poolNodeCount(int count) {
    return '$count 个节点';
  }

  @override
  String get subscriptionDetails => '订阅详情';

  @override
  String get lastUpdated => '最近更新';

  @override
  String get neverUpdated => '尚未更新';

  @override
  String get trafficUsed => '已用流量';

  @override
  String get subscriptionAddress => '订阅地址';

  @override
  String get nodePoolHint => '在地图上浏览地区，从已启用订阅的节点中选择连接。';

  @override
  String get allSubscriptions => '全部订阅';

  @override
  String get allRegions => '全部地区';

  @override
  String get searchNodes => '搜索节点、协议或订阅';

  @override
  String get noMatchingNodes => '没有匹配的节点';

  @override
  String get emptyPool => '节点池为空';

  @override
  String get manageSubscriptions => '管理订阅';

  @override
  String get noNodeSelected => '请选择节点';

  @override
  String get nodeUnavailable => '不可用';

  @override
  String get unknownSource => '未知来源';

  @override
  String get clearFilters => '清除筛选';

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
