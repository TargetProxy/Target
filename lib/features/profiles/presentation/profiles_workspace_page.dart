import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format_bytes.dart';
import '../../../data/models/subscription.dart';
import '../../proxies/application/proxies_notifier.dart';
import '../../settings/application/settings_notifier.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../../subscriptions/presentation/widgets/add_subscription_sheet.dart';
import '../../maps/presentation/widgets/abstract_world_map.dart';

enum _ProfileSection { overview, proxies, configuration }

class ProfilesWorkspacePage extends ConsumerStatefulWidget {
  const ProfilesWorkspacePage({super.key});

  @override
  ConsumerState<ProfilesWorkspacePage> createState() =>
      _ProfilesWorkspacePageState();
}

class _ProfilesWorkspacePageState extends ConsumerState<ProfilesWorkspacePage> {
  String? _selectedId;
  _ProfileSection _section = _ProfileSection.overview;

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final profiles = subscriptions.subscriptions;
    final selected = _selectedProfile(profiles);
    final wide = MediaQuery
        .sizeOf(context)
        .width >= 820;

    if (!wide) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profiles')),
        body: selected == null
            ? _EmptyWorkspace(onAdd: _showAddSubscription)
            : _ProfileDetail(
          profile: selected,
          section: _section,
          onSectionChanged: (value) => setState(() => _section = value),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: _ProfileList(
              profiles: profiles,
              selectedId: selected?.id,
              busy: subscriptions.busy,
              onSelected: (id) {
                setState(() => _selectedId = id);
                Navigator.pop(context);
              },
              onAdd: _showAddSubscription,
              onRefresh: _refreshSelected,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 190,
          child: _ProfileList(
            profiles: profiles,
            selectedId: selected?.id,
            busy: subscriptions.busy,
            onSelected: (id) => setState(() => _selectedId = id),
            onAdd: _showAddSubscription,
            onRefresh: _refreshSelected,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? _EmptyWorkspace(onAdd: _showAddSubscription)
              : _ProfileDetail(
            profile: selected,
            section: _section,
            onSectionChanged: (value) => setState(() => _section = value),
          ),
        ),
      ],
    );
  }

  Subscription? _selectedProfile(List<Subscription> profiles) {
    if (profiles.isEmpty) return null;
    final requested = _selectedId;
    if (requested != null) {
      for (final profile in profiles) {
        if (profile.id == requested) return profile;
      }
    }
    return profiles.firstWhere(
          (profile) => profile.enabled,
      orElse: () => profiles.first,
    );
  }

  Future<void> _showAddSubscription() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddSubscriptionSheet(),
    );
    if (result == null || !mounted) return;
    final url = result['url']?.trim();
    if (url == null || url.isEmpty) return;

    final notifier = ref.read(subscriptionsProvider.notifier);
    final added = await notifier.addSubscription(url, name: result['name']);
    if (!mounted || added) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref
              .read(subscriptionsProvider)
              .lastError ??
              'Subscription was not added.',
        ),
      ),
    );
  }

  Future<void> _refreshSelected() async {
    final profiles = ref
        .read(subscriptionsProvider)
        .subscriptions;
    final selected = _selectedProfile(profiles);
    if (selected != null) {
      await ref
          .read(subscriptionsProvider.notifier)
          .updateSubscription(selected.id);
    }
  }
}

class _ProfileList extends StatelessWidget {
  const _ProfileList({
    required this.profiles,
    required this.selectedId,
    required this.busy,
    required this.onSelected,
    required this.onAdd,
    required this.onRefresh,
  });

