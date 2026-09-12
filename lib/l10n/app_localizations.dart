import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get profiles;

  /// No description provided for @nodeSelection.
  ///
  /// In en, this message translates to:
  /// **'Node selection'**
  String get nodeSelection;

  /// No description provided for @subscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Select the subscriptions to include in your Smart Connect node pool.'**
  String get subscriptionsHint;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscription;

  /// No description provided for @updateSubscription.
  ///
  /// In en, this message translates to:
  /// **'Update subscription'**
  String get updateSubscription;

  /// No description provided for @refreshPool.
  ///
  /// In en, this message translates to:
  /// **'Refresh node pool'**
  String get refreshPool;

  /// No description provided for @includedInPool.
  ///
  /// In en, this message translates to:
  /// **'Included in node pool'**
  String get includedInPool;

  /// No description provided for @excludedFromPool.
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get excludedFromPool;

  /// No description provided for @noSubscriptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription, then select one or more sources for your node pool.'**
  String get noSubscriptionsHint;

  /// No description provided for @poolSummary.
  ///
  /// In en, this message translates to:
  /// **'{subscriptions} subscriptions enabled · {nodes} nodes'**
  String poolSummary(int subscriptions, int nodes);

  /// No description provided for @poolNodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes'**
  String poolNodeCount(int count);

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription details'**
  String get subscriptionDetails;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @neverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated yet'**
  String get neverUpdated;

  /// No description provided for @trafficUsed.
  ///
  /// In en, this message translates to:
  /// **'Traffic used'**
  String get trafficUsed;

  /// No description provided for @subscriptionAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get subscriptionAddress;

  /// No description provided for @subscriptionNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get subscriptionNodes;

  /// No description provided for @automaticUpdates.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates'**
  String get automaticUpdates;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @updateInterval.
  ///
  /// In en, this message translates to:
  /// **'Update interval'**
  String get updateInterval;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @webPage.
  ///
  /// In en, this message translates to:
  /// **'Web page'**
  String get webPage;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @nodePoolHint.
  ///
  /// In en, this message translates to:
  /// **'Explore regions on the map, then select a node from your enabled subscriptions.'**
  String get nodePoolHint;

  /// No description provided for @allSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'All subscriptions'**
  String get allSubscriptions;

  /// No description provided for @allRegions.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get allRegions;

  /// No description provided for @searchNodes.
  ///
  /// In en, this message translates to:
  /// **'Search nodes, protocols or subscriptions'**
  String get searchNodes;

  /// No description provided for @noMatchingNodes.
  ///
  /// In en, this message translates to:
  /// **'No matching nodes'**
  String get noMatchingNodes;

  /// No description provided for @emptyPool.
  ///
  /// In en, this message translates to:
  /// **'Your node pool is empty'**
  String get emptyPool;

  /// No description provided for @manageSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Manage subscriptions'**
  String get manageSubscriptions;

  /// No description provided for @noNodeSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a node'**
  String get noNodeSelected;

  /// No description provided for @nodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get nodeUnavailable;

  /// No description provided for @unknownSource.
  ///
  /// In en, this message translates to:
  /// **'Unknown source'**
  String get unknownSource;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @traffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// No description provided for @trafficSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live throughput and runtime activity.'**
  String get trafficSubtitle;

  /// No description provided for @liveTraffic.
  ///
  /// In en, this message translates to:
  /// **'Live traffic'**
  String get liveTraffic;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @uploadRate.
  ///
  /// In en, this message translates to:
  /// **'Upload rate'**
  String get uploadRate;

  /// No description provided for @downloadRate.
  ///
  /// In en, this message translates to:
  /// **'Download rate'**
  String get downloadRate;

  /// No description provided for @activeConnections.
  ///
  /// In en, this message translates to:
  /// **'Active connections'**
  String get activeConnections;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @proxyNodeWorldMap.
  ///
  /// In en, this message translates to:
  /// **'World map of proxy nodes'**
  String get proxyNodeWorldMap;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @fitMapToNodes.
  ///
  /// In en, this message translates to:
  /// **'Fit map to nodes'**
  String get fitMapToNodes;

  /// No description provided for @countryMarkerNodeCount.
  ///
  /// In en, this message translates to:
  /// **'{countryCode} · {nodeCount, plural, =1{1 node} other{{nodeCount} nodes}}'**
  String countryMarkerNodeCount(String countryCode, int nodeCount);

  /// No description provided for @outboundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Outbound policy'**
  String get outboundPolicy;

  /// No description provided for @testLatency.
  ///
  /// In en, this message translates to:
  /// **'Test latency'**
  String get testLatency;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @countryCount.
  ///
  /// In en, this message translates to:
  /// **'Countries · {count}'**
  String countryCount(int count);

  /// No description provided for @selectionSavedForNextCoreStart.
  ///
  /// In en, this message translates to:
  /// **'The saved selection will be used the next time the core starts.'**
  String get selectionSavedForNextCoreStart;

  /// No description provided for @noOutboundGroupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No outbound groups are available.'**
  String get noOutboundGroupsAvailable;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}} · {type}'**
  String groupMembers(int count, String type);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
