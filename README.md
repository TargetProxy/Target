# Target

Target is a Flutter desktop proxy client backed by TargetLib. It uses the local
gRPC command server for runtime state, subscriptions, configuration building,
commands, and logs.

## Status

- Flutter UI: available
- Settings persistence: available
- TargetLib subscription persistence, parsing, scheduling, and proxy catalog: available
- TargetLib runtime lifecycle: available through FFI and gRPC
- Runtime metrics, connections, events, and outbound groups: available
- Active URLTest triggering and refreshed latency results: available
- TargetLib logs: streamed through the authenticated gRPC command server
- Single-instance desktop launch: repeat launches restore and focus the running
  window on Windows, macOS, and Linux
- GitHub Actions: intentionally removed

## Architecture

The UI uses Riverpod as its composition and state-observation layer. Native
core access is isolated behind `CoreGateway`. TargetLib's reusable Flutter
runtime is provided by the sibling `TargetLib/flutter` package:

```text
Flutter widgets
  -> Riverpod providers
  -> feature controllers
  -> CoreController
  -> CoreGateway
  -> TargetLib gRPC adapter
     -> targetlib Flutter package
        -> path_provider + local command socket
```

`CoreGateway` keeps widgets independent from generated protobuf and process
management code. Build the sibling `../TargetLib` checkout before packaging.
The Windows build bundles `TargetLib.exe` beside the Flutter executable; on
first use, Target copies it to the `path_provider` application support
directory and runs that managed copy. The TargetLib build script also refreshes
all existing Windows runner copies, so `Reinstall Service` installs the latest
local daemon build without a manual file copy.

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
