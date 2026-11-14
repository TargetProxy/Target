import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../core/ui/record.dart';
import 'package:talker/talker.dart';

import '../../application/logs_notifier.dart';

class LogLineTile extends StatelessWidget {
  const LogLineTile({required this.entry, super.key});

  final TalkerData entry;

  @override
  Widget build(BuildContext context) {
    final level = entry.logLevel ?? LogLevel.info;
    final styles = RecordTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: recordListGap),
      child: RecordListItem(
        header: RecordHeader(
          children: [
            Text(formatLogTime(entry.time)),
            Text(
              level.name.toUpperCase(),
              style: AppTextStyle.caption1.of(context, emphasized: true)
                  .copyWith(color: _levelColor(level, Theme.of(context))),
            ),
          ],
        ),
        body: Text(
          '[${entry.title ?? ''}] ${entry.message ?? ''}',
          style: styles.primary,
        ),
      ),
    );
  }

  Color _levelColor(LogLevel level, ThemeData theme) {
    return switch (level) {
      LogLevel.error || LogLevel.critical => theme.colorScheme.error,
      LogLevel.warning => const Color(0xffd97706),
      LogLevel.info => theme.colorScheme.primary,
      LogLevel.debug => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }
}
