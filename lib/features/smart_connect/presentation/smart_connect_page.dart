import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/application/settings_notifier.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../application/smart_connect_notifier.dart';
import '../application/smart_policy_notifier.dart';
import '../domain/smart_connect_models.dart';
import 'smart_policy_editor.dart';

class SmartConnectPage extends ConsumerStatefulWidget {
  const SmartConnectPage({super.key});
  @override
  ConsumerState<SmartConnectPage> createState() => _SmartConnectPageState();
}

class _SmartConnectPageState extends ConsumerState<SmartConnectPage> {
  final _expanded = <String>{};
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(smartConnectProvider.notifier).refresh();
    });
  }

  Future<void> _edit([SmartPolicy? policy]) async {
    final result = await showDialog<SmartPolicy>(
      context: context,
      builder: (_) => SmartPolicyEditor(policy: policy),
    );
    if (result != null && mounted) {
      try {
        await ref.read(smartPoliciesProvider.notifier).savePolicy(result);
      } on Object catch (error) {
        if (mounted) _message(error.toString());
      }
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _showText(String title, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(child: SelectableText(text)),
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  Future<void> _import() async {
    final text = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import service policies'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: text,
            minLines: 8,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText:
                  'Paste exported policy JSON. Matching service IDs will be updated.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      try {
        final values = jsonDecode(text.text) as List;
        await ref.read(smartPoliciesProvider.notifier).importPolicies([
          for (final v in values)
            SmartPolicy.fromJson(Map<String, dynamic>.from(v as Map)),
        ]);
        if (mounted) {
          _message(
            'Policies imported. Existing bindings require explicit re-evaluation.',
          );
        }
      } on Object {
        if (mounted) {
          _message(
            'Import failed. Check policy fields, service IDs and domain conflicts.',
          );
        }
      }
    }
    text.dispose();
  }

  Future<void> _diagnostics() async {
    final state = ref.read(smartConnectProvider);
    await _showText(
      'Export diagnostics',
      const JsonEncoder.withIndent('  ').convert({
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'enabled': ref.read(settingsProvider).settings.smartConnectEnabled,
        'runtimeRevision': state.snapshot.revision,
        'poolRevision': state.snapshot.poolRevision,
        'running': state.snapshot.running,
        'bindings': [
          for (final b in state.bindings.values)
            {
              'serviceId': b.serviceId,
              'nodeId': b.nodeId,
              'effective': b.effective,
              'needsEvaluation': b.needsEvaluation,
              'selectedAt': b.selectedAt.toIso8601String(),
              'expiresAt': b.expiresAt.toIso8601String(),
              'score': b.score,
              'policyRevision': b.policyRevision,
            },
        ],
        'audit': state.logs,
      }),
    );
  }

  Future<void> _template(String service) async {
    final presets = <String, SmartPolicy>{
      'chatgpt': const SmartPolicy(
        id: 'chatgpt',
        name: 'ChatGPT',
        domains: {'chatgpt.com', 'openai.com'},
        allowedRegions: {'SG', 'JP', 'US'},
        preferredRegions: {'SG'},
        probeTargets: [
          SmartProbeTarget(
            url: 'https://chatgpt.com/',
            egressUrl: 'https://api.country.is/',
          ),
        ],
      ),
      'disney': const SmartPolicy(
        id: 'disney',
        name: 'Disney+',
        domains: {'disneyplus.com'},
        allowedRegions: {'US'},
        probeTargets: [
          SmartProbeTarget(
            url: 'https://www.disneyplus.com/',
            egressUrl: 'https://api.country.is/',
          ),
        ],
      ),
      'youtube': const SmartPolicy(
        id: 'youtube',
        name: 'YouTube',
        domains: {'youtube.com', 'googlevideo.com'},
        preferredRegions: {'JP'},
        probeTargets: [
          SmartProbeTarget(
            url: 'https://www.youtube.com/',
            egressUrl: 'https://api.country.is/',
          ),
        ],
      ),
      'direct': const SmartPolicy(
        id: 'direct',
        name: 'Direct',
        domains: {'example.cn'},
        selectionMode: SmartSelectionMode.direct,
      ),
    };
    await _edit(presets[service]);
  }

  Future<void> _nodePreference(SmartNode node) async {
    var enabled = node.enabled,
        excluded = node.excluded,
        favorite = node.favorite;
    final tags = TextEditingController(text: node.tags.join(', '));
    final priority = TextEditingController(
      text: '${node.subscriptionPriority}',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(node.name.isEmpty ? node.id : node.name),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enabled for Smart Connect'),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                SwitchListTile(
                  title: const Text('Exclude from Smart Connect'),
                  value: excluded,
                  onChanged: (v) => setState(() => excluded = v),
                ),
                SwitchListTile(
                  title: const Text('Favorite'),
                  value: favorite,
                  onChanged: (v) => setState(() => favorite = v),
                ),
                TextField(
                  controller: tags,
                  decoration: const InputDecoration(
                    labelText: 'Tags, comma separated',
                  ),
                ),
                TextField(
                  controller: priority,
                  decoration: const InputDecoration(
                    labelText: 'Subscription priority (higher wins ties)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (int.tryParse(priority.text) != null) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      try {
        final store = ref.read(smartPolicyStoreProvider);
        await store.saveNodePreference(
          node.id,
          SmartNodePreference(
            enabled: enabled,
            excluded: excluded,
            favorite: favorite,
            tags: tags.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet(),
          ),
        );
        await store.saveSubscriptionPriority(
          node.subscriptionId,
          int.parse(priority.text),
        );
        await ref.read(smartConnectProvider.notifier).refresh();
      } on Object catch (e) {
        if (mounted) _message(e.toString());
      }
    }
    tags.dispose();
    priority.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartConnectProvider);
    final notifier = ref.read(smartConnectProvider.notifier);
    final enabled = ref.watch(settingsProvider).settings.smartConnectEnabled;
    final policies = ref.watch(smartPoliciesProvider);
    final subscriptions = ref.watch(subscriptionsProvider).subscriptions;
    final names = {for (final s in subscriptions) s.id: s.name};
    final busy = state.busy || state.evaluating;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Connect · Experimental'),
        actions: [
          IconButton(
            onPressed: enabled && !busy ? notifier.refresh : null,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh actual runtime',
          ),
          IconButton(
            onPressed: () => _showText(
              'Selection audit',
              const JsonEncoder.withIndent('  ').convert(state.logs),
            ),
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Selection audit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Smart Connect'),
            subtitle: const Text(
              'Optional service routing. Evaluate first, then explicitly apply a binding.',
            ),
            value: enabled,
            onChanged: state.busy ? null : notifier.setEnabled,
          ),
          if (!enabled)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Smart Connect is off. Configure policies here; ordinary proxy selection remains available.',
                ),
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SelectableText(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (state.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(state.message),
            ),
          if (busy) const LinearProgressIndicator(),
          if (state.evaluating)
            TextButton.icon(
              onPressed: notifier.cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text('Cancel evaluation · ${state.activeService}'),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Add service'),
              ),
              PopupMenuButton<String>(
                onSelected: _template,
                enabled: !busy,
                itemBuilder: (_) => [
                  for (final value in [
                    'chatgpt',
                    'disney',
                    'youtube',
                    'direct',
                  ])
                    PopupMenuItem(value: value, child: Text(value)),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Use template'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : _import,
                child: const Text('Import policies'),
              ),
              TextButton(
                onPressed: _diagnostics,
                child: const Text('Export diagnostics'),
              ),
              TextButton(
                onPressed: policies.value == null
                    ? null
                    : () => _showText(
                        'Export policies',
                        const JsonEncoder.withIndent('  ').convert(
                          policies.value!.map((p) => p.toJson()).toList(),
                        ),
                      ),
                child: const Text('Export policies'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          policies.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load policies: $error'),
            data: (items) => Column(
              children: [
                if (items.isEmpty)
                  const ListTile(
                    title: Text('No service policies'),
                    subtitle: Text('Add a service or choose a template.'),
                  ),
                for (final policy in items)
                  Builder(
                    builder: (context) {
                      final binding = state.bindings[policy.id];
                      final assessment = state.assessments[policy.id];
                      final stale =
                          binding != null &&
                          (binding.policyRevision != policy.revision ||
                              !binding.valid);
                      final node = state.snapshot.nodes
                          .where((n) => n.id == binding?.nodeId)
                          .firstOrNull;
                      return Card(
                        child: ExpansionTile(
                          key: ValueKey(policy.id),
                          initiallyExpanded: _expanded.contains(policy.id),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              _expanded.add(policy.id);
                            } else {
                              _expanded.remove(policy.id);
                            }
                          },
                          title: Text(
                            policy.name.isEmpty ? policy.id : policy.name,
                          ),
                          subtitle: Text(
                            binding == null
                                ? 'Unbound · ${policy.domains.join(", ")}'
                                : '${node?.name.isNotEmpty == true ? node!.name : binding.nodeId} · ${names[node?.subscriptionId] ?? node?.subscriptionId ?? "Direct"}\n${binding.effective ? "Effective" : "Not effective"}${stale ? " · Re-evaluation required" : ""}',
                          ),
                          childrenPadding: const EdgeInsets.all(16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allowed: ${policy.allowedRegions.isEmpty ? "Any" : policy.allowedRegions.join(", ")} · Preferred: ${policy.preferredRegions.join(", ")}',
                            ),
                            if (binding != null)
                              SelectableText(
                                'Score ${binding.score.toStringAsFixed(1)} · Selected ${binding.selectedAt.toLocal()} · Expires ${binding.expiresAt.toLocal()}\n${binding.reason}\n${binding.status}',
                              ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: enabled && !busy && policy.enabled
                                      ? () => notifier.evaluate(policy)
                                      : null,
                                  child: const Text('Re-evaluate'),
                                ),
                                FilledButton(
                                  onPressed:
                                      enabled &&
                                          !busy &&
                                          assessment?.selection.succeeded ==
                                              true &&
                                          policy.selectionMode !=
                                              SmartSelectionMode.manual
                                      ? () => notifier.apply(policy.id)
                                      : null,
                                  child: const Text('Apply result'),
                                ),
                                TextButton(
                                  onPressed: busy ? null : () => _edit(policy),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => notifier.removePolicy(policy.id),
                                  child: const Text('Remove'),
                                ),
                                if (binding != null)
                                  TextButton(
                                    onPressed: !enabled || busy
                                        ? null
                                        : () async {
                                            try {
                                              final rows = await ref
                                                  .read(smartRepositoryProvider)
                                                  .history(
                                                    policy,
                                                    binding.nodeId,
                                                  );
                                              if (mounted) {
                                                await _showText(
                                                  'Probe history',
                                                  rows
                                                      .map(
                                                        (n) =>
                                                            '${n.testedAt?.toLocal()} · ${n.latencyMs} ms · ${n.effectiveRegion} · ${n.failureReason.isEmpty ? "READY" : n.failureReason}',
                                                      )
                                                      .join('\n'),
                                                );
                                              }
                                            } on Object catch (e) {
                                              if (mounted) {
                                                _message(e.toString());
                                              }
                                            }
                                          },
                                    child: const Text('History'),
                                  ),
                              ],
                            ),
                            if (assessment != null) ...[
                              Text(assessment.selection.reason),
                              for (final n in assessment.nodes)
                                ListTile(
                                  dense: true,
                                  title: Text(n.name.isEmpty ? n.id : n.name),
                                  subtitle: Text(
                                    '${names[n.subscriptionId] ?? n.subscriptionId} · ${n.effectiveRegion} · ${n.latencyMs ?? "—"} ms · ${n.testedAt?.toLocal() ?? "Untested"}\n${assessment.selection.excluded[n.id] ?? "Eligible · score ${assessment.selection.scores[n.id]?.toStringAsFixed(1)}"}',
                                  ),
                                  trailing:
                                      assessment.selection.scores.containsKey(
                                        n.id,
                                      )
                                      ? TextButton(
                                          onPressed: enabled && !busy
                                              ? () => notifier.apply(
                                                  policy.id,
                                                  manualNodeId: n.id,
                                                )
                                              : null,
                                          child: const Text('Use node'),
                                        )
                                      : null,
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Unified node pool · ${state.snapshot.nodes.length}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final node in state.snapshot.nodes)
            ListTile(
              title: Text(
                '${node.favorite ? "★ " : ""}${node.name.isEmpty ? node.id : node.name}',
              ),
              subtitle: Text(
                '${names[node.subscriptionId] ?? node.subscriptionId} · ${node.protocol} · ${node.region.isEmpty ? "Unknown region" : node.region} · ${!node.enabled
                    ? "Disabled"
                    : node.excluded
                    ? "Excluded"
                    : "Enabled"}\n${node.id}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Smart Connect node preferences',
                onPressed: busy ? null : () => _nodePreference(node),
              ),
            ),
        ],
      ),
    );
  }
}
