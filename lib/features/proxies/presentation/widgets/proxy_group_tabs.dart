import 'package:material_ui/material_ui.dart';

import '../../../../data/models/proxy_group.dart';

class ProxyGroupTabs extends StatelessWidget {
  const ProxyGroupTabs({
    required this.groups,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<ProxyGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = index == selectedIndex;

          return ChoiceChip(
            label: Text(group.name),
            selected: isSelected,
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}
