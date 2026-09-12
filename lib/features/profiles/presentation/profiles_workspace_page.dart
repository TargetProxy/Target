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
                          _DetailRow(
                            label: l10n.subscriptionAddress,
                            value: subscription.safeUrl,
                            selectable: true,
                          ),
                          _DetailRow(
                            label: l10n.lastUpdated,
                            value: subscription.lastUpdatedAt == null
                                ? l10n.neverUpdated
                                : DateFormat.yMMMd(
                                    l10n.localeName,
                                  ).add_Hm().format(
                                    subscription.lastUpdatedAt!.toLocal(),
                                  ),
                          ),
                          _DetailRow(
                            label: l10n.subscriptionNodes,
                            value: '${subscription.nodeCount}',
                          ),
                          _DetailRow(
                            label: l10n.automaticUpdates,
                            value: subscription.autoUpdate
                                ? l10n.enabled
                                : l10n.disabled,
                          ),
                          _DetailRow(
                            label: l10n.updateInterval,
                            value: _formatInterval(
                              subscription.updateIntervalSeconds,
                              disabledLabel: l10n.disabled,
                            ),
                          ),
                          _DetailRow(
                            label: l10n.trafficUsed,
                            value: formatBytes(
                              subscription.uploadBytes +
                                  subscription.downloadBytes,
                            ),
                          ),
                          if (subscription.expiresAt != null)
                            _DetailRow(
                              label: l10n.expires,
                              value: DateFormat.yMMMd(l10n.localeName)
                                  .add_Hm()
                                  .format(subscription.expiresAt!.toLocal()),
                            ),
                          if (subscription.profileTitle?.isNotEmpty == true)
                            _DetailRow(
                              label: l10n.profile,
                              value: subscription.profileTitle!,
                            ),
                          if (subscription.webPageUrl?.isNotEmpty == true)
                            _DetailRow(
                              label: l10n.webPage,
                              value: subscription.webPageUrl!,
                              selectable: true,
                            ),
                          if (subscription.supportUrl?.isNotEmpty == true)
                            _DetailRow(
                              label: l10n.support,
                              value: subscription.supportUrl!,
                              selectable: true,
                            ),
                          if (subscription.lastError?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                subscription.lastError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
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

  static String _formatInterval(int seconds, {required String disabledLabel}) {
    if (seconds <= 0) return disabledLabel;
    final hours = seconds ~/ 3600;
    if (hours > 0 && seconds % 3600 == 0) {
      return '$hours h';
    }
    final minutes = seconds ~/ 60;
    if (minutes > 0 && seconds % 60 == 0) {
      return '$minutes min';
    }
    return '$seconds s';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final valueWidget = selectable
        ? SelectionArea(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          )
        : Text(value, softWrap: true);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 132, child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}
