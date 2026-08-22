import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';

class ConnectionErrorBanner extends StatelessWidget {
  const ConnectionErrorBanner({
    required this.message,
    this.onElevate,
    super.key,
  });

  final String message;
  final Future<void> Function()? onElevate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
        title: Text(
          'Connection Error',
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
        trailing: onElevate == null
            ? Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onErrorContainer,
              )
            : FilledButton.icon(
                onPressed: onElevate,
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Elevate'),
              ),
        onTap: () => context.go(AppRoute.logs.path),
      ),
    );
  }
}
