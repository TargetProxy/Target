// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profiles => 'Subscriptions';

  @override
  String get nodeSelection => 'Proxy groups';

  @override
  String get subscriptionsHint =>
      'Select subscriptions to supply nodes for all your proxy groups.';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get updateSubscription => 'Update subscription';

  @override
  String get refreshPool => 'Refresh node pool';

  @override
  String get includedInPool => 'Included in node pool';

  @override
  String get excludedFromPool => 'Not included';

  @override
  String get noSubscriptionsHint =>
      'Add a subscription, then select one or more sources for your node pool.';

  @override
  String poolSummary(int subscriptions, int nodes) {
    return '$subscriptions subscriptions enabled · $nodes nodes';
  }

  @override
  String poolNodeCount(int count) {
    return '$count nodes';
  }

  @override
  String get subscriptionDetails => 'Subscription details';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get neverUpdated => 'Not updated yet';

  @override
  String get trafficUsed => 'Traffic used';

  @override
  String get subscriptionAddress => 'Address';

  @override
  String get subscriptionNodes => 'Nodes';

  @override
  String get automaticUpdates => 'Automatic updates';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get updateInterval => 'Update interval';

  @override
  String get expires => 'Expires';

  @override
  String get profile => 'Profile';

  @override
  String get webPage => 'Web page';

  @override
  String get support => 'Support';

  @override
  String get allSubscriptions => 'All subscriptions';

  @override
  String get allRegions => 'All regions';

  @override
  String get searchNodes => 'Search nodes, protocols or subscriptions';

  @override
  String get noMatchingNodes => 'No matching nodes';

  @override
  String get emptyPool => 'Your node pool is empty';

  @override
  String get manageSubscriptions => 'Manage subscriptions';

  @override
  String get nodeUnavailable => 'Unavailable';

  @override
  String get unknownSource => 'Unknown source';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get connections => 'Connections';

  @override
  String get traffic => 'Traffic';

  @override
  String get trafficSubtitle => 'Live throughput and runtime activity.';

  @override
  String get liveTraffic => 'Live traffic';

  @override
  String get upload => 'Upload';

  @override
  String get download => 'Download';

  @override
  String get uploadRate => 'Upload rate';

  @override
  String get downloadRate => 'Download rate';

  @override
  String get activeConnections => 'Active connections';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get logs => 'Logs';

  @override
  String get proxyNodeWorldMap => 'World map of proxy nodes';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get fitMapToNodes => 'Fit map to nodes';

  @override
  String countryMarkerNodeCount(String countryCode, int nodeCount) {
    String _temp0 = intl.Intl.pluralLogic(
      nodeCount,
      locale: localeName,
      other: '$nodeCount nodes',
      one: '1 node',
    );
    return '$countryCode · $_temp0';
  }

  @override
  String get testLatency => 'Test latency';

  @override
  String get rules => 'Rules';

  @override
  String get defaultNode => 'Default node';

  @override
  String get selectDefaultNode => 'Choose default node';

  @override
  String get nodeNotSelected => 'No node selected';

  @override
  String get createDomainRule => 'New domain rule';

  @override
  String get serviceId => 'Service ID';

  @override
  String get displayName => 'Display name';

  @override
  String get domainsHint => 'Domains (comma or space separated)';

  @override
  String get dropNodeHint => 'Drop a node here as the rule exit';

  @override
  String get dropNode => 'Drop a node here';

  @override
  String selectedNode(Object node) {
    return 'Selected: $node';
  }

  @override
  String get saveRule => 'Save rule';

  @override
  String routeExit(Object node) {
    return 'Exit: $node (drop a node to switch)';
  }

  @override
  String get deleteRule => 'Delete rule';

  @override
  String get searchConnections => 'Search connections...';

  @override
  String get closeAllConnections => 'Close all connections';

  @override
  String get noConnections => 'No connections';

  @override
  String get connectionDetailsUnavailable => 'Connection details unavailable';

  @override
  String get activeConnectionsWillInterrupt =>
      'Active network connections will be interrupted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get closeAll => 'Close all';

  @override
  String get unableToCloseConnection => 'Unable to close connection.';

  @override
  String get unableToCloseConnections => 'Unable to close connections.';

  @override
  String closedConnections(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Closed $count active connection$_temp0.';
  }

  @override
  String get sortBy => 'Sort by';

  @override
  String get trafficSort => 'Traffic';

  @override
  String get destinationSort => 'Destination';

  @override
  String get outboundSort => 'Outbound';

  @override
  String get networkSort => 'Network';

  @override
  String get runtimeDiagnostics => 'Runtime events and diagnostics.';

  @override
  String get copyVisible => 'Copy visible';

  @override
  String get export => 'Export';

  @override
  String get clear => 'Clear';

  @override
  String get noLogs => 'No logs';

  @override
  String get logsRealtimeHint => 'Logs will appear here in real time.';

  @override
  String get logsCopied => 'Logs copied to clipboard';

  @override
  String get exportLogs => 'Export logs';

  @override
  String get sanitizeLogsPrompt =>
      'Sanitize sensitive data (URLs, IPs, tokens)?';

  @override
  String get raw => 'Raw';

  @override
  String get sanitized => 'Sanitized';

  @override
  String get sanitizedLogsCopied => 'Sanitized logs copied to clipboard';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get searchLogs => 'Search logs...';

  @override
  String get all => 'All';

  @override
  String get err => 'Err';

  @override
  String get warn => 'Warn';

  @override
  String get info => 'Info';

  @override
  String get addSubscriptionTitle => 'Add subscription';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get subscriptionUrl => 'Subscription URL';

  @override
  String get urlRequired => 'URL is required';

  @override
  String get paste => 'Paste';

  @override
  String get add => 'Add';

  @override
  String get ipInformation => 'IP information';

  @override
  String get refresh => 'Refresh';

  @override
  String get failedToLoadIpInfo => 'Failed to load IP information';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get isp => 'ISP';

  @override
  String get connected => 'Connected';

  @override
  String get noActiveProfile => 'No active profile';

  @override
  String get mode => 'Mode';

  @override
  String get node => 'Node';

  @override
  String get region => 'Region';

  @override
  String get nodeId => 'Node ID';

  @override
  String get proxyError => 'Proxy error';

  @override
  String get serviceRunning => 'Service is running';

  @override
  String get serviceStopped => 'Service is stopped';

  @override
  String get proxyMode => 'Proxy mode';

  @override
  String get routingMode => 'Routing mode';

  @override
  String get mixed => 'Mixed';

  @override
  String get tun => 'TUN';

  @override
  String get rule => 'Rule';

  @override
  String get direct => 'Direct';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get working => 'Working…';

  @override
  String get viewLogs => 'View logs';

  @override
  String get nodeLibrary => 'Node library';

  @override
  String get trafficRouted => 'Traffic is routed through the active profile.';

  @override
  String get startServicePrompt =>
      'Start the service to begin routing traffic.';

  @override
  String get coreUnavailable =>
      'The local core is unavailable on this platform.';

  @override
  String get vpnTun => 'VPN (TUN)';

  @override
  String get serviceCheckFailed => 'Unable to check TargetLib service';

  @override
  String get targetLibStopped => 'TargetLib service is stopped';

  @override
  String get targetLibNotInstalled => 'TargetLib service is not installed';

  @override
  String get targetLibUnknown => 'TargetLib service status is unknown';

  @override
  String get startRegisteredService =>
      'Start the registered service to make TargetLib available.';

  @override
  String get repairTargetLib =>
      'Install or repair TargetLib using the platform installer, then check again.';

  @override
  String get starting => 'Starting…';

  @override
  String get startService => 'Start service';

  @override
  String get checkAgain => 'Check again';

  @override
  String get ruleInputRequired =>
      'Enter a service ID and domain, then drop in a node.';
}
