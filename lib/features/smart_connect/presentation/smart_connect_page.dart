import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/proxy_node.dart';
import '../../../data/models/runtime_settings.dart';
import '../../maps/application/proxy_country_map.dart';
import '../../maps/presentation/widgets/abstract_world_map.dart';
import '../../proxies/application/proxies_notifier.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../application/smart_connect_notifier.dart';
import '../application/smart_policy_notifier.dart';
import '../domain/smart_connect_models.dart';
import 'smart_policy_editor.dart';

class _RouteDragData {
  const _RouteDragData(this.policy);

  final SmartPolicy? policy;
}

class _RouteDragFeedback extends StatelessWidget {
  const _RouteDragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    ),
  );
}

class SmartConnectPage extends ConsumerStatefulWidget {
  const SmartConnectPage({super.key});
  @override
  ConsumerState<SmartConnectPage> createState() => SmartConnectPageState();
}

class SmartConnectPageState extends ConsumerState<SmartConnectPage> {
  String? _groupId;
  SmartPolicy? _draftPolicy;
  SmartSelectionMode? _draftMode;
  String? _draftNode;
  String _query = '';
  String? _region, _source;
  bool _dirty = false, _detailOpen = false, _applying = false;
  String? _error;

  String t(String en, String zh) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(smartConnectProvider.notifier).refresh());
  }

  SmartPolicy? get _savedPolicy => ref
      .read(smartPoliciesProvider)
      .value
      ?.where((p) => p.id == _groupId)
      .firstOrNull;
  SmartPolicy? get _policy => _draftPolicy ?? _savedPolicy;
  String get _title => _policy == null
      ? t('Default', '默认 Default')
      : (_policy!.name.isEmpty ? _policy!.id : _policy!.name);
  SmartSelectionMode get _mode =>
      _draftMode ??
      _policy?.selectionMode ??
      (ref.read(smartConnectProvider).snapshot.defaultNodeId == 'direct'
          ? SmartSelectionMode.direct
          : SmartSelectionMode.manual);
  bool get _busy => _applying || ref.read(smartConnectProvider).busy;

  void _resetDraft() {
    _draftPolicy = null;
    _draftMode = null;
    _draftNode = null;
    _dirty = false;
    _error = null;
  }

  Future<bool> confirmLeave() async {
    if (_busy) return false;
    if (!_dirty) return true;
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Unsaved changes to $_title', '$_title 有待应用的更改')),
        content: Text(
          t(
            'Apply this group before leaving, or discard its draft.',
            '离开前可以应用此分组，或放弃草稿。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: Text(t('Keep editing', '继续编辑')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(t('Discard', '放弃')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'apply'),
            child: Text(t('Apply', '应用')),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (decision == 'discard') {
      setState(_resetDraft);
      return true;
    }
    return decision == 'apply' ? _apply() : false;
  }

  Future<void> _selectGroup(String? id) async {
    if (id != _groupId && !await confirmLeave()) return;
    if (!mounted) return;
    setState(() {
      if (id != _groupId) _resetDraft();
      _groupId = id;
      _query = '';
      _region = null;
      _source = null;
      _detailOpen = true;
    });
  }

  Future<bool> _apply() async {
    if (_busy) return false;
    final notifier = ref.read(smartConnectProvider.notifier);
    final policy = _policy?.copyWith(selectionMode: _mode);
    final smart = ref.read(smartConnectProvider);
    final savedNode = policy == null
        ? smart.snapshot.defaultNodeId
        : smart.bindings[policy.id]?.nodeId;
    final nodeId = _mode == SmartSelectionMode.direct
        ? 'direct'
        : _draftNode ?? (savedNode == 'direct' ? null : savedNode);
    if ((policy == null ||
            (policy.enabled && _mode == SmartSelectionMode.manual)) &&
        (nodeId == null || nodeId.isEmpty)) {
      setState(() => _error = t('Choose a node first.', '请先选择节点。'));
      return false;
    }
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      if (policy?.enabled == true &&
          policy?.selectionMode == SmartSelectionMode.automatic) {
        await notifier.evaluate(policy!);
        if (!mounted) return false;
        final result = ref.read(smartConnectProvider);
        if (result.error != null ||
            result.assessments[policy.id]?.selection.node == null) {
          setState(
            () => _error =
                result.error ??
                t(
                  'No eligible node. Adjust the service settings.',
                  '没有符合条件的节点，请调整服务设置。',
                ),
          );
          return false;
        }
      }
      if (policy == null) {
        await notifier.selectDefault(nodeId!);
      } else {
        await notifier.applyRoute(policy, nodeId: nodeId);
      }
      if (!mounted) return false;
      final error = ref.read(smartConnectProvider).error;
      if (error != null) {
        setState(() => _error = error);
        return false;
      }
      setState(_resetDraft);
      return true;
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _edit({bool create = false}) async {
    if (create && !await confirmLeave()) return;
    if (!mounted) return;
    final result = await showDialog<SmartPolicy>(
      context: context,
      builder: (_) => SmartPolicyEditor(policy: create ? null : _policy),
    );
    if (result == null || !mounted) return;
    if (!create) {
      setState(() {
        _draftPolicy = result;
        _dirty = true;
      });
      return;
    }
    try {
      await ref.read(smartPoliciesProvider.notifier).savePolicy(result);
      if (!mounted) return;
      setState(() {
        _resetDraft();
        _groupId = result.id;
        _detailOpen = true;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _delete() async {
    final policy = _savedPolicy;
    if (policy == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete $_title?', '删除 $_title？')),
        content: Text(
          t(
            'Its service override will be removed. Traffic returns to the base routing rules.',
            '这会移除此分组的独立选路，相关流量将回到基础路由规则。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', '取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Delete group', '删除分组')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(smartConnectProvider.notifier).removePolicy(policy.id);
    if (!mounted || ref.read(smartConnectProvider).error != null) return;
    setState(() {
      _resetDraft();
      _groupId = null;
      _detailOpen = false;
    });
  }

  String _modeName(SmartSelectionMode mode) => switch (mode) {
    SmartSelectionMode.followDefault => t('Follow Default', '跟随默认'),
    SmartSelectionMode.manual => t('Manual node', '手动选择'),
    SmartSelectionMode.automatic => t('Automatic', '自动选择'),
    SmartSelectionMode.direct => t('Direct', '直连'),
  };

  String _nodeName(String? id) {
    if (id == 'direct') return t('Direct · local network', '直连 · 本机网络');
    if (id == null || id.isEmpty) return t('Not selected', '尚未选择');
    return ref
            .read(smartConnectProvider)
            .snapshot
            .nodes
            .where((n) => n.id == id)
            .firstOrNull
            ?.displayName ??
        '$id · ${t('unavailable', '不可用')}';
  }

  String _routeSummary(SmartPolicy? policy) {
    final smart = ref.read(smartConnectProvider);
    final snapshot = smart.snapshot;
    if (!snapshot.loaded) return t('Runtime not loaded', '尚未读取运行状态');
    final binding = policy == null ? null : snapshot.bindings[policy.id];
    if (binding != null) {
      return '${_nodeName(binding.nodeId)} · ${binding.effective ? t('Effective', '已生效') : t('Not effective', '未生效')}';
    }
    final defaultLabel = _nodeName(snapshot.defaultNodeId);
    if (policy == null) return defaultLabel;
    return '${t('Follow Default', '跟随默认')} → $defaultLabel';
  }

  @override
  Widget build(BuildContext context) {
    final smart = ref.watch(smartConnectProvider);
    final policies = ref.watch(smartPoliciesProvider);
    ref.watch(proxiesProvider);
    ref.watch(subscriptionsProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          return Padding(
            padding: EdgeInsets.all(wide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Smart Connect', '智能连接'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              'Drag a node onto a service below.',
                              '将节点拖到下方服务图标，即可切换出口。',
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t('Refresh runtime', '刷新运行状态'),
                      onPressed: _busy
                          ? null
                          : () => ref
                                .read(smartConnectProvider.notifier)
                                .refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'nodes' &&
                            await confirmLeave() &&
                            context.mounted) {
                          context.go('/node-library');
                        }
                        if (value == 'export') {
                          await Clipboard.setData(
                            ClipboardData(
                              text: const JsonEncoder.withIndent('  ').convert(
                                (policies.value ?? [])
                                    .map((p) => p.toJson())
                                    .toList(),
                              ),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t('Group configuration copied', '分组配置已复制'),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'nodes',
                          child: Text(t('Node library & map', '节点库与地图')),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Text(t('Copy group configuration', '复制分组配置')),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_error != null || smart.error != null)
                  _notice(_error ?? smart.error!, error: true),
                if (policies.hasError)
                  _notice(
                    '${t('Could not load groups', '无法加载分组')}: ${policies.error}',
                    error: true,
                  ),
                if (policies.isLoading || _busy)
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Expanded(
                  child: _detailOpen
                      ? _detail(true)
                      : ListView(
                          key: const ValueKey('node-overview'),
                          children: [
                            if (smart.snapshot.nodes.isNotEmpty) ...[
                              AbstractWorldMap(
                                height: 250,
                                nodes: proxyCountryMapEntries(
                                  smart.snapshot.nodes,
                                ),
                                onDrop: _dropCountry,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _nodeList(null, smart.snapshot.defaultNodeId),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                _groups(policies.value ?? []),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notice(String text, {bool error = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        color: error ? Theme.of(context).colorScheme.error : null,
      ),
    ),
  );

  Future<void> _dropNode(SmartPolicy? policy, ProxyNode node) async {
    if (_busy || !await confirmLeave() || !mounted) return;
    setState(() => _error = null);
    final notifier = ref.read(smartConnectProvider.notifier);
    if (policy == null) {
      await notifier.selectDefault(node.id);
    } else {
      await notifier.applyRoute(
        policy.copyWith(
          selectionMode: SmartSelectionMode.manual,
          enabled: true,
        ),
        nodeId: node.id,
      );
    }
    if (!mounted || ref.read(smartConnectProvider).error != null) return;
    setState(_resetDraft);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${policy?.name ?? t('Default', '默认')} → ${node.displayName}',
        ),
      ),
    );
  }

  Future<void> _dropCountry(String countryCode, Object data) async {
    if (data is! _RouteDragData || _busy) return;
    final policy = data.policy;
    final nodes = ref
        .read(smartConnectProvider)
        .snapshot
        .nodes
        .where((node) => proxyNodeCountryCode(node) == countryCode)
        .where((node) => _canDrop(policy, node))
        .toList();
    if (nodes.isEmpty) {
      setState(
        () => _error = t('No eligible node in this country.', '这个国家没有符合条件的节点。'),
      );
      return;
    }
    final node = nodes.length == 1
        ? nodes.single
        : await _chooseNode(policy, nodes);
    if (node != null && mounted) await _dropNode(policy, node);
  }

  bool _canDrop(SmartPolicy? policy, ProxyNode node) =>
      !_busy &&
      node.isAvailable &&
      (policy == null ||
          (node.enabled &&
              !node.excluded &&
              !policy.excludedNodes.contains(node.id) &&
              (policy.allowedRegions.isEmpty ||
                  policy.allowedRegions.contains(node.effectiveRegion)) &&
              (policy.allowedSubscriptions.isEmpty ||
                  policy.allowedSubscriptions.contains(node.subscriptionId))));

  Widget _groups(List<SmartPolicy> policies) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _groupTile(null),
            for (final policy in policies) _groupTile(policy),
            const SizedBox(width: 4),
            IconButton(
              tooltip: t('Add group', '添加分组'),
              onPressed: _busy ? null : () => _edit(create: true),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _groupTile(SmartPolicy? policy) {
    final colors = Theme.of(context).colorScheme;
    final name = policy == null
        ? t('Default', '默认')
        : policy.name.isEmpty
        ? policy.id
        : policy.name;
    return DragTarget<Object>(
      key: ValueKey('drop-${policy?.id ?? 'default'}'),
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data is ProxyNode ||
            (data is List<ProxyNode> &&
                data.any((node) => _canDrop(policy, node)));
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is ProxyNode) {
          _dropNode(policy, data);
        } else if (data is List<ProxyNode>) {
          final eligible = data
              .where((node) => _canDrop(policy, node))
              .toList();
          if (eligible.length == 1) _dropNode(policy, eligible.single);
          if (eligible.length > 1) _chooseNode(policy, eligible);
        }
      },
      builder: (context, candidates, rejected) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Tooltip(
          message: t('Drop a node on $name', '将节点拖到$name'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: candidates.isNotEmpty
                  ? colors.primaryContainer
                  : rejected.isNotEmpty
                  ? colors.errorContainer
                  : _detailOpen && _groupId == policy?.id
                  ? colors.secondaryContainer
                  : colors.surfaceContainerHighest,
              border: Border.all(
                color: candidates.isNotEmpty
                    ? colors.primary
                    : colors.outlineVariant,
                width: candidates.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Draggable<_RouteDragData>(
              data: _RouteDragData(policy),
              feedback: _RouteDragFeedback(label: name),
              child: IconButton(
                key: ValueKey('group-${policy?.id ?? 'default'}'),
                onPressed: _busy ? null : () => _selectGroup(policy?.id),
                padding: const EdgeInsets.all(14),
                icon: Semantics(
                  label: name,
                  child: policy?.id == 'chatgpt'
                      ? Image.asset(
                          'assets/services/openai.png',
                          width: 28,
                          height: 28,
                          color: colors.onSurface,
                        )
                      : Icon(switch (policy?.id) {
                          null => Icons.public,
                          'youtube' => Icons.smart_display_outlined,
                          'disney' => Icons.movie_outlined,
                          'direct' => Icons.wifi,
                          _ => Icons.language,
                        }, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<ProxyNode?> _chooseNode(
    SmartPolicy? policy,
    List<ProxyNode> nodes,
  ) async {
    return showModalBottomSheet<ProxyNode>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                t('Choose a node', '选择节点'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final node in nodes)
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(node.displayName),
                subtitle: Text(node.effectiveRegion),
                onTap: () => Navigator.pop(context, node),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detail(bool mobile) {
    final smart = ref.read(smartConnectProvider);
    final policy = _policy;
    final binding = smart.bindings[_groupId];
    final theme = Theme.of(context);
    final snapshot = smart.snapshot;
    final actual = policy == null
        ? snapshot.actualDefaultNodeId
        : binding?.effective == true
        ? binding?.nodeId
        : null;
    final follows = policy != null && binding == null && snapshot.loaded;
    final mode = _mode;
    final savedNode = policy == null ? snapshot.defaultNodeId : binding?.nodeId;
    final selectedNode =
        _draftNode ?? (savedNode == 'direct' ? null : savedNode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                if (await confirmLeave() && mounted) {
                  setState(() => _detailOpen = false);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(t('All nodes', '全部节点')),
            ),
          ),
        Expanded(
          child: ListView(
            key: ValueKey('detail-${_groupId ?? 'default'}'),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_title, style: theme.textTheme.headlineSmall),
                  ),
                  if (policy != null) ...[
                    IconButton(
                      tooltip: t(
                        'Edit matching rules & constraints',
                        '编辑规则与候选约束',
                      ),
                      onPressed: _busy ? null : _edit,
                      icon: const Icon(Icons.tune),
                    ),
                    IconButton(
                      tooltip: t('Delete group', '删除分组'),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                policy == null
                    ? t(
                        'Fallback for traffic not matched by service or built-in rules.',
                        '用于未命中服务分组及内置规则的流量。',
                      )
                    : '${t('Matches domains and subdomains', '匹配域名及其子域名')}: ${policy.domains.join(', ')}',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('CURRENT ROUTE', '当前出口'),
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _routeSummary(_savedPolicy),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !snapshot.loaded
                          ? t(
                              'Refresh to read the runtime state.',
                              '请刷新以读取运行状态。',
                            )
                          : !snapshot.running
                          ? t(
                              'Configuration saved; active after connecting.',
                              '配置已保存，连接后生效。',
                            )
                          : ref.read(coreProvider).settings.routeMode ==
                                RouteMode.direct
                          ? t('Bypassed by All direct mode.', '当前被全部直连模式覆盖。')
                          : follows
                          ? t(
                              'Uses base routing rules and the current Default. No independent override.',
                              '沿用基础路由规则与当前默认出口，未设置独立出口。',
                            )
                          : actual != null && actual.isNotEmpty
                          ? '${t('Runtime reports', '运行时报告')}: ${_nodeName(actual)}'
                          : t(
                              'Not confirmed effective. The saved choice is not an active-route guarantee.',
                              '尚未确认生效；已保存的选择不等于实际出口。',
                            ),
                    ),
                    if (binding?.needsEvaluation == true)
                      Text(t('Service check needs refreshing.', '服务检测结果需要刷新。')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (policy?.enabled == false)
                _notice(
                  t(
                    'This group is disabled. Applying removes its independent route.',
                    '此分组已停用；应用后会移除其独立出口。',
                  ),
                ),
              Text(
                t('How this group connects', '这个分组怎么走'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in [
                    if (policy != null) SmartSelectionMode.followDefault,
                    SmartSelectionMode.manual,
                    if (policy != null) SmartSelectionMode.automatic,
                    SmartSelectionMode.direct,
                  ])
                    ChoiceChip(
                      key: ValueKey('mode-${option.name}'),
                      label: Text(_modeName(option)),
                      selected: mode == option,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                              _draftMode = option;
                              _dirty = true;
                              _error = null;
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (mode == SmartSelectionMode.followDefault)
                _notice(
                  '${t('Follows Default automatically', '随默认出口一起变化')} → ${_nodeName(snapshot.defaultNodeId)}',
                ),
              if (mode == SmartSelectionMode.direct)
                _notice(
                  t(
                    'This group uses the local network. No proxy node or test is required.',
                    '此分组使用本机网络，不需要代理节点或测速。',
                  ),
                ),
              if (mode == SmartSelectionMode.manual)
                _nodeList(policy, selectedNode),
              if (mode == SmartSelectionMode.automatic && policy != null)
                _notice(
                  t(
                    'Find and apply a suitable node in one step.',
                    '应用时自动检测并选择可用节点。',
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _dirty
                    ? '${t('Pending', '待应用')}: $_title → ${mode == SmartSelectionMode.manual ? _nodeName(selectedNode) : _modeName(mode)}'
                    : t(
                        'Choose a mode or node to prepare a change.',
                        '选择方式或节点后，再应用到当前分组。',
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: !_dirty || _busy
                        ? null
                        : () => setState(_resetDraft),
                    child: Text(t('Cancel', '取消')),
                  ),
                  FilledButton(
                    key: const ValueKey('apply-group'),
                    onPressed:
                        !_dirty ||
                            _busy ||
                            (policy?.enabled != false &&
                                mode == SmartSelectionMode.manual &&
                                selectedNode == null)
                        ? null
                        : _apply,
                    child: Text(
                      _busy
                          ? t('Working…', '处理中…')
                          : t('Apply to $_title', '应用到 $_title'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nodeList(SmartPolicy? policy, String? selectedNode) {
    final smart = ref.read(smartConnectProvider);
    final testing = ref.read(proxiesProvider).testing;
    final latency = {
      for (final group in ref.read(proxiesProvider).groups)
        for (final node in group.nodes) node.id: node,
    };
    final sources = {
      for (final s in ref.read(subscriptionsProvider).subscriptions)
        s.id: s.name,
    };
    final nodes = smart.snapshot.nodes;
    final regions =
        nodes
            .map((n) => n.effectiveRegion)
            .where((r) => r.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final sourceIds = nodes.map((n) => n.subscriptionId).toSet().toList();
    final visible = nodes
        .where(
          (node) =>
              (_region == null || node.effectiveRegion == _region) &&
              (_source == null || node.subscriptionId == _source) &&
              '${node.displayName} ${node.type} ${sources[node.subscriptionId] ?? ''}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    String? excluded(ProxyNode node) {
      if (!node.isAvailable) return t('Unavailable', '不可用');
      if (policy == null) return null;
      if (!node.enabled ||
          node.excluded ||
          policy.excludedNodes.contains(node.id)) {
        return t('Excluded from this group', '已从候选范围排除');
      }
      if (policy.allowedRegions.isNotEmpty &&
          !policy.allowedRegions.contains(node.effectiveRegion)) {
        return t('Outside allowed regions', '不在允许地区内');
      }
      if (policy.allowedSubscriptions.isNotEmpty &&
          !policy.allowedSubscriptions.contains(node.subscriptionId)) {
        return t('Outside allowed subscriptions', '不在允许订阅内');
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ValueKey('search-${_groupId ?? 'default'}'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: t('Search nodes or subscriptions', '搜索节点或订阅'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: regions.contains(_region) ? _region : null,
              hint: Text(t('All regions', '全部地区')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(t('All regions', '全部地区')),
                ),
                for (final region in regions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            SizedBox(
              width: 180,
              child: DropdownButton<String>(
                isExpanded: true,
                value: sourceIds.contains(_source) ? _source : null,
                hint: Text(t('All subscriptions', '全部订阅')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(t('All subscriptions', '全部订阅')),
                  ),
                  for (final id in sourceIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        sources[id] ?? id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _source = value),
              ),
            ),
            TextButton.icon(
              onPressed: ref.read(proxiesProvider).testing || _busy
                  ? null
                  : () => ref.read(proxiesProvider.notifier).testAllLatency(),
              icon: const Icon(Icons.speed),
              label: Text(t('Test latency', '测速')),
            ),
          ],
        ),
        Text(
          t(
            'Filters only change this list. Group constraints are edited with the settings button.',
            '筛选只影响列表展示；分组的候选约束在右上角设置中编辑。',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (selectedNode != null &&
            selectedNode != 'direct' &&
            !nodes.any((n) => n.id == selectedNode))
          _notice(
            '${t('Selected node is no longer available', '所选节点已不可用')}: $selectedNode',
            error: true,
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              nodes.isEmpty
                  ? t('No nodes. Enable a subscription first.', '暂无节点，请先启用订阅。')
                  : t(
                      'No matching nodes. Clear the search or filters.',
                      '没有匹配节点，请清除搜索或筛选。',
                    ),
            ),
          ),
        for (final node in visible)
          Draggable<ProxyNode>(
            data: node,
            maxSimultaneousDrags: _busy || excluded(node) != null ? 0 : 1,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dns_outlined),
                    const SizedBox(width: 10),
                    Text(node.displayName),
                  ],
                ),
              ),
            ),
            child: ListTile(
              key: ValueKey('candidate-${node.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              selected: selectedNode == node.id,
              enabled: excluded(node) == null,
              leading: Icon(
                selectedNode == node.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(node.displayName),
              subtitle: Text(
                '${sources[node.subscriptionId] ?? node.subscriptionId} · ${node.effectiveRegion}\n${excluded(node) ?? t('Service availability unverified', '服务可用性未验证')}',
              ),
              trailing: testing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      latency[node.id]?.latencyTimedOut == true
                          ? t('Timeout', '超时')
                          : latency[node.id]?.latencyMs != null
                          ? '${latency[node.id]!.latencyMs} ms'
                          : '—',
                    ),
              onTap: _busy || excluded(node) != null
                  ? null
                  : () => setState(() {
                      _draftNode = node.id;
                      _draftMode = SmartSelectionMode.manual;
                      _detailOpen = true;
                      _dirty = true;
                      _error = null;
                    }),
            ),
          ),
      ],
    );
  }
}
