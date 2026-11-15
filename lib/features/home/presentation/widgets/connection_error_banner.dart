import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../app/router.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../l10n/app_localizations.dart';
import '../dashboard/card.dart';

class ConnectionErrorBanner extends StatelessWidget {
  const ConnectionErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DashboardCard(
      side: BorderSide(color: scheme.error.withValues(alpha: .45)),
      onTap: () => context.go(AppRoute.logs.path),
      child: Row(
        spacing: 14,
        children: [
          GlyphIcon(AppGlyphs.error, color: scheme.error),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  AppLocalizations.of(context).connectionError,
                  style: AppTextStyle.subheadline.of(context, emphasized: true),
                ),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.footnote
                      .of(context)
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const GlyphIcon(AppGlyphs.chevronForward),
        ],
      ),
    );
  }
}
