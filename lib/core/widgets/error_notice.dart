import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../ui/app_glyphs.dart';

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    inert: true,
    child: ListRow(
      leading: GlyphIcon(AppGlyphs.error, color: context.colorScheme.error),
      title: SelectableText(
        message,
        style: AppTextStyle.subheadline.of(context),
      ),
    ),
  );
}
