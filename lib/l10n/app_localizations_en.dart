// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Target';

  @override
  String get workspace => 'WORKSPACE';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profiles => 'Profiles';

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
  String get nodeMap => 'Node map';

  @override
  String mapSummary(int regionCount, int nodeCount) {
    return '$regionCount regions · $nodeCount nodes';
  }

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
