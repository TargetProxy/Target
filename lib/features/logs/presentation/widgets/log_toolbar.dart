import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../core/ui/app_glyphs.dart';
import 'package:talker/talker.dart';

import '../../../../l10n/app_localizations.dart';

class LogToolbar extends StatelessWidget {
  const LogToolbar({
    required this.paused,
    required this.l10n,
    required this.levelFilter,
    required this.onPauseToggle,
    required this.onLevelChanged,
    required this.onSearchChanged,
    super.key,
  });

  final bool paused;
  final AppLocalizations l10n;
  final LogLevel? levelFilter;
  final VoidCallback onPauseToggle;
  final ValueChanged<LogLevel?> onLevelChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final filter = SegmentedControl<LogLevel?>(
      segments: [
        (null, l10n.all),
        (LogLevel.error, l10n.err),
        (LogLevel.warning, l10n.warn),
        (LogLevel.info, l10n.info),
      ],
      value: levelFilter,
      onChanged: onLevelChanged,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = SearchField(
            hintText: l10n.searchLogs,
            onChanged: onSearchChanged,
          );
          final pause = IconButton(
            onPressed: onPauseToggle,
            icon: GlyphIcon(AppGlyphs.playPause(paused ? 0 : 1)),
            tooltip: paused ? l10n.resume : l10n.pause,
          );
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    pause,
                    const SizedBox(width: 8),
                    Expanded(child: search),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(width: 280, child: filter),
              ],
            );
          }
          return Row(
            children: [
              pause,
              const SizedBox(width: 8),
              Expanded(child: search),
              const SizedBox(width: 8),
              SizedBox(width: 280, child: filter),
            ],
          );
        },
      ),
    );
  }
}
