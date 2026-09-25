import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/target_page_layout.dart';
import '../../../data/models/proxy_node.dart';
import '../../../l10n/app_localizations.dart';
import '../../maps/application/proxy_country_map.dart';
import '../../maps/presentation/widgets/abstract_world_map.dart';
import '../../smart_connect/application/smart_connect_notifier.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../application/proxies_notifier.dart';

class NodePoolPage extends ConsumerStatefulWidget {
  const NodePoolPage({super.key});

  @override
  ConsumerState<NodePoolPage> createState() => _NodePoolPageState();
}

class _NodePoolPageState extends ConsumerState<NodePoolPage> {
  final _search = TextEditingController();
  String? _source;
  String? _country;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editSmartPreference(ProxyNode node) async {
    final smart = ref.read(smartConnectProvider);
    final current =
        smart.snapshot.nodes.where((n) => n.id == node.id).firstOrNull ?? node;
    final result = await showDialog<NodePreference>(
      context: context,
      builder: (_) => _NodePreferenceDialog(node: current),
    );
    if (result == null || !mounted) return;
    try {
      await ref
          .read(smartConnectProvider.notifier)
          .savePreference(node.id, result);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Color _latencyColor(BuildContext context, ProxyNode node) {
    final scheme = Theme.of(context).colorScheme;
    if (node.latencyTimedOut) return scheme.error;
    final latency = node.latencyMs;
    if (latency == null) return scheme.onSurfaceVariant;
    if (latency <= 200) return Colors.green;
    if (latency <= 500) return Colors.orange.shade700;
    if (latency <= 1000) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final proxies = ref.watch(proxiesProvider);
    final subscriptions = ref.watch(subscriptionsProvider);
    final notifier = ref.read(proxiesProvider.notifier);
    final enabled = subscriptions.subscriptions.where((sub) => sub.enabled);
    final names = {
      for (final sub in subscriptions.subscriptions) sub.id: sub.name,
    };
    final source = enabled.any((sub) => sub.id == _source) ? _source : null;
    final nodes = proxies.selectedGroup?.nodes ?? const <ProxyNode>[];
    final query = _search.text.trim().toLowerCase();
    String sourceName(ProxyNode node) =>
        names[node.subscriptionId] ?? l10n.unknownSource;
    final matching = nodes
        .where(
          (node) =>
              (source == null || node.subscriptionId == source) &&
              (query.isEmpty ||
                  '${node.name} ${node.type} ${proxyNodeCountryCode(node) ?? ''} ${sourceName(node)}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    final countries = proxyCountryMapEntries(matching);
    final country = countries.any((entry) => entry.countryCode == _country)
        ? _country
        : null;
    final visible = matching
        .where(
          (node) => country == null || proxyNodeCountryCode(node) == country,
        )
        .toList();
    final busy = subscriptions.busy || subscriptions.changingIds.isNotEmpty;
    final error = proxies.lastError ?? subscriptions.lastError;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TargetPageLayout.maxWidth + 48,
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: TargetPageLayout.padding,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TargetPageHeader(
                        title:
                            Localizations.localeOf(context).languageCode == 'zh'
                            ? '节点库与地图'
                            : 'Node library & map',
                        subtitle:
                            Localizations.localeOf(context).languageCode == 'zh'
                            ? '查看节点、测速与候选偏好。出口请在代理分组中选择。'
                            : 'Inspect nodes, latency and candidate preferences. Choose routes in Proxy groups.',
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/smart-connect'),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.nodeSelection),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: proxies.testing || nodes.isEmpty
                                ? null
                                : notifier.testAllLatency,
                            icon: const Icon(Icons.speed),
                            label: Text(l10n.testLatency),
                          ),
                          if (proxies.testing)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (nodes.isNotEmpty) ...[
                        AbstractWorldMap(
                          height: 320,
                          nodes: countries,
                          selectedId: country,
                          onSelect: (value) => setState(() => _country = value),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allRegions),
                              selected: country == null,
                              onSelected: (_) =>
                                  setState(() => _country = null),
                            ),
                            for (final entry in countries)
                              ChoiceChip(
                                key: ValueKey('region-${entry.countryCode}'),
                                label: Text(
                                  '${entry.countryCode} · ${entry.nodeCount}',
                                ),
                                selected: country == entry.countryCode,
                                onSelected: (value) => setState(
                                  () => _country = value
                                      ? entry.countryCode
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.searchNodes,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allSubscriptions),
                              selected: source == null,
                              onSelected: (_) => setState(() {
                                _source = null;
                                _country = null;
                              }),
                            ),
                            for (final sub in enabled)
                              ChoiceChip(
                                key: ValueKey('source-${sub.id}'),
                                label: Text(sub.name),
                                selected: source == sub.id,
                                onSelected: (value) => setState(() {
                                  _source = value ? sub.id : null;
                                  _country = null;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.poolNodeCount(visible.length),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                      if (visible.isEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          nodes.isEmpty ? l10n.emptyPool : l10n.noMatchingNodes,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: nodes.isEmpty
                                ? () => context.go('/proxies')
                                : () => setState(() {
                                    _search.clear();
                                    _source = null;
                                    _country = null;
                                  }),
                            child: Text(
                              nodes.isEmpty
                                  ? l10n.manageSubscriptions
                                  : l10n.clearFilters,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final node = visible[index];
                    return ListTile(
                      key: ValueKey('node-${node.id}'),
                      dense: true,

                      title: Text(
                        node.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${sourceName(node)} · ${node.typeLabel}${node.isAvailable ? '' : ' · ${l10n.nodeUnavailable}'}',
                      ),
                      trailing: Text(
                        node.latencyTimedOut
                            ? 'timeout'
                            : (node.latencyMs == null
                                  ? '—'
                                  : '${node.latencyMs} ms'),
                        style: TextStyle(
                          color: _latencyColor(context, node),
                          fontWeight: node.latencyTimedOut
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: 'Smart Connect node preferences',
                            onPressed: busy
                                ? null
                                : () => _editSmartPreference(node),
                          ),
                        ],
                      ),
                      enabled: node.isAvailable,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodePreferenceDialog extends StatefulWidget {
  const _NodePreferenceDialog({required this.node});

  final ProxyNode node;

  @override
  State<_NodePreferenceDialog> createState() => _NodePreferenceDialogState();
}

class _NodePreferenceDialogState extends State<_NodePreferenceDialog> {
  late bool _enabled = widget.node.enabled;
  late bool _excluded = widget.node.excluded;
  late bool _favorite = widget.node.favorite;
  late final TextEditingController _tags = TextEditingController(
    text: widget.node.tags.join(', '),
  );
  late final TextEditingController _priority = TextEditingController(
    text: '${widget.node.subscriptionPriority}',
  );

  @override
  void dispose() {
    _tags.dispose();
    _priority.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return AlertDialog(
      title: Text(node.name.isEmpty ? node.id : node.name),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Enabled for Smart Connect'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile(
              title: const Text('Exclude from Smart Connect'),
              value: _excluded,
              onChanged: (value) => setState(() => _excluded = value),
            ),
            SwitchListTile(
              title: const Text('Favorite'),
              value: _favorite,
              onChanged: (value) => setState(() => _favorite = value),
            ),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tags, comma separated',
              ),
            ),
            TextField(
              controller: _priority,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Subscription priority (higher wins ties)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final priority = int.tryParse(_priority.text);
            if (priority == null) return;
            Navigator.pop(
              context,
              NodePreference(
                enabled: _enabled,
                excluded: _excluded,
                favorite: _favorite,
                tags: _tags.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toSet(),
                subscriptionPriority: priority,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
