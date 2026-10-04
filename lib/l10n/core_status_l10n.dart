import '../core/runtime/core_models.dart';
import 'app_localizations.dart';

/// Maps a core lifecycle onto user-facing text. The core reports its state in
/// English for logs and diagnostics; every string that reaches the UI is
/// resolved here instead.
extension CoreStatusL10n on AppLocalizations {
  String coreStatusLabel(CoreLifecycle lifecycle) => switch (lifecycle) {
    CoreLifecycle.unavailable => coreUnavailable,
    CoreLifecycle.stopped => disconnected,
    CoreLifecycle.starting => starting,
    CoreLifecycle.running => running,
    CoreLifecycle.stopping => working,
    CoreLifecycle.failed => err,
  };
}
