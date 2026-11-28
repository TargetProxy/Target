import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:intl/date_symbol_data_local.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../l10n/app_localizations.dart';

const targetLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  TargetUiLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

class TargetUiLocalizations extends UiLocalizations {
  TargetUiLocalizations(this.locale);

  final Locale locale;
  bool get _zh => locale.languageCode == 'zh';
  static const delegate = _TargetUiLocalizationsDelegate();

  @override
  String get back => _zh ? '返回' : 'Back';

  @override
  String get cancel => _zh ? '取消' : 'Cancel';

  @override
  String get clearSearch => _zh ? '清除搜索' : 'Clear search';

  @override
  String get close => _zh ? '关闭' : 'Close';

  @override
  String get copy => _zh ? '复制' : 'Copy';

  @override
  String get cut => _zh ? '剪切' : 'Cut';

  @override
  String get dialog => _zh ? '对话框' : 'Dialog';

  @override
  String get hidePassword => _zh ? '隐藏密码' : 'Hide password';

  @override
  String get more => _zh ? '更多' : 'More';

  @override
  String get noSearchResults => _zh ? '没有搜索结果' : 'No search results';

  @override
  String get paste => _zh ? '粘贴' : 'Paste';

  @override
  String get reset => _zh ? '重置' : 'Reset';

  @override
  String get select => _zh ? '选择' : 'Select';

  @override
  String get search => _zh ? '搜索' : 'Search';

  @override
  String get selectAll => _zh ? '全选' : 'Select all';

  @override
  String get showLess => _zh ? '收起' : 'Show less';

  @override
  String get showMore => _zh ? '展开' : 'Show more';

  @override
  String get showPassword => _zh ? '显示密码' : 'Show password';

  @override
  String get sort => _zh ? '排序' : 'Sort';

  @override
  String get submit => _zh ? '提交' : 'Submit';
}

class _TargetUiLocalizationsDelegate
    extends LocalizationsDelegate<UiLocalizations> {
  const _TargetUiLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<UiLocalizations> load(Locale locale) async {
    await initializeDateFormatting();
    return TargetUiLocalizations(locale);
  }

  @override
  bool shouldReload(_TargetUiLocalizationsDelegate old) => false;
}
