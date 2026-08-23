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
  String get logs => '日志';
}
