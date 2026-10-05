import 'package:material_ui/material_ui.dart';
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
    final segments = [
      ButtonSegment(value: null, label: Text(l10n.all)),
      ButtonSegment(value: LogLevel.error, label: Text(l10n.err)),
      ButtonSegment(value: LogLevel.warning, label: Text(l10n.warn)),
      ButtonSegment(value: LogLevel.info, label: Text(l10n.info)),
    ];
    final filter = SegmentedButton<LogLevel?>(
      segments: segments,
      selected: {levelFilter},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) onLevelChanged(selected.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
            decoration: InputDecoration(
              hintText: l10n.searchLogs,
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: onSearchChanged,
          );
          final pause = IconButton(
            onPressed: onPauseToggle,
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
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
                filter,
              ],
            );
          }
          return Row(
            children: [
              pause,
              const SizedBox(width: 8),
              Expanded(child: search),
              const SizedBox(width: 8),
              filter,
            ],
          );
        },
      ),
    );
  }
}
