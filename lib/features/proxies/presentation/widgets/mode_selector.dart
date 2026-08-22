import 'package:material_ui/material_ui.dart';

import '../../application/proxies_notifier.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({required this.mode, required this.onChanged, super.key});

  final ProxyMode mode;
  final ValueChanged<ProxyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ProxyMode>(
      segments: const [
        ButtonSegment(value: ProxyMode.rule, label: Text('Rule')),
        ButtonSegment(value: ProxyMode.global, label: Text('Global')),
        ButtonSegment(value: ProxyMode.direct, label: Text('Direct')),
      ],
      selected: {mode},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) onChanged(selected.first);
      },
    );
  }
}
