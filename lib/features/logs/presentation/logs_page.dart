import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../core/widgets/animated_reveal.dart';
import '../../../l10n/app_localizations.dart';
import '../application/logs_notifier.dart';
import 'widgets/log_line_tile.dart';
import 'widgets/log_toolbar.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logsProvider);
    final notifier = ref.read(logsProvider.notifier);
    final entries = state.filteredEntries;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TargetPageLayout.maxWidth,
              ),
              child: Row(
                children: [
                  Expanded(child: TargetPageHeader(title: l10n.logs)),
                  IconButton(
                    onPressed: _copyVisible,
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.copyVisible,
                  ),
                  IconButton(
                    onPressed: _export,
                    icon: const Icon(Icons.share),
                    tooltip: l10n.export,
                  ),
                  IconButton(
                    onPressed: notifier.clear,
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: l10n.clear,
                  ),
                ],
              ),
            ),
          ),
          LogToolbar(
            l10n: l10n,
            paused: state.paused,
            levelFilter: state.levelFilter,
            onPauseToggle: notifier.togglePause,
            onLevelChanged: notifier.setLevelFilter,
            onSearchChanged: notifier.setSearchQuery,
          ),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noLogs,
                    description: l10n.logsRealtimeHint,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return AnimatedReveal(
                        key: ValueKey(
                          '${entries[index].time.microsecondsSinceEpoch}-$index',
                        ),
                        child: LogLineTile(entry: entries[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _copyVisible() {
    final l10n = AppLocalizations.of(context);
    final text = ref.read(logsProvider.notifier).exportLogs();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.logsCopied)));
  }

  void _export() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.exportLogs),
        content: Text(l10n.sanitizeLogsPrompt),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _doExport(sanitize: false);
            },
            child: Text(l10n.raw),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _doExport(sanitize: true);
            },
            child: Text(l10n.sanitized),
          ),
        ],
      ),
    );
  }

  void _doExport({required bool sanitize}) {
    final l10n = AppLocalizations.of(context);
    final text = ref.read(logsProvider.notifier).exportLogs(sanitize: sanitize);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sanitize ? l10n.sanitizedLogsCopied : l10n.logsCopied),
      ),
    );
  }
}
