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
  String get nodeSelection => '代理分组';

  @override
  String get subscriptionsHint => '勾选订阅，为所有代理分组提供可选节点。';

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
  String get subscriptionNodes => '节点数';

  @override
  String get automaticUpdates => '自动更新';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已停用';

  @override
  String get updateInterval => '更新周期';

  @override
  String get expires => '过期时间';

  @override
  String get profile => '配置';

  @override
  String get webPage => '网页';

  @override
  String get support => '支持';

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
  String get testLatency => '测试延迟';

  @override
  String get rules => '规则';

  @override
  String get defaultNode => '默认节点';

  @override
  String get selectDefaultNode => '选择默认节点';

  @override
  String get nodeNotSelected => '尚未选择';

  @override
  String get createDomainRule => '新建域名规则';

  @override
  String get serviceId => '服务 ID';

  @override
  String get displayName => '显示名称';

  @override
  String get domainsHint => '域名（逗号或空格分隔）';

  @override
  String get dropNodeHint => '将节点拖到这里作为规则出口';

  @override
  String get dropNode => '拖入节点';

  @override
  String selectedNode(Object node) {
    return '已选择：$node';
  }

  @override
  String get saveRule => '保存规则';

  @override
  String routeExit(Object node) {
    return '出口：$node（拖入节点可切换）';
  }

  @override
  String get deleteRule => '删除规则';

  @override
  String get searchConnections => '搜索连接...';

  @override
  String get closeAllConnections => '关闭所有连接';

  @override
  String get noConnections => '暂无连接';

  @override
  String get connectionDetailsUnavailable => '连接详情不可用';

  @override
  String get activeConnectionsWillInterrupt => '活动网络连接将被中断。';

  @override
  String get cancel => '取消';

  @override
  String get closeAll => '全部关闭';

  @override
  String get unableToCloseConnection => '无法关闭连接。';

  @override
  String get unableToCloseConnections => '无法关闭连接。';

  @override
  String closedConnections(num count) {
    return '已关闭 $count 个活动连接。';
  }

  @override
  String get sortBy => '排序方式';

  @override
  String get trafficSort => '流量';

  @override
  String get destinationSort => '目标地址';

  @override
  String get outboundSort => '出站';

  @override
  String get networkSort => '网络';

  @override
  String get runtimeDiagnostics => '运行事件与诊断信息。';

  @override
  String get copyVisible => '复制当前内容';

  @override
  String get export => '导出';

  @override
  String get clear => '清空';

  @override
  String get noLogs => '暂无日志';

  @override
  String get logsRealtimeHint => '日志会实时显示在这里。';

  @override
  String get logsCopied => '日志已复制到剪贴板';

  @override
  String get exportLogs => '导出日志';

  @override
  String get sanitizeLogsPrompt => '清理敏感数据（网址、IP、令牌）？';

  @override
  String get raw => '原始';

  @override
  String get sanitized => '已清理';

  @override
  String get sanitizedLogsCopied => '已清理的日志已复制到剪贴板';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get searchLogs => '搜索日志...';

  @override
  String get all => '全部';

  @override
  String get err => '错误';

  @override
  String get warn => '警告';

  @override
  String get info => '信息';

  @override
  String get addSubscriptionTitle => '添加订阅';

  @override
  String get nameOptional => '名称（可选）';

  @override
  String get subscriptionUrl => '订阅地址';

  @override
  String get urlRequired => '请输入地址';

  @override
  String get paste => '粘贴';

  @override
  String get add => '添加';

  @override
  String get ipInformation => 'IP 信息';

  @override
  String get refresh => '刷新';

  @override
  String get failedToLoadIpInfo => 'IP 信息加载失败';

  @override
  String get country => '国家/地区';

  @override
  String get city => '城市';

  @override
  String get isp => '运营商';

  @override
  String get connected => '已连接';

  @override
  String get noActiveProfile => '没有活动配置';

  @override
  String get mode => '模式';

  @override
  String get node => '节点';

  @override
  String get region => '地区';

  @override
  String get nodeId => '节点 ID';

  @override
  String get proxyError => '代理错误';

  @override
  String get serviceRunning => '服务正在运行';

  @override
  String get serviceStopped => '服务已停止';

  @override
  String get proxyMode => '代理模式';

  @override
  String get routingMode => '路由模式';

  @override
  String get mixed => '混合';

  @override
  String get tun => 'TUN';

  @override
  String get rule => '规则';

  @override
  String get direct => '直连';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get working => '处理中…';

  @override
  String get viewLogs => '查看日志';

  @override
  String get nodeLibrary => '节点库';

  @override
  String get trafficRouted => '流量将通过当前配置转发。';

  @override
  String get startServicePrompt => '启动服务后即可开始转发流量。';

  @override
  String get coreUnavailable => '当前平台无法使用本地内核。';

  @override
  String get vpnTun => 'VPN（TUN）';

  @override
  String get serviceCheckFailed => '无法检查 TargetLib 服务';

  @override
  String get targetLibStopped => 'TargetLib 服务已停止';

  @override
  String get targetLibNotInstalled => '尚未安装 TargetLib 服务';

  @override
  String get targetLibUnknown => 'TargetLib 服务状态未知';

  @override
  String get startRegisteredService => '启动已注册的服务以使用 TargetLib。';

  @override
  String get repairTargetLib => '请使用平台安装程序安装或修复 TargetLib，然后重新检查。';

  @override
  String get starting => '启动中…';

  @override
  String get startService => '启动服务';

  @override
  String get checkAgain => '再次检查';

  @override
  String get ruleInputRequired => '填写服务 ID、域名，并拖入一个节点。';

  @override
  String get disconnected => '离线';

  @override
  String get connectionError => '连接错误';

  @override
  String get connectionErrorMessage => 'TargetLib 无法连接，请查看日志了解详情。';

  @override
  String get closeConnection => '关闭连接';

  @override
  String get more => '更多';

  @override
  String get showWindow => '显示窗口';

  @override
  String get quit => '退出';

  @override
  String get systemProxy => '系统代理';

  @override
  String get systemProxyDescription => '将混合代理应用到系统网络设置';

  @override
  String get timeout => '超时';
}