  final List<Subscription> profiles;
  final String? selectedId;
  final bool busy;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profiles',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : onRefresh,
                  icon: busy
                      ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.refresh),
                  tooltip: 'Update profile',
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add profile',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Text(
              'PROFILE LIST',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: profiles.isEmpty
                ? Center(
              child: Text(
                'No profiles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  selected: profile.id == selectedId,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Icon(
                    profile.enabled
                        ? Icons.description
                        : Icons.description_outlined,
                    size: 20,
                  ),
                  title: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${profile.nodeCount} nodes',
                    maxLines: 1,
                  ),
                  trailing: profile.enabled
                      ? Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  )
                      : null,
                  onTap: () => onSelected(profile.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetail extends ConsumerWidget {
  const _ProfileDetail({
    required this.profile,
    required this.section,
    required this.onSectionChanged,
  });

  final Subscription profile;
  final _ProfileSection section;
  final ValueChanged<_ProfileSection> onSectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final busy = ref
        .watch(subscriptionsProvider)
        .busy;
    final notifier = ref.read(subscriptionsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.enabled ? 'Active profile' : 'Inactive profile',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: profile.enabled
                            ? Colors.green
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!profile.enabled)
                OutlinedButton.icon(
                  onPressed: () => notifier.setActive(profile.id),
                  icon: const Icon(Icons.check),
                  label: const Text('Use profile'),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: busy
                    ? null
                    : () => notifier.updateSubscription(profile.id),
                icon: const Icon(Icons.refresh),
                tooltip: 'Update',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: SegmentedButton<_ProfileSection>(
            segments: const [
              ButtonSegment(
                value: _ProfileSection.overview,
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Overview'),
              ),
              ButtonSegment(
                value: _ProfileSection.proxies,
                icon: Icon(Icons.account_tree_outlined),
                label: Text('Proxies'),
              ),
              ButtonSegment(
                value: _ProfileSection.configuration,
                icon: Icon(Icons.code),
                label: Text('Configuration'),
              ),
            ],
            selected: {section},
            onSelectionChanged: (value) => onSectionChanged(value.first),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (section) {
            _ProfileSection.overview => _Overview(profile: profile),
            _ProfileSection.proxies => const _Policy(),
            _ProfileSection.configuration => _Configuration(profile: profile),
          },
        ),
      ],
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.profile});

  final Subscription profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final used = profile.uploadBytes + profile.downloadBytes;
    final proxies = ref.watch(proxiesProvider);
    return _SectionScroll(
      children: [
        const _SectionTitle(
          icon: Icons.info_outline,
          title: 'Profile overview',
        ),
        _InfoCard(
          rows: [
            ('Status', profile.enabled ? 'Active' : 'Inactive'),
            ('Format', profile.formatHint.name),
            ('Nodes', '${profile.nodeCount}'),
            (
            'Last updated',
            profile.lastUpdatedAt?.toLocal().toString() ?? 'Never',
            ),
          ],
        ),
        const _SectionTitle(
          icon: Icons.cloud_download_outlined,
          title: 'Subscription',
        ),
        _InfoCard(
          rows: [
            ('Address', profile.safeUrl),
            ('Automatic updates', profile.autoUpdate ? 'Enabled' : 'Disabled'),
            (
            'Update interval',
            '${profile.updateIntervalSeconds ~/ 3600} hours',
            ),
            ('Traffic used', formatBytes(used)),
          ],
        ),
        const _SectionTitle(icon: Icons.account_tree_outlined, title: 'Policy'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: proxies.groups.isEmpty
                ? const Text('No proxy groups are available.')
                : Row(
              children: [
                _PolicyMetric(
                  label: 'Groups',
                  value: '${proxies.groups.length}',
                ),
                _PolicyMetric(
                  label: 'Nodes',
                  value:
                  '${proxies.groups.fold<int>(
                      0, (sum, group) => sum + group.nodes.length)}',
                ),
                _PolicyMetric(
                  label: 'Selected',
                  value:
                  '${proxies.groups
                      .where((group) => group.selectedNode != null)
                      .length}',
                ),
              ],
            ),
          ),
        ),
        if (profile.lastError != null)
          Card(
            color: Theme
                .of(context)
                .colorScheme
                .errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(profile.lastError!),
            ),
          ),
      ],
    );
  }
}

