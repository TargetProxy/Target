import 'package:material_ui/material_ui.dart';

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

/// A page shell: an optional fixed header row (title, subtitle, trailing
/// actions) above a scrolling body.
///
/// Use this for pages whose body needs its own scrolling, or that host a custom
/// header. Use [TargetPageLayout] when the page is a single plain column.
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

  /// Omit to render a page without the standard header row.
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return SafeArea(
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: TargetPageLayout.maxWidth,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TargetPageHeader(title: title, subtitle: subtitle),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: TargetPageLayout.maxWidth),
        child: body,
      ),
    );
    if (!scrollableBody) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: content,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: content,
    );
  }
}

class TargetPageHeader extends StatelessWidget {
  const TargetPageHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
