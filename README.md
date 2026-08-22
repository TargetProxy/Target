# Target

Target is a Flutter desktop proxy client backed by TargetLib. It uses the local
gRPC command server for runtime state, subscriptions, configuration building,
commands, and logs.

## Status

- Flutter UI: available
- Settings persistence: available
- TargetLib subscription persistence, parsing, scheduling, and proxy catalog: available
- Libbox runtime lifecycle: available through FFI and gRPC
- Runtime metrics, connections, events, and outbound groups: available
- Active URLTest triggering and refreshed latency results: available
- Libbox logs: streamed through the authenticated gRPC command server
- GitHub Actions: intentionally removed

## Architecture

The UI uses Riverpod as its composition and state-observation layer. Native
core access is isolated behind `CoreGateway`:

```text
Flutter widgets
  -> Riverpod providers
  -> feature controllers
  -> CoreController
  -> CoreGateway
  -> TargetLib gRPC adapter
```

`CoreGateway` keeps widgets independent from generated protobuf and process
management code. Build the sibling `../TargetLib` checkout before packaging;
the Windows build copies `../TargetLib/build/TargetLib.exe` beside the app.

## Run

```powershell
flutter pub get
flutter run -d windows
```

## Verify

```powershell
flutter analyze
flutter test
flutter build windows --debug
```

The website is an independent Astro project:

```powershell
pnpm --dir website install
pnpm --dir website check
pnpm --dir website build
```
