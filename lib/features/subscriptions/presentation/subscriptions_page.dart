import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../application/subscriptions_notifier.dart';
import 'widgets/add_subscription_sheet.dart';
import 'widgets/subscription_card.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsProvider);
    final subs = state.subscriptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            onPressed: state.busy ? null : _updateAll,
            icon: const Icon(Icons.sync),
            tooltip: 'Update all',
          ),
          IconButton(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add),
            tooltip: 'Add subscription',
          ),
        ],
      ),
      body: subs.isEmpty
          ? EmptyState(
              icon: Icons.rss_feed_outlined,
              title: 'No subscriptions',
              description: 'Add a subscription URL to get started.',
              action: FilledButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add Subscription'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SubscriptionCard(
                    subscription: sub,
                    onTap: () {},
                    onMenuSelected: (action) => _handleMenu(action, sub.id),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddSubscriptionSheet(),
    );

    if (result == null) return;
    final url = result['url'];
    if (url == null || url.isEmpty) return;

    final notifier = ref.read(subscriptionsProvider.notifier);
    final added = await notifier.addSubscription(url, name: result['name']);
    if (!mounted) return;
    if (!added) {
      _showError(
        ref.read(subscriptionsProvider).lastError ?? 'Subscription was not added.',
      );
      return;
    }
    final error = ref.read(subscriptionsProvider).lastError;
    if (error != null && error.isNotEmpty) {
      _showError(error);
    }
  }

  Future<void> _handleMenu(String action, String id) async {
    final notifier = ref.read(subscriptionsProvider.notifier);
    switch (action) {
      case 'use':
        await notifier.setActive(id);
      case 'update':
        await notifier.updateSubscription(id);
      case 'rename':
        _showRenameDialog(id);
      case 'delete':
        _showDeleteConfirm(id);
    }
  }

  Future<void> _updateAll() async {
    final notifier = ref.read(subscriptionsProvider.notifier);
    final ids = ref.read(subscriptionsProvider).subscriptions.map((s) => s.id).toList();
    for (final id in ids) {
      await notifier.updateSubscription(id);
    }
  }

  void _showRenameDialog(String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(subscriptionsProvider.notifier)
                    .renameSubscription(id, name);
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(subscriptionsProvider.notifier)
                  .removeSubscription(id);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
