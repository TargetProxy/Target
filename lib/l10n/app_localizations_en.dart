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
  String get nodeSelection => 'Node selection';

  @override
  String get subscriptionsHint =>
      'Select the subscriptions to include in your Smart Connect node pool.';

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
  String get nodePoolHint =>
      'Explore regions on the map, then select a node from your enabled subscriptions.';

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
  String get noNodeSelected => 'Select a node';

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
  String get outboundPolicy => 'Outbound policy';

  @override
  String get testLatency => 'Test latency';

  @override
  String get selectCountry => 'Select country';

  @override
  String countryCount(int count) {
    return 'Countries · $count';
  }

  @override
  String get selectionSavedForNextCoreStart =>
      'The saved selection will be used the next time the core starts.';

  @override
  String get noOutboundGroupsAvailable => 'No outbound groups are available.';

  @override
  String groupMembers(int count, String type) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0 · $type';
  }
}
