import 'package:material_ui/material_ui.dart';
import 'abstract_world_map.dart';

/// 首页可复用的世界地图卡片 — 抽象剪影风格（模仿截图）
/// 不再使用 OSM 瓦片，保持暗色主题与现有 Dashboard 一致
class HomeWorldMapCard extends StatefulWidget {
  const HomeWorldMapCard({super.key});

  @override
  State<HomeWorldMapCard> createState() => _HomeWorldMapCardState();
}

class _HomeWorldMapCardState extends State<HomeWorldMapCard> {
  String _selected = 'AR';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.public, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('节点地图', style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('抽象 · 10 节点',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AbstractWorldMap(
              height: 380,
              selectedId: _selected,
              onSelect: (id) => setState(() => _selected = id),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('点击国旗切换选择（当前：$_selected）',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selected = 'AR'),
                  child: const Text('重置'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
