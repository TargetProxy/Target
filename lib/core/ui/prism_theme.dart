import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

abstract final class PrismTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: brightness,
      style: ColorStyle.vivid,
    );
    return ThemeData(
      colorScheme: scheme,
      elevatedColorScheme: brightness == Brightness.dark ? scheme.elevated : null,
    );
  }
}
