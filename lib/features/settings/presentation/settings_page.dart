import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/app_settings.dart';
import '../application/settings_notifier.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tile.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).settings;
    final notifier = ref.read(settingsProvider.notifier);
    final core = ref.watch(coreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings'),
            Text(
              'Application preferences and runtime options',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          SettingsGroup(
            title: 'General',
            children: [
              const SettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
              ),
              SettingsTile(
                icon: Icons.power_settings_new,
                title: 'Start on boot',
                trailing: Switch(
                  value: settings.startOnBoot,
                  onChanged: notifier.setStartOnBoot,
                ),
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: settings.enableNotifications,
                  onChanged: notifier.setNotifications,
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Network',
            children: [
              SettingsTile(
                icon: Icons.alt_route,
                title: 'Proxy mode',
                subtitle: settings.proxyMode.label,
                onTap: _showProxyModeDialog,
              ),
              SettingsTile(
                icon: Icons.tune,
                title: 'Mixed port',
                subtitle: '${settings.mixedPort}',
                onTap: _showPortDialog,
              ),
              SettingsTile(
                icon: Icons.language,
                title: 'IPv6',
                trailing: Switch(
                  value: settings.ipv6,
                  onChanged: (value) {
                    notifier.setIPv6(value);
                    _syncCore();
                  },
                ),
              ),
              SettingsTile(
                icon: Icons.settings_ethernet,
                title: 'System proxy',
                trailing: Switch(
                  value: settings.systemProxy,
                  onChanged: (value) {
                    notifier.setSystemProxy(value);
                    _syncCore();
                  },
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Appearance',
            children: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: settings.themeMode.label,
                onTap: _showThemeDialog,
              ),
            ],
          ),
          SettingsGroup(
            title: 'About',
            children: [
              const SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '0.2.0',
              ),
              SettingsTile(
                icon: Icons.memory_outlined,
                title: 'Core backend',
                subtitle: core.available
                    ? core.backendName
                    : '${core.backendName} bridge pending',
              ),
              const SettingsTile(
                icon: Icons.description_outlined,
                title: 'License',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final notifier = ref.read(settingsProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Theme'),
        children: ThemeModeOption.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              notifier.setThemeMode(mode);
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: [
                if (ref.read(settingsProvider).settings.themeMode == mode)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 12),
                Text(mode.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showProxyModeDialog() {
    final notifier = ref.read(settingsProvider.notifier);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Proxy mode'),
        children: ProxyMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              notifier.setProxyMode(mode);
              _syncCore();
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: [
                if (ref.read(settingsProvider).settings.proxyMode == mode)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(mode.label)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPortDialog() {
    final notifier = ref.read(settingsProvider.notifier);
    final textController = TextEditingController(
      text: ref.read(settingsProvider).settings.mixedPort.toString(),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mixed port'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Port'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(textController.text);
              if (port != null && port > 0 && port < 65536) {
                notifier.setMixedPort(port);
                _syncCore();
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _syncCore() {
    final settings = ref.read(settingsProvider).settings;
    ref.read(coreProvider.notifier).configure(settings);
  }
}
