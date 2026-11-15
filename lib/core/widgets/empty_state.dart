import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.illustration,
    required this.title,
    this.description,
    this.action,
    super.key,
  });

  final Illustration illustration;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return NullStatus(
      illustration: illustration,
      label: title,
      description: description,
      action: action,
    );
  }
}
