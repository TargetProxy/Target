import 'dart:io';

import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import 'package:targetlib/targetlib.dart';

const _socketName = 'targetlib.sock';

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
    final version = await connection.client.getVersion(
      Empty(),
      options: connection.options,
    );
    final state = await connection.client.getState(
      Empty(),
      options: connection.options,
    );
    final list = await connection.client.listSubscriptions(
      Empty(),
      options: connection.options,
    );

    stdout.writeln('transport=${connection.transport}');
    stdout.writeln(
      'targetlib=${version.targetlibVersion} '
      'sing-box=${version.singBoxVersion} protocol=${version.protocolVersion}',
    );
    stdout.writeln(
      'state=${state.state.name} subscriptions=${list.subscriptions.length}',
    );
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
    await connection.close();
  }
}

Future<TargetLibConnection> _connect(String socketPath) =>
    TargetLibConnection.connect(socketPath: socketPath);
