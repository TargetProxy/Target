import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';

enum TargetLibServiceStatus { running, stopped, unknown, notInstalled }

class TargetLibServiceResult {
  const TargetLibServiceResult(this.status, {this.output = ''});

  final TargetLibServiceStatus status;
  final String output;
}

/// Controls the standalone TargetLib executable. This deliberately uses the
/// daemon's CLI so it works on Windows SCM and Linux systemd alike.
class TargetLibServiceManager {
  TargetLibServiceManager([this._executablePath]);

  /// The Windows service name registered by the daemon. Must match the name
  /// the daemon uses with kardianos/service (verified via `sc.exe query`).
  static const String _windowsServiceName = 'TargetLib';

  final String? _executablePath;

  Future<String> resolveExecutable() async {
    final exeSuffix = Platform.isWindows ? '.exe' : '';
    final baseDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      ..._optional(_executablePath),
      '$baseDir${Platform.pathSeparator}TargetLib$exeSuffix',
      '$baseDir${Platform.pathSeparator}bin${Platform.pathSeparator}TargetLib$exeSuffix',
    ];
    String? bundled;
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        bundled = candidate;
        break;
      }
    }
    if (bundled == null) {
      throw StateError(
        'TargetLib executable is not bundled with this application. '
        'Rebuild the desktop target to include TargetLib$exeSuffix.',
      );
    }
    final support = await getApplicationSupportDirectory();
    final targetDir = Directory(
      '${support.path}${Platform.pathSeparator}TargetLib${Platform.pathSeparator}bin',
    );
    await targetDir.create(recursive: true);
    final target = File(
      '${targetDir.path}${Platform.pathSeparator}TargetLib$exeSuffix',
    );
    final source = File(bundled);
    final sourceStat = await source.stat();
    final stamp = File('${target.path}.version');
    final expectedStamp =
        '${sourceStat.size}:${sourceStat.modified.microsecondsSinceEpoch}';
    final currentStamp = await stamp.exists() ? await stamp.readAsString() : '';
    if (!await target.exists() || currentStamp != expectedStamp) {
      final temporary = File('${target.path}.new');
      await source.copy(temporary.path);
      try {
        if (await target.exists()) {
          await _releaseWindowsTarget(target.path);
          await target.delete();
        }
        await temporary.rename(target.path);
        await stamp.writeAsString(expectedStamp, flush: true);
      } catch (_) {
        if (await temporary.exists()) await temporary.delete();
        rethrow;
      }
    }
    AppLogger.debug('Resolved executable: ${target.path}', source: 'TargetLib');
    return target.path;
  }

  /// A previous daemon instance can survive service removal and keep the
  /// cached executable open. Stop only processes whose executable path is
  /// exactly the cache target before replacing it.
  Future<void> _releaseWindowsTarget(String path) async {
    if (!Platform.isWindows) return;
    final escaped = path.replaceAll("'", "''");
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "Get-CimInstance Win32_Process | Where-Object { \$_.ExecutablePath -eq '$escaped' } | Select-Object -ExpandProperty ProcessId",
    ]);
    final pids = result.stdout
        .toString()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>();
    for (final pid in pids) {
      await Process.run('taskkill.exe', ['/PID', '$pid', '/T', '/F']);
    }
    if (pids.isNotEmpty) {
      for (var i = 0; i < 10 && await File(path).exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        try {
          final handle = await File(path).open(mode: FileMode.append);
          await handle.close();
          break;
        } on Object {
          // The process may need a few milliseconds to release its handle.
        }
      }
    }
  }

  Future<TargetLibServiceResult> run(
    String action, {
    required String basePath,
    String workingPath = '',
    String tempPath = '',
    String locale = '',
    bool elevated = true,
  }) async {
    // Querying status never needs admin rights. On Windows the daemon's own
    // `status` opens the service with START/STOP access and gets rejected
    // non-elevated, so use `sc.exe query` instead. Elsewhere the daemon's
    // status is queried without elevation.
    if (action == 'status' && Platform.isWindows) {
      return _queryStatusWindows();
    }
    final effectiveElevated = action == 'status' ? false : elevated;
    final stopwatch = Stopwatch()..start();
    AppLogger.info(
      'Service action started: action=$action elevated=$effectiveElevated '
      'basePath=$basePath workingPath=${_displayOptional(workingPath)} '
      'tempPath=${_displayOptional(tempPath)} locale=${_displayOptional(locale)}',
      source: 'TargetLib',
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
        AppLogger.info('stdout:\n$stdout', source: 'TargetLib');
      }
      if (stderr.isNotEmpty) {
        AppLogger.warning('stderr:\n$stderr', source: 'TargetLib');
      }
      final output = [
        stdout,
        stderr,
      ].where((value) => value.isNotEmpty).join('\n');
      AppLogger.info(
        'Service action exited: action=$action exitCode=${result.exitCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'TargetLib',
      );
      if (result.exitCode != 0) {
        throw ProcessException(executable, args, output, result.exitCode);
      }
      final status = action == 'status'
          ? _parseStatus(output)
          : TargetLibServiceStatus.unknown;
      return TargetLibServiceResult(status, output: output);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service action failed: action=$action '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'TargetLib',
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
      source: 'TargetLib',
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
        AppLogger.info('stdout:\n$stdout', source: 'TargetLib');
      }
      if (stderr.isNotEmpty) {
        AppLogger.warning('stderr:\n$stderr', source: 'TargetLib');
      }
      final output = [
        stdout,
        stderr,
      ].where((value) => value.isNotEmpty).join('\n');
      AppLogger.info(
        'Service install+start exited: exitCode=${result.exitCode} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'TargetLib',
      );
      if (result.exitCode != 0) {
        throw ProcessException(
          executable,
          const ['install', 'start'],
          output,
          result.exitCode,
        );
      }
      return TargetLibServiceResult(
        TargetLibServiceStatus.running,
        output: output,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service install+start failed: '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        source: 'TargetLib',
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
        'target_TargetLib_$nonce.output.log';
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
      source: 'TargetLib',
    );
    final argList = _powershellQuote(
      '-NoProfile -NonInteractive -EncodedCommand $encodedCommand',
    );
    final outerScript =
        "try { "
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

  Future<TargetLibServiceResult> _queryStatusWindows() async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info(
      'Querying service status via sc.exe (no elevation required)',
      source: 'TargetLib',
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
      AppLogger.info(
        'Service status resolved: ${status.name} '
        '(elapsedMs=${stopwatch.elapsedMilliseconds})',
        source: 'TargetLib',
      );
      return TargetLibServiceResult(status, output: output);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Service status query failed',
        source: 'TargetLib',
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
      source: 'TargetLib',
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
        source: 'TargetLib',
      );
      return process;
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Daemon launch failed',
        source: 'TargetLib',
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
