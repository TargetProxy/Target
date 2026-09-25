import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../domain/smart_connect_models.dart';

class SmartPolicyEditor extends ConsumerStatefulWidget {
  const SmartPolicyEditor({super.key, this.policy});
  final SmartPolicy? policy;
  @override
  ConsumerState<SmartPolicyEditor> createState() => _SmartPolicyEditorState();
}

class _SmartPolicyEditorState extends ConsumerState<SmartPolicyEditor> {
  final _fields = <String, TextEditingController>{};
  String? _error;
  late Set<String> _subscriptions;
  late bool _enabled;
  String t(String en, String zh) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  @override
  void initState() {
    super.initState();
    final p = widget.policy ?? const SmartPolicy(id: '');
    _subscriptions = {...p.allowedSubscriptions};
    _enabled = p.enabled;
    final values = {
      'name': p.name,
      'domains': p.domains.join(', '),
      'regions': p.allowedRegions.join(', '),
      'preferred': p.preferredRegions.join(', '),
      'probe': p.probeTargets.firstOrNull?.url ?? '',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String value(String key) => _fields[key]!.text.trim();
  Set<String> values(String key) =>
      value(key).split(RegExp(r'[,\s]+')).where((v) => v.isNotEmpty).toSet();
  Widget field(String key, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _fields[key],
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      decoration: InputDecoration(labelText: label),
    ),
  );
  void save() {
    try {
      final domain = values('domains').firstOrNull;
      final id =
          widget.policy?.id ?? 'group-${DateTime.now().microsecondsSinceEpoch}';
      final existingDirect =
          widget.policy?.selectionMode == SmartSelectionMode.direct;
      final probe = value('probe').isEmpty && domain != null && !existingDirect
          ? 'https://$domain/'
          : value('probe');
      final previousProbe = widget.policy?.probeTargets.firstOrNull;
      final targets = probe.isEmpty
          ? const <SmartProbeTarget>[]
          : [
              SmartProbeTarget(
                url: probe,
                expectedStatus: previousProbe?.expectedStatus ?? const {200},
                bodyContains: previousProbe?.bodyContains ?? '',
                egressUrl: previousProbe?.egressUrl ?? '',
                serviceCountryHeader: previousProbe?.serviceCountryHeader ?? '',
              ),
              ...?widget.policy?.probeTargets.skip(1),
            ];
      final p = SmartPolicy(
        id: id,
        name: value('name').isEmpty ? id : value('name'),
        domains: values('domains').map((d) => d.toLowerCase()).toSet(),
        allowedRegions: values('regions').map((r) => r.toUpperCase()).toSet(),
        preferredRegions: values(
          'preferred',
        ).map((r) => r.toUpperCase()).toSet(),
        probeTargets: targets,
        selectionMode:
            widget.policy?.selectionMode ?? SmartSelectionMode.followDefault,
        allowedSubscriptions: _subscriptions,
        excludedNodes: widget.policy?.excludedNodes ?? const {},
        stickyDuration:
            widget.policy?.stickyDuration ?? const Duration(minutes: 30),
        probeValidity:
            widget.policy?.probeValidity ?? const Duration(minutes: 5),
        enabled: _enabled,
      );
      final errors = p.validate();
      if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
      Navigator.of(context).pop(p);
    } on Object catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.policy == null
          ? t('Add group', '添加分组')
          : t('Rules & candidate constraints', '匹配规则与候选约束'),
    ),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field('name', t('Group name', '分组名称')),
            field(
              'domains',
              t('Domains, separated by commas', '域名，以逗号分隔'),
              lines: 2,
            ),
            Text(
              t(
                'Includes subdomains. More specific domains match first.',
                '包含子域名；更具体的域名优先匹配。',
              ),
            ),
            if (widget.policy == null)
              Text(
                t(
                  'New groups follow Default. Choose an independent route after creating the group.',
                  '新分组跟随默认，创建后可选择独立出口。',
                ),
              ),
            SwitchListTile(
              title: Text(t('Enable independent routing', '启用此分组独立选路')),
              subtitle: Text(
                t(
                  'When disabled, traffic follows base routing rules.',
                  '关闭后流量沿用基础路由规则。',
                ),
              ),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            ExpansionTile(
              title: Text(
                t('Candidate constraints & service probe', '候选约束与服务检测'),
              ),
              children: [
                field(
                  'regions',
                  t(
                    'Allowed country codes (empty = any)',
                    '允许的国家代码（留空不限，如 US, JP）',
                  ),
                ),
                field('preferred', t('Preferred country codes', '偏好的国家代码')),
                Text(
                  t(
                    'Allowed subscriptions · none selected means all',
                    '允许的订阅 · 不勾选表示全部',
                  ),
                ),
                for (final subscription
                    in ref.watch(subscriptionsProvider).subscriptions)
                  CheckboxListTile(
                    title: Text(subscription.name),
                    value: _subscriptions.contains(subscription.id),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _subscriptions.add(subscription.id);
                      } else {
                        _subscriptions.remove(subscription.id);
                      }
                    }),
                  ),
                field(
                  'probe',
                  t(
                    'Probe URL (defaults to the first domain)',
                    '检测 URL（默认使用第一个域名）',
                  ),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(t('Cancel', '取消')),
      ),
      FilledButton(
        onPressed: save,
        child: Text(
          widget.policy == null
              ? t('Create group', '创建分组')
              : t('Update draft', '更新草稿'),
        ),
      ),
    ],
  );
}
