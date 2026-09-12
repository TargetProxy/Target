import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../data/models/subscription.dart';
import '../../../l10n/app_localizations.dart';
import '../../proxies/application/proxy_catalog.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../../subscriptions/presentation/widgets/add_subscription_sheet.dart';

class ProfilesWorkspacePage extends ConsumerWidget {
  const ProfilesWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsProvider);
    final notifier = ref.read(subscriptionsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final busy = state.busy || state.changingIds.isNotEmpty;
    final nodeCount = ref
        .watch(proxyCatalogProvider)
        .groups
        .expand((group) => group.nodes)
        .map((node) => node.id)
        .toSet()
        .length;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: TargetPageLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TargetPageHeader(
                title: l10n.profiles,
                subtitle: l10n.subscriptionsHint,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => _addSubscription(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSubscription),
                  ),
                  IconButton(
                    onPressed: busy ? null : notifier.load,
                    tooltip: l10n.refreshPool,
                    icon: const Icon(Icons.refresh),
                  ),
                  Text(
                    l10n.poolSummary(
                      state.subscriptions.where((sub) => sub.enabled).length,
                      nodeCount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.lastError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (state.subscriptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    l10n.noSubscriptionsHint,
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final subscription in state.subscriptions) ...[
                Card(
                  key: ValueKey('subscription-${subscription.id}'),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        key: ValueKey('enable-${subscription.id}'),
                        value: subscription.enabled,
                        onChanged: busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  notifier.setEnabled(subscription.id, value);
                                }
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(subscription.name),
                        subtitle: Text(
                          '${l10n.poolNodeCount(subscription.nodeCount)} · ${subscription.enabled ? l10n.includedInPool : l10n.excludedFromPool}',
                        ),
                        secondary:
                            state.changingIds.contains(subscription.id) ||
                                subscription.updateStatus ==
                                    SubscriptionUpdateStatus.updating
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                onPressed: busy
                                    ? null
                                    : () => notifier.updateSubscription(
                                        subscription.id,
                                      ),
                                tooltip: l10n.updateSubscription,
                                icon: const Icon(Icons.refresh),
                              ),
                      ),
                      ExpansionTile(
                        key: PageStorageKey('details-${subscription.id}'),
                        title: Text(
                          l10n.subscriptionDetails,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            '${l10n.subscriptionAddress}: ${subscription.safeUrl}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.lastUpdated}: ${subscription.lastUpdatedAt == null ? l10n.neverUpdated : DateFormat.yMMMd(l10n.localeName).add_Hm().format(subscription.lastUpdatedAt!.toLocal())}',
                          ),
                          Text(
                            '${l10n.trafficUsed}: ${formatBytes(subscription.uploadBytes + subscription.downloadBytes)}',
                          ),
                          if (subscription.lastError?.isNotEmpty == true)
                            Text(
                              subscription.lastError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSubscription(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddSubscriptionSheet(),
    );
    if (result == null || !context.mounted) return;
    final url = result['url']?.trim();
    if (url == null || url.isEmpty) return;
    await ref
        .read(subscriptionsProvider.notifier)
        .addSubscription(url, name: result['name']);
  }
}
