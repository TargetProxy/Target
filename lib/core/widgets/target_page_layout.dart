import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../ui/scaffold/scaffold.dart' as ui;

class TargetPageLayout extends StatelessWidget {
  const TargetPageLayout({required this.child, super.key});

  final Widget child;

  static const maxWidth = 960.0;
  static const padding = EdgeInsets.all(24);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class TargetPageScaffold extends StatelessWidget {
  const TargetPageScaffold({
    required this.body,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.scrollableBody = true,
    super.key,
  });

  final Widget body;

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    return ui.Scaffold(
      title: title,
      actions: actions,
      body: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: TargetPageLayout.maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: scrollableBody ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(subtitle!, style: AppTextStyle.subheadline.of(context).toLighter),
              ),
            if (scrollableBody) body else Expanded(child: body),
          ],
        ),
      ),
    );
    final padding = EdgeInsets.fromLTRB(
      24, context.contentTopPadding + 16, 24, context.bottomInset + 24,
    );
    if (!scrollableBody) return Padding(padding: padding, child: content);
    return SingleChildScrollView(padding: padding, child: content);
  }
}

class TargetPageHeader extends StatelessWidget {
  const TargetPageHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.title1.of(context, emphasized: true),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTextStyle.subheadline.of(context).toLighter,
          ),
        ],
      ],
    );
  }
}
