import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

class LogToolbar extends StatelessWidget {
  const LogToolbar({
    required this.paused,
    required this.levelFilter,
    required this.onPauseToggle,
    required this.onLevelChanged,
    required this.onSearchChanged,
    super.key,
  });

  final bool paused;
  final LogLevel? levelFilter;
  final VoidCallback onPauseToggle;
  final ValueChanged<LogLevel?> onLevelChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onPauseToggle,
            icon: Icon(paused ? Icons.play_arrow : Icons.pause),
            tooltip: paused ? 'Resume' : 'Pause',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search logs...',
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<LogLevel?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: LogLevel.error, label: Text('Err')),
              ButtonSegment(value: LogLevel.warning, label: Text('Warn')),
              ButtonSegment(value: LogLevel.info, label: Text('Info')),
            ],
            selected: {levelFilter},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) onLevelChanged(selected.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
