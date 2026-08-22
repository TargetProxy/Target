import 'dart:convert';
import 'dart:io';

import '../logging/app_logger.dart';

enum TargetLibServiceStatus { running, stopped, unknown, notInstalled }

// Keep old name as alias for backward compatibility.
typedef LibboxdServiceStatus = TargetLibServiceStatus;
typedef LibboxdServiceResult = TargetLibServiceResult;

class TargetLibServiceResult {
  const TargetLibServiceResult(this.status, {this.output = ''});

  final TargetLibServiceStatus status;
  final String output;
}

/// Controls the standalone targetlib executable. This deliberately uses the
/// daemon's CLI so it works on Windows SCM and Linux systemd alike.
class TargetLibServiceManager {
  TargetLibServiceManager([this._executablePath]);

  /// The Windows service name registered by the daemon. Must match the name
  /// the daemon uses with kardianos/service (verified via `sc.exe query`).
  static const String _windowsServiceName = 'TargetLib';

  static TargetLibServiceStatus? _cachedStatus;
  static String? _cachedBasePath;

  final String? _executablePath;

  static void invalidateStatus() {
    _cachedStatus = null;
    _cachedBasePath = null;
  }

  Future<String> resolveExecutable() async {
    final exeSuffix = Platform.isWindows ? '.exe' : '';
    final baseDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      ..._optional(_executablePath),
      '$baseDir${Platform.pathSeparator}TargetLib$exeSuffix',
      '$baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}TargetLib$exeSuffix',
      '$baseDir${Platform.pathSeparator}targetlibd$exeSuffix',
      '$baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}targetlibd$exeSuffix',
    ];
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        AppLogger.debug('Resolved executable: $candidate', source: 'targetlib');
        return candidate;
      }
    }
    AppLogger.error(
      'Executable not found; checked: ${candidates.join(', ')}',
      source: 'targetlib',
    );
    throw StateError(
      'TargetLib executable is not bundled with this application. '
      'Rebuild the desktop target to copy it from the targetlib build output.',
    );
  }

  Future<TargetLibServiceResult> run(
    String action, {
    required String basePath,
    String workingPath = '',
    String tempPath = '',
    String locale = '',
    bool elevated = true,
  }) async {
    if (action == 'status' &&
        _cachedStatus != null &&
        _cachedBasePath == basePath) {
      AppLogger.debug(
        'Using cached service status: ${_cachedStatus!.name}',
        source: 'targetlib',
      );
      return TargetLibServiceResult(_cachedStatus!);
    }
    // Querying status never needs admin rights. On Windows the daemon's own
    // `status` opens the service with START/STOP access and gets rejected
    // non-elevated, so use `sc.exe query` instead. Elsewhere the daemon's
    // status is queried without elevation.
    if (action == 'status' && Platform.isWindows) {
      return _queryStatusWindows(basePath);
    }
    final effectiveElevated = action == 'status' ? false : elevated;
    final stopwatch = Stopwatch()..start();
    AppLogger.info(
      'Service action started: action=$action elevated=$effectiveElevated '
      'basePath=$basePath workingPath=${_displayOptional(workingPath)} '
      'tempPath=${_displayOptional(tempPath)} locale=${_displayOptional(locale)}',
      source: 'targetlib',
    );
    try {
      final executable = await resolveExecutable();
      final args = _buildActionArgs(
        action,
        basePath,
        workingPath,
        tempPath,
        locale,
      );
      final result = effectiveElevated
          ? await _runElevated(executable, [args])
          : await Process.run(executable, args);
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (stdout.isNotEmpty) {
        AppLogger.info('stdout:\n$stdout', source: 'targetlib');
      }
      if (stderr.isNotEmpty) {
        AppLogger.warning('stderr:\n$stderr', source: 'targetlib');
      }
      final output = [
        stdout,
        stderr,
      ].where((value) => value.isNotEmpty).join('\n');
      AppLogger.info(
        'Service action exited: action=$action exitCode=${result.exitCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'targetlib',
      );
      if (result.exitCode != 0) {
        throw ProcessException(executable, args, output, result.exitCode);
      }
      final status = action == 'status'
          ? _parseStatus(output)
          : TargetLibServiceStatus.unknown;
      if (action == 'status') {
        _cachedStatus = status;
        _cachedBasePath = basePath;
      } else if (action == 'start') {
        _cachedStatus = TargetLibServiceStatus.running;
        _cachedBasePath = basePath;
      } else if (action == 'stop') {
        _cachedStatus = TargetLibServiceStatus.stopped;
        _cachedBasePath = basePath;
      } else if (action == 'uninstall') {
        _cachedStatus = TargetLibServiceStatus.notInstalled;
        _cachedBasePath = basePath;
      }
      return TargetLibServiceResult(status, output: output);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service action failed: action=$action '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'targetlib',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Installs and starts the service in a single elevation prompt.
  Future<TargetLibServiceResult> installAndStart({
    required String basePath,
    String workingPath = '',
    String tempPath = '',
    String locale = '',
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info(
      'Service install+start started: basePath=$basePath '
      'workingPath=${_displayOptional(workingPath)} '
      'tempPath=${_displayOptional(tempPath)} locale=${_displayOptional(locale)}',
      source: 'targetlib',
    );
    try {
      final executable = await resolveExecutable();
      final installArgs = _buildActionArgs(
        'install',
        basePath,
        workingPath,
        tempPath,
        locale,
      );
      final startArgs = _buildActionArgs(
        'start',
        basePath,
        workingPath,
        tempPath,
        locale,
      );
      final result = await _runElevated(executable, [installArgs, startArgs]);
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (stdout.isNotEmpty) {
        AppLogger.info('stdout:\n$stdout', source: 'targetlib');
      }
      if (stderr.isNotEmpty) {
        AppLogger.warning('stderr:\n$stderr', source: 'targetlib');
      }
      final output = [
        stdout,
        stderr,
      ].where((value) => value.isNotEmpty).join('\n');
      AppLogger.info(
        'Service install+start exited: exitCode=${result.exitCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'targetlib',
      );
      if (result.exitCode != 0) {
        throw ProcessException(
          executable,
          const ['install', 'start'],
          output,
          result.exitCode,
        );
      }
      _cachedStatus = TargetLibServiceStatus.running;
      _cachedBasePath = basePath;
      return TargetLibServiceResult(
        TargetLibServiceStatus.running,
        output: output,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service install+start failed: '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'targetlib',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProcessResult> _runElevated(
    String executable,
    List<List<String>> invocations,
  ) {
    if (Platform.isWindows) {
      return _runElevatedWindows(executable, invocations);
    }
    if (Platform.isMacOS) {
      final script = invocations
          .map((args) => [executable, ...args].map(_shellQuote).join(' '))
          .join(' && ');
      return Process.run('osascript', [
        '-e',
        'do shell script ${_appleScriptQuote(script)} '
            'with administrator privileges',
      ]);
    }
    return _runPkexecOrSudo(executable, invocations);
  }

  /// Runs the invocations elevated via UAC. A single minimal PowerShell is
  /// used only to trigger `Start-Process -Verb RunAs`; the elevated process
  /// writes its output to a temp file that Dart reads back directly.
  Future<ProcessResult> _runElevatedWindows(
    String executable,
    List<List<String>> invocations,
  ) async {
    final nonce = '${pid}_${DateTime.now().microsecondsSinceEpoch}';
    final outputPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'target_targetlib_$nonce.output.log';
    // Pre-create the file so it is owned by the current (non-elevated) user;
    // the elevated process only overwrites its contents.
    await File(outputPath).create(recursive: true);
    final elevatedCommand = _buildWindowsElevatedCommand(
      executable,
      invocations,
      outputPath,
    );
    final encodedCommand = _encodePowerShellCommand(elevatedCommand);
    AppLogger.info(
      'Requesting Windows administrator privileges',
      source: 'targetlib',
    );
    final argList = _powershellQuote(
      '-NoProfile -NonInteractive -EncodedCommand $encodedCommand',
    );
    final outerScript = "try { "
        "\$process = Start-Process -FilePath 'powershell.exe' "
        "-ArgumentList $argList "
        "-Verb RunAs -Wait -PassThru; "
        "if (\$null -eq \$process) { exit 1 } else { exit \$process.ExitCode } "
        "} catch { exit 1 }";
    final outer = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      outerScript,
    ]);
    var content = await _readAndDeleteTempFile(outputPath);
    if (content.isEmpty && outer.exitCode != 0) {
      content =
          'The elevated operation failed or was canceled '
          '(exit code ${outer.exitCode}).';
    }
    return ProcessResult(outer.pid, outer.exitCode, content, '');
  }

  String _buildWindowsElevatedCommand(
    String executable,
    List<List<String>> invocations,
    String outputPath,
  ) {
    final outQuoted = _powershellQuote(outputPath);
    final lines = <String>[];
    for (var i = 0; i < invocations.length; i++) {
      final invocation = invocations[i];
      final append = i == 0 ? '' : ' -Append';
      lines.add(
        '& ${_powershellQuote(executable)} '
        '${invocation.map(_powershellQuote).join(' ')} '
        '2>&1 | Out-File -LiteralPath $outQuoted -Encoding utf8$append',
      );
      if (i < invocations.length - 1) {
        lines.add(r'if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }');
      }
    }
    lines.add(r'exit $LASTEXITCODE');
    return 'try { ${lines.join('; ')} } catch { '
        r'$_ | Out-File -LiteralPath '
        '$outQuoted -Encoding utf8 -Append; exit 1 }';
  }

  Future<String> _readAndDeleteTempFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return '';
    try {
      final bytes = await file.readAsBytes();
      return _decodeWithBom(bytes);
    } finally {
      try {
        await file.delete();
      } on Object {
        // Best effort cleanup; ignore failures.
      }
    }
  }

  String _decodeWithBom(List<int> bytes) {
    var offset = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      offset = 3; // Strip UTF-8 BOM written by Out-File -Encoding utf8.
    }
    return utf8.decode(bytes.sublist(offset), allowMalformed: true);
  }

  Future<ProcessResult> _runPkexecOrSudo(
    String executable,
    List<List<String>> invocations,
  ) async {
    if (invocations.length == 1) {
      final args = invocations.single;
      try {
        final pkexec = await Process.run('pkexec', [executable, ...args]);
        if (pkexec.exitCode != 127) return pkexec;
      } on ProcessException {
        // Fall through to sudo on minimal Linux installations.
      }
      return Process.run('sudo', [executable, ...args]);
    }
    final script = invocations
        .map((args) => [executable, ...args].map(_shellQuote).join(' '))
        .join(' && ');
    try {
      final pkexec = await Process.run('pkexec', ['/bin/sh', '-c', script]);
      if (pkexec.exitCode != 127) return pkexec;
    } on ProcessException {
      // Fall through to sudo on minimal Linux installations.
    }
    return Process.run('sudo', ['/bin/sh', '-c', script]);
  }

  Future<TargetLibServiceResult> _queryStatusWindows(String basePath) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info(
      'Querying service status via sc.exe (no elevation required)',
      source: 'targetlib',
    );
    try {
      final result = await Process.run('sc.exe', [
        'query',
        _windowsServiceName,
      ]);
      final output = '${result.stdout}\n${result.stderr}'.trim();
      final TargetLibServiceStatus status;
      if (result.exitCode == 0) {
        status = _parseScQueryState(output);
      } else if (_isServiceMissing(output, result.exitCode)) {
        status = TargetLibServiceStatus.notInstalled;
      } else {
        status = TargetLibServiceStatus.unknown;
      }
      _cachedStatus = status;
      _cachedBasePath = basePath;
      AppLogger.info(
        'Service status resolved: ${status.name} '
        '(elapsedMs=${stopwatch.elapsedMilliseconds})',
        source: 'targetlib',
      );
      return TargetLibServiceResult(status, output: output);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service status query failed',
        source: 'targetlib',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _isServiceMissing(String output, int exitCode) {
    final value = output.toLowerCase();
    return exitCode == 1060 ||
        value.contains('does not exist') ||
        value.contains('not installed');
  }

  TargetLibServiceStatus _parseScQueryState(String output) {
    final match = RegExp(r'STATE\s+:\s+\d+\s+(\w+)').firstMatch(output);
    return switch (match?.group(1)?.toUpperCase()) {
      'RUNNING' => TargetLibServiceStatus.running,
      'STOPPED' => TargetLibServiceStatus.stopped,
      'PAUSED' => TargetLibServiceStatus.stopped,
      _ => TargetLibServiceStatus.unknown,
    };
  }

  String _powershellQuote(String value) => "'${value.replaceAll("'", "''")}'";

  String _encodePowerShellCommand(String command) {
    final bytes = <int>[];
    for (final codeUnit in command.codeUnits) {
      bytes
        ..add(codeUnit & 0xff)
        ..add(codeUnit >> 8);
    }
    return base64Encode(bytes);
  }

  String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  String _appleScriptQuote(String value) =>
      '"${value.replaceAll('\\', '\\\\').replaceAll('"', '${String.fromCharCode(92)}"')}"';

  List<String> _buildActionArgs(
    String action,
    String basePath,
    String workingPath,
    String tempPath,
    String locale,
  ) {
    final args = <String>[action, '--base-path', basePath];
    if (workingPath.trim().isNotEmpty) {
      args.addAll(['--working-path', workingPath]);
    }
    if (tempPath.trim().isNotEmpty) {
      args.addAll(['--temp-path', tempPath]);
    }
    if (locale.trim().isNotEmpty) {
      args.addAll(['--locale', locale]);
    }
    return args;
  }

  Future<Process> launch({
    required String basePath,
    String workingPath = '',
    String tempPath = '',
    String locale = '',
  }) async {
    AppLogger.info(
      'Daemon launch started: basePath=$basePath '
      'workingPath=${_displayOptional(workingPath)} '
      'tempPath=${_displayOptional(tempPath)} locale=${_displayOptional(locale)}',
      source: 'targetlib',
    );
    try {
      final executable = await resolveExecutable();
      final args = <String>['--base-path', basePath];
      if (workingPath.trim().isNotEmpty) {
        args.addAll(['--working-path', workingPath]);
      }
      if (tempPath.trim().isNotEmpty) {
        args.addAll(['--temp-path', tempPath]);
      }
      if (locale.trim().isNotEmpty) {
        args.addAll(['--locale', locale]);
      }
      final process = await Process.start(executable, args);
      AppLogger.info(
        'Daemon process started: pid=${process.pid}',
        source: 'targetlib',
      );
      return process;
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Daemon launch failed',
        source: 'targetlib',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  TargetLibServiceStatus _parseStatus(String output) {
    final value = output.toLowerCase();
    if (value.contains('running')) return TargetLibServiceStatus.running;
    if (value.contains('stopped')) return TargetLibServiceStatus.stopped;
    if (value.contains('not installed') || value.contains('does not exist')) {
      return TargetLibServiceStatus.notInstalled;
    }
    return TargetLibServiceStatus.unknown;
  }

  List<String> _optional(String? value) =>
      value == null || value.isEmpty ? const [] : [value];

  String _displayOptional(String value) =>
      value.trim().isEmpty ? '<default>' : value;
}

// Backward-compatible aliases.
typedef LibboxdServiceManager = TargetLibServiceManager;
