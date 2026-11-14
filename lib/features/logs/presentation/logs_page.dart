import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import '../../../core/ui/app_glyphs.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/target_page_layout.dart';
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

    return TargetPageScaffold(
      title: l10n.logs,
      subtitle: l10n.runtimeDiagnostics,
      scrollableBody: false,
      actions: [
        prism.IconButton(
          onPressed: _copyVisible,
          icon: const GlyphIcon(AppGlyphs.copy),
          tooltip: l10n.copyVisible,
        ),
        prism.IconButton(
          onPressed: _export,
          icon: const GlyphIcon(AppGlyphs.export),
          tooltip: l10n.export,
        ),
        prism.IconButton(
          onPressed: notifier.clear,
          icon: const GlyphIcon(AppGlyphs.delete),
          tooltip: l10n.clear,
        ),
      ],
      body: Column(
        children: [
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
                      return LogLineTile(
                        key: ValueKey(
                          '${entries[index].time.microsecondsSinceEpoch}-$index',
                        ),
                        entry: entries[index],
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
    prism.BannerHost.maybeOf(context)?.show(l10n.logsCopied);
  }

  void _export() {
    final l10n = AppLocalizations.of(context);
    prism.showFloatingDialog<void>(
      context: context,
      child: prism.AlertDialog(
        title: l10n.exportLogs,
        child: Text(l10n.sanitizeLogsPrompt),
        actions: [
          prism.TextButton(
            onPressed: () {
              Navigator.pop(context);
              _doExport(sanitize: false);
            },
            child: Text(l10n.raw),
          ),
          prism.TextButton(
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
    prism.BannerHost.maybeOf(context)?.show(
      sanitize ? l10n.sanitizedLogsCopied : l10n.logsCopied,
    );
  }
}
