import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/app_animate.dart';

class ConnectionErrorBanner extends StatelessWidget {
  const ConnectionErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppAnimate(
      effects: [
        FadeEffect(duration: AppMotion.standard, curve: AppMotion.easeOut),
        MoveEffect(
          duration: AppMotion.standard,
          curve: AppMotion.easeOut,
          begin: const Offset(0, -10),
        ),
        ShakeEffect(
          delay: AppMotion.standard,
          duration: const Duration(milliseconds: 360),
          hz: 4,
          rotation: 0,
          offset: const Offset(5, 0),
        ),
      ],
      child: Card(
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
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onErrorContainer,
          ),
          onTap: () => context.go(AppRoute.logs.path),
        ),
      ),
    );
  }
}
