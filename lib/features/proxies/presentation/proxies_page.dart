import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/proxies_notifier.dart';
import 'widgets/mode_selector.dart';
import 'widgets/proxy_group_tabs.dart';
import 'widgets/proxy_node_detail_sheet.dart';
import 'widgets/proxy_node_tile.dart';

class ProxiesPage extends ConsumerStatefulWidget {
  const ProxiesPage({super.key});

  @override
  ConsumerState<ProxiesPage> createState() => _ProxiesPageState();
}

class _ProxiesPageState extends ConsumerState<ProxiesPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proxiesProvider);
    final notifier = ref.read(proxiesProvider.notifier);
    final nodes = state.filteredNodes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proxies'),
        actions: [
          IconButton(onPressed: _showSearch, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: notifier.toggleSortOrder,
            icon: Icon(
              state.sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ModeSelector(
              mode: state.mode,
              onChanged: notifier.setMode,
            ),
          ),
          ProxyGroupTabs(
            groups: state.groups,
            selectedIndex: state.selectedGroupIndex,
            onSelected: notifier.selectGroup,
          ),
          const SizedBox(height: AppSpacing.smallGap),
          Expanded(
            child: nodes.isEmpty
                ? const EmptyState(
                    icon: Icons.hub_outlined,
                    title: 'No nodes available',
                    description: 'Add a subscription to get proxy nodes.',
                  )
                : ListView.builder(
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return ProxyNodeTile(
                        node: node,
                        onTap: () => notifier.selectNode(node.id),
                        onLongPress: () => _showDetail(node),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.testing ? null : () => _testLatency(notifier),
        child: state.testing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.speed),
      ),
    );
  }

  Future<void> _testLatency(ProxiesNotifier notifier) async {
    await notifier.testAllLatency();
    if (!mounted) return;
    final error = ref.read(proxiesProvider).lastError;
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSearch() {
    final notifier = ref.read(proxiesProvider.notifier);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search nodes'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Name, type, or region...',
          ),
          onChanged: notifier.setSearchQuery,
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.setSearchQuery('');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showDetail(dynamic node) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ProxyNodeDetailSheet(node: node),
    );
  }
}
