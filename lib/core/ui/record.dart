import 'package:prism_ui/prism_ui.dart';
import 'package:flutter/widgets.dart';

class RecordTextStyles {
  final TextStyle title;
  final TextStyle primary;
  final TextStyle secondary;

  const RecordTextStyles._({
    required this.title,
    required this.primary,
    required this.secondary,
  });

  factory RecordTextStyles.of(BuildContext context) {
    final colorScheme = context.colorScheme;
    return RecordTextStyles._(
      title: AppTextStyle.subheadline
          .of(context, emphasized: true)
          .copyWith(color: colorScheme.onSurface),
      primary: AppTextStyle.subheadline
          .of(context)
          .copyWith(color: colorScheme.onSurface),
      secondary: AppTextStyle.footnote
          .of(context)
          .copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}

const recordListGap = 8.0;

const recordListEstimatedExtent = 100.0;

class RecordListItem extends StatelessWidget {
  final Widget header;
  final Widget body;
  final VoidCallback? onTap;

  const RecordListItem({
    super.key,
    required this.header,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = context.raisedSurfaceLevel;
    return PressSurface(
      fill: level.colorOf(context.colorScheme),
      shape: AppShape.xl,
      onPressed: onTap,
      child: SurfaceScope(
        level: level,
        child: ListRow(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          minVerticalPadding: 0,
          minHeight: 0,
          horizontalTitleGap: 12,
          alignment: ListRowAlignment.top,
          title: header,
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: body,
          ),
        ),
      ),
    );
  }
}

class RecordHeader extends StatelessWidget {
  final List<Widget> children;
  final Widget? trailing;

  const RecordHeader({super.key, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return DefaultTextStyle.merge(
      style: AppTextStyle.caption1
          .of(context)
          .toTabular
          .copyWith(color: context.colorScheme.onSurfaceVariant),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: children,
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
