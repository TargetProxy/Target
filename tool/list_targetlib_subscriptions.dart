import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import 'package:targetlib/src/generated/api/TargetLib/targetlib.pbgrpc.dart';

const _socketName = 'targetlib.sock';
const _host = '127.0.0.1';
const _port = 19090;

Future<void> main(List<String> args) async {
  final nodeFilter = args.isEmpty ? null : args.first.toLowerCase();
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) {
    stderr.writeln('APPDATA is not set.');
    exitCode = 1;
    return;
  }

  final socketPath = [
    appData,
    'top.loafman',
    'target',
    'core',
    _socketName,
  ].join(Platform.pathSeparator);

  final connection = await _connect(socketPath);
  try {
    final version = await connection.$2.getVersion(
      Empty(),
      options: connection.$3,
    );
    final state = await connection.$2.getState(Empty(), options: connection.$3);
    final list = await connection.$2.listSubscriptions(
      Empty(),
      options: connection.$3,
    );

    stdout.writeln('transport=${connection.$4}');
    stdout.writeln(
      'targetlib=${version.targetlibVersion} '
      'sing-box=${version.singBoxVersion} protocol=${version.protocolVersion}',
    );
    stdout.writeln('state=${state.state.name} active=${list.activeId}');
    stdout.writeln('subscriptions=${list.subscriptions.length}');
    for (final item in list.subscriptions) {
      stdout.writeln(
        [
          'id=${item.id}',
          'name=${item.name}',
          'status=${item.status.name}',
          'nodes=${item.profile.nodes.length}',
          'error=${item.errorMessage}',
          'updated=${item.updatedAtUnixMs}',
        ].join(' '),
      );
      final nodes = nodeFilter == null
          ? item.profile.nodes.take(5)
          : item.profile.nodes.where(
              (node) =>
                  node.tag.toLowerCase().contains(nodeFilter) ||
                  node.name.toLowerCase().contains(nodeFilter),
            );
      for (final node in nodes) {
        stdout.writeln(
          '  node tag=${node.tag} name=${node.name} type=${node.type} '
          'country=${node.countryCode} phase=${node.phase.name} '
          'server=${node.server}:${node.port}',
        );
      }
    }
  } finally {
    await connection.$1.shutdown();
  }
}

Future<(ClientChannel, TargetLibClient, CallOptions, String)> _connect(
  String socketPath,
) async {
  final options = CallOptions();
  final candidates = <(ClientChannel, String)>[];
  try {
    candidates.add((
      ClientChannel(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        port: 0,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      ),
      'unix',
    ));
  } on Object {
    // Unix sockets are not available on every host; fall back to TCP below.
  }
  candidates.add((
    ClientChannel(
      _host,
      port: _port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    ),
    'tcp',
  ));

  Object? lastError;
  for (final candidate in candidates) {
    final client = TargetLibClient(candidate.$1);
    try {
      await client
          .getVersion(Empty(), options: options)
          .timeout(const Duration(seconds: 2));
      return (candidate.$1, client, options, candidate.$2);
    } on Object catch (error) {
      lastError = error;
      await candidate.$1.shutdown();
    }
  }
  throw StateError('TargetLib command server is unavailable: $lastError');
}
