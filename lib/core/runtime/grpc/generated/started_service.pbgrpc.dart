// This is a generated file - do not edit.
//
// Generated from started_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'started_service.pb.dart' as $1;

export 'started_service.pb.dart';

@$pb.GrpcServiceName('daemon.StartedService')
class StartedServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  StartedServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$1.ServiceStatus> subscribeServiceStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeServiceStatus, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.Log> subscribeLog(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeLog, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.Empty> clearLogs(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$clearLogs, request, options: options);
  }

  $grpc.ResponseStream<$1.Status> subscribeStatus(
    $1.SubscribeStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeStatus, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.Groups> subscribeGroups(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeGroups, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.Empty> uRLTest(
    $1.URLTestRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$uRLTest, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> selectOutbound(
    $1.SelectOutboundRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$selectOutbound, request, options: options);
  }

  $grpc.ResponseStream<$1.ConnectionEvents> subscribeConnections(
    $1.SubscribeConnectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeConnections, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.Empty> closeConnection(
    $1.CloseConnectionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> closeAllConnections(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeAllConnections, request, options: options);
  }

  // method descriptors

  static final _$subscribeServiceStatus =
      $grpc.ClientMethod<$0.Empty, $1.ServiceStatus>(
          '/daemon.StartedService/SubscribeServiceStatus',
          ($0.Empty value) => value.writeToBuffer(),
          $1.ServiceStatus.fromBuffer);
  static final _$subscribeLog = $grpc.ClientMethod<$0.Empty, $1.Log>(
      '/daemon.StartedService/SubscribeLog',
      ($0.Empty value) => value.writeToBuffer(),
      $1.Log.fromBuffer);
  static final _$clearLogs = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/daemon.StartedService/ClearLogs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$subscribeStatus =
      $grpc.ClientMethod<$1.SubscribeStatusRequest, $1.Status>(
          '/daemon.StartedService/SubscribeStatus',
          ($1.SubscribeStatusRequest value) => value.writeToBuffer(),
          $1.Status.fromBuffer);
  static final _$subscribeGroups = $grpc.ClientMethod<$0.Empty, $1.Groups>(
      '/daemon.StartedService/SubscribeGroups',
      ($0.Empty value) => value.writeToBuffer(),
      $1.Groups.fromBuffer);
  static final _$uRLTest = $grpc.ClientMethod<$1.URLTestRequest, $0.Empty>(
      '/daemon.StartedService/URLTest',
      ($1.URLTestRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$selectOutbound =
      $grpc.ClientMethod<$1.SelectOutboundRequest, $0.Empty>(
          '/daemon.StartedService/SelectOutbound',
          ($1.SelectOutboundRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$subscribeConnections =
      $grpc.ClientMethod<$1.SubscribeConnectionsRequest, $1.ConnectionEvents>(
          '/daemon.StartedService/SubscribeConnections',
          ($1.SubscribeConnectionsRequest value) => value.writeToBuffer(),
          $1.ConnectionEvents.fromBuffer);
  static final _$closeConnection =
      $grpc.ClientMethod<$1.CloseConnectionRequest, $0.Empty>(
          '/daemon.StartedService/CloseConnection',
          ($1.CloseConnectionRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$closeAllConnections = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/daemon.StartedService/CloseAllConnections',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
}

@$pb.GrpcServiceName('daemon.StartedService')
abstract class StartedServiceBase extends $grpc.Service {
  $core.String get $name => 'daemon.StartedService';

  StartedServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.ServiceStatus>(
        'SubscribeServiceStatus',
        subscribeServiceStatus_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.ServiceStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.Log>(
        'SubscribeLog',
        subscribeLog_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.Log value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'ClearLogs',
        clearLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SubscribeStatusRequest, $1.Status>(
        'SubscribeStatus',
        subscribeStatus_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.SubscribeStatusRequest.fromBuffer(value),
        ($1.Status value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.Groups>(
        'SubscribeGroups',
        subscribeGroups_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.Groups value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.URLTestRequest, $0.Empty>(
        'URLTest',
        uRLTest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.URLTestRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SelectOutboundRequest, $0.Empty>(
        'SelectOutbound',
        selectOutbound_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.SelectOutboundRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SubscribeConnectionsRequest,
            $1.ConnectionEvents>(
        'SubscribeConnections',
        subscribeConnections_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.SubscribeConnectionsRequest.fromBuffer(value),
        ($1.ConnectionEvents value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.CloseConnectionRequest, $0.Empty>(
        'CloseConnection',
        closeConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.CloseConnectionRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'CloseAllConnections',
        closeAllConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
  }

  $async.Stream<$1.ServiceStatus> subscribeServiceStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeServiceStatus($call, await $request);
  }

  $async.Stream<$1.ServiceStatus> subscribeServiceStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.Log> subscribeLog_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeLog($call, await $request);
  }

  $async.Stream<$1.Log> subscribeLog($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Empty> clearLogs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return clearLogs($call, await $request);
  }

  $async.Future<$0.Empty> clearLogs($grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.Status> subscribeStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$1.SubscribeStatusRequest> $request) async* {
    yield* subscribeStatus($call, await $request);
  }

  $async.Stream<$1.Status> subscribeStatus(
      $grpc.ServiceCall call, $1.SubscribeStatusRequest request);

  $async.Stream<$1.Groups> subscribeGroups_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeGroups($call, await $request);
  }

  $async.Stream<$1.Groups> subscribeGroups(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Empty> uRLTest_Pre($grpc.ServiceCall $call,
      $async.Future<$1.URLTestRequest> $request) async {
    return uRLTest($call, await $request);
  }

  $async.Future<$0.Empty> uRLTest(
      $grpc.ServiceCall call, $1.URLTestRequest request);

  $async.Future<$0.Empty> selectOutbound_Pre($grpc.ServiceCall $call,
      $async.Future<$1.SelectOutboundRequest> $request) async {
    return selectOutbound($call, await $request);
  }

  $async.Future<$0.Empty> selectOutbound(
      $grpc.ServiceCall call, $1.SelectOutboundRequest request);

  $async.Stream<$1.ConnectionEvents> subscribeConnections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SubscribeConnectionsRequest> $request) async* {
    yield* subscribeConnections($call, await $request);
  }

  $async.Stream<$1.ConnectionEvents> subscribeConnections(
      $grpc.ServiceCall call, $1.SubscribeConnectionsRequest request);

  $async.Future<$0.Empty> closeConnection_Pre($grpc.ServiceCall $call,
      $async.Future<$1.CloseConnectionRequest> $request) async {
    return closeConnection($call, await $request);
  }

  $async.Future<$0.Empty> closeConnection(
      $grpc.ServiceCall call, $1.CloseConnectionRequest request);

  $async.Future<$0.Empty> closeAllConnections_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return closeAllConnections($call, await $request);
  }

  $async.Future<$0.Empty> closeAllConnections(
      $grpc.ServiceCall call, $0.Empty request);
}