class _Configuration extends ConsumerWidget {
  const _Configuration({required this.profile});

  final Subscription profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref
        .watch(settingsProvider)
        .settings;
    return _SectionScroll(
      children: [
        const _SectionTitle(icon: Icons.tune, title: 'Runtime configuration'),
        _InfoCard(
          rows: [
            ('Proxy mode', settings.proxyMode.label),
            if (!Platform.isAndroid) ('Listen address', settings.listenAddress),
            if (!Platform.isAndroid) ('Mixed port', '${settings.mixedPort}'),
            ('IPv6', settings.ipv6 ? 'Enabled' : 'Disabled'),
            if (!Platform.isAndroid && settings.systemProxy)
              ('System proxy', 'Enabled'),
          ],
        ),
        const _SectionTitle(icon: Icons.code, title: 'Configuration source'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.formatHint == SubscriptionFormat.singBoxJson
                      ? 'sing-box JSON'
                      : 'Generated from subscription',
                  style: Theme
                      .of(
                    context,
                  )
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configuration editing will use the imported profile source. Runtime options remain available in Settings.',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyMetric extends StatelessWidget {
  const _PolicyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme
                .of(
              context,
            )
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme
                .of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Policy extends ConsumerWidget {
  const _Policy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxies = ref.watch(proxiesProvider);
    final notifier = ref.read(proxiesProvider.notifier);
    return _SectionScroll(
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.account_tree_outlined,
                title: 'Outbound policy',
              ),
            ),
            FilledButton.icon(
              onPressed: proxies.testing ? null : notifier.testAllLatency,
              icon: const Icon(Icons.speed),
              label: const Text('Test latency'),
            ),
          ],
        ),
        // 抽象世界地图 — 模仿截图的 暗色剪影 + 国旗节点
        const _CountryMapHeader(),
        const AbstractWorldMap(height: 320),
        const _CountrySectionTitle(
            icon: Icons.public, title: '选择国家', subtitle: '国家 · 10'),
        if (proxies.groups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No outbound groups are available.')),
            ),
          )
        else
          for (var index = 0; index < proxies.groups.length; index++)
            Card(
              child: ExpansionTile(
                initiallyExpanded: index == proxies.selectedGroupIndex,
                leading: const Icon(Icons.route),
                title: Text(proxies.groups[index].name),
                subtitle: Text(
                  '${proxies.groups[index].nodes.length} members · ${proxies
                      .groups[index].type}',
                ),
                children: [
                  for (final node in proxies.groups[index].nodes)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        node.isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: node.isSelected
                            ? Theme
                            .of(context)
                            .colorScheme
                            .primary
                            : null,
                      ),
                      title: Text(node.name),
                      subtitle: Text(node.typeLabel),
                      trailing: Text(
                        node.latencyMs == null ? '—' : '${node.latencyMs} ms',
                      ),
                      onTap: () {
                        notifier.selectGroup(index);
                        notifier.selectNode(node.id);
                      },
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CountryMapHeader extends StatelessWidget {
  const _CountryMapHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, size: 14,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('下次启动内核时会使用已保存的选择。',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _CountrySectionTitle extends StatelessWidget {
  const _CountrySectionTitle(
      {required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: Theme
                    .of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme
                    .of(context)
                    .colorScheme
                    .onSurfaceVariant)),
          ],
        ],
      );
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 52,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'No profile selected',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 6),
            const Text('Add a subscription to create your first profile.'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add profile'),
            ),
          ],
        ),
      );
}

class _SectionScroll extends StatelessWidget {
  const _SectionScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) =>
      Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme
                .of(
              context,
            )
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        style: TextStyle(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                        child: Text(rows[i].$2, textAlign: TextAlign.left)),
                  ],
                ),
                if (i != rows.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
              ],
            ],
          ),
        ),
      );
}
