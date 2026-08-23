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
  String get logs => 'Logs';
}
