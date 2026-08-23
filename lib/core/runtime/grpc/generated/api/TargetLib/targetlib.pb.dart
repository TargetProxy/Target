// This is a generated file - do not edit.
//
// Generated from api/TargetLib/targetlib.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'targetlib.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'targetlib.pbenum.dart';

class VersionResponse extends $pb.GeneratedMessage {
  factory VersionResponse({
    $core.String? targetlibVersion,
    $core.String? singBoxVersion,
    $core.String? goVersion,
    $core.int? protocolVersion,
  }) {
    final result = create();
    if (targetlibVersion != null) result.targetlibVersion = targetlibVersion;
    if (singBoxVersion != null) result.singBoxVersion = singBoxVersion;
    if (goVersion != null) result.goVersion = goVersion;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    return result;
  }

  VersionResponse._();

  factory VersionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VersionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetlibVersion')
    ..aOS(2, _omitFieldNames ? '' : 'singBoxVersion')
    ..aOS(3, _omitFieldNames ? '' : 'goVersion')
    ..aI(4, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse copyWith(void Function(VersionResponse) updates) =>
      super.copyWith((message) => updates(message as VersionResponse))
          as VersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionResponse create() => VersionResponse._();
  @$core.override
  VersionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VersionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VersionResponse>(create);
  static VersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get targetlibVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetlibVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTargetlibVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetlibVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get singBoxVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set singBoxVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSingBoxVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearSingBoxVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get goVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set goVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGoVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearGoVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get protocolVersion => $_getIZ(3);
  @$pb.TagNumber(4)
  set protocolVersion($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocolVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocolVersion() => $_clearField(4);
}

class CapabilitiesResponse extends $pb.GeneratedMessage {
  factory CapabilitiesResponse({
    $core.String? platform,
    $core.bool? platformVpn,
    $core.bool? subscriptionManagement,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (platformVpn != null) result.platformVpn = platformVpn;
    if (subscriptionManagement != null)
      result.subscriptionManagement = subscriptionManagement;
    return result;
  }

  CapabilitiesResponse._();

  factory CapabilitiesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapabilitiesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapabilitiesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'platform')
    ..aOB(3, _omitFieldNames ? '' : 'platformVpn')
    ..aOB(5, _omitFieldNames ? '' : 'subscriptionManagement')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapabilitiesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapabilitiesResponse copyWith(void Function(CapabilitiesResponse) updates) =>
      super.copyWith((message) => updates(message as CapabilitiesResponse))
          as CapabilitiesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapabilitiesResponse create() => CapabilitiesResponse._();
  @$core.override
  CapabilitiesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapabilitiesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapabilitiesResponse>(create);
  static CapabilitiesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get platform => $_getSZ(0);
  @$pb.TagNumber(1)
  set platform($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.bool get platformVpn => $_getBF(1);
  @$pb.TagNumber(3)
  set platformVpn($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatformVpn() => $_has(1);
  @$pb.TagNumber(3)
  void clearPlatformVpn() => $_clearField(3);

  @$pb.TagNumber(5)
  $core.bool get subscriptionManagement => $_getBF(2);
  @$pb.TagNumber(5)
  set subscriptionManagement($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(5)
  $core.bool hasSubscriptionManagement() => $_has(2);
  @$pb.TagNumber(5)
  void clearSubscriptionManagement() => $_clearField(5);
}

class ConfigRequest extends $pb.GeneratedMessage {
  factory ConfigRequest({
    $core.String? content,
  }) {
    final result = create();
    if (content != null) result.content = content;
    return result;
  }

  ConfigRequest._();

  factory ConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigRequest copyWith(void Function(ConfigRequest) updates) =>
      super.copyWith((message) => updates(message as ConfigRequest))
          as ConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfigRequest create() => ConfigRequest._();
  @$core.override
  ConfigRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfigRequest>(create);
  static ConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get content => $_getSZ(0);
  @$pb.TagNumber(1)
  set content($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
}

class CheckConfigResponse extends $pb.GeneratedMessage {
  factory CheckConfigResponse({
    $core.bool? valid,
    $core.String? formattedError,
  }) {
    final result = create();
    if (valid != null) result.valid = valid;
    if (formattedError != null) result.formattedError = formattedError;
    return result;
  }

  CheckConfigResponse._();

  factory CheckConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'valid')
    ..aOS(2, _omitFieldNames ? '' : 'formattedError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckConfigResponse copyWith(void Function(CheckConfigResponse) updates) =>
      super.copyWith((message) => updates(message as CheckConfigResponse))
          as CheckConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckConfigResponse create() => CheckConfigResponse._();
  @$core.override
  CheckConfigResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckConfigResponse>(create);
  static CheckConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get valid => $_getBF(0);
  @$pb.TagNumber(1)
  set valid($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearValid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get formattedError => $_getSZ(1);
  @$pb.TagNumber(2)
  set formattedError($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormattedError() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormattedError() => $_clearField(2);
}

class StartRequest extends $pb.GeneratedMessage {
  factory StartRequest({
    $core.String? config,
  }) {
    final result = create();
    if (config != null) result.config = config;
    return result;
  }

  StartRequest._();

  factory StartRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'config')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartRequest copyWith(void Function(StartRequest) updates) =>
      super.copyWith((message) => updates(message as StartRequest))
          as StartRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartRequest create() => StartRequest._();
  @$core.override
  StartRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartRequest>(create);
  static StartRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get config => $_getSZ(0);
  @$pb.TagNumber(1)
  set config($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
}

class ReloadRequest extends $pb.GeneratedMessage {
  factory ReloadRequest({
    $core.String? config,
  }) {
    final result = create();
    if (config != null) result.config = config;
    return result;
  }

  ReloadRequest._();

  factory ReloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReloadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'config')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReloadRequest copyWith(void Function(ReloadRequest) updates) =>
      super.copyWith((message) => updates(message as ReloadRequest))
          as ReloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReloadRequest create() => ReloadRequest._();
  @$core.override
  ReloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReloadRequest>(create);
  static ReloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get config => $_getSZ(0);
  @$pb.TagNumber(1)
  set config($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
}

class RestartRequest extends $pb.GeneratedMessage {
  factory RestartRequest({
    $core.String? config,
  }) {
    final result = create();
    if (config != null) result.config = config;
    return result;
  }

  RestartRequest._();

  factory RestartRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RestartRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestartRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'config')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestartRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestartRequest copyWith(void Function(RestartRequest) updates) =>
      super.copyWith((message) => updates(message as RestartRequest))
          as RestartRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestartRequest create() => RestartRequest._();
  @$core.override
  RestartRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RestartRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestartRequest>(create);
  static RestartRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get config => $_getSZ(0);
  @$pb.TagNumber(1)
  set config($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
}

class OperationResponse extends $pb.GeneratedMessage {
  factory OperationResponse({
    ServiceState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  OperationResponse._();

  factory OperationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOM<ServiceState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: ServiceState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResponse copyWith(void Function(OperationResponse) updates) =>
      super.copyWith((message) => updates(message as OperationResponse))
          as OperationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationResponse create() => OperationResponse._();
  @$core.override
  OperationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationResponse>(create);
  static OperationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ServiceState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ServiceState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  ServiceState ensureState() => $_ensure(0);
}

class ServiceState extends $pb.GeneratedMessage {
  factory ServiceState({
    ServiceStateType? state,
    $core.String? errorMessage,
    $fixnum.Int64? changedAtUnixMs,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (errorMessage != null) result.errorMessage = errorMessage;
    if (changedAtUnixMs != null) result.changedAtUnixMs = changedAtUnixMs;
    return result;
  }

  ServiceState._();

  factory ServiceState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aE<ServiceStateType>(1, _omitFieldNames ? '' : 'state',
        enumValues: ServiceStateType.values)
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage')
    ..aInt64(3, _omitFieldNames ? '' : 'changedAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceState copyWith(void Function(ServiceState) updates) =>
      super.copyWith((message) => updates(message as ServiceState))
          as ServiceState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceState create() => ServiceState._();
  @$core.override
  ServiceState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceState>(create);
  static ServiceState? _defaultInstance;

  @$pb.TagNumber(1)
  ServiceStateType get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ServiceStateType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get changedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set changedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChangedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearChangedAtUnixMs() => $_clearField(3);
}

class SubscriptionId extends $pb.GeneratedMessage {
  factory SubscriptionId({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  SubscriptionId._();

  factory SubscriptionId.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionId.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionId',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionId clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionId copyWith(void Function(SubscriptionId) updates) =>
      super.copyWith((message) => updates(message as SubscriptionId))
          as SubscriptionId;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionId create() => SubscriptionId._();
  @$core.override
  SubscriptionId createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionId getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionId>(create);
  static SubscriptionId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class AddSubscriptionRequest extends $pb.GeneratedMessage {
  factory AddSubscriptionRequest({
    $core.String? id,
    $core.String? name,
    $core.String? url,
    $core.bool? enabled,
    $core.bool? autoUpdate,
    $fixnum.Int64? updateIntervalSeconds,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? headers,
    $core.bool? activate,
    $core.bool? updateNow,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (url != null) result.url = url;
    if (enabled != null) result.enabled = enabled;
    if (autoUpdate != null) result.autoUpdate = autoUpdate;
    if (updateIntervalSeconds != null)
      result.updateIntervalSeconds = updateIntervalSeconds;
    if (headers != null) result.headers.addEntries(headers);
    if (activate != null) result.activate = activate;
    if (updateNow != null) result.updateNow = updateNow;
    return result;
  }

  AddSubscriptionRequest._();

  factory AddSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..aOB(5, _omitFieldNames ? '' : 'autoUpdate')
    ..aInt64(6, _omitFieldNames ? '' : 'updateIntervalSeconds')
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'headers',
        entryClassName: 'AddSubscriptionRequest.HeadersEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('targetlib'))
    ..aOB(8, _omitFieldNames ? '' : 'activate')
    ..aOB(9, _omitFieldNames ? '' : 'updateNow')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddSubscriptionRequest copyWith(
          void Function(AddSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as AddSubscriptionRequest))
          as AddSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddSubscriptionRequest create() => AddSubscriptionRequest._();
  @$core.override
  AddSubscriptionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddSubscriptionRequest>(create);
  static AddSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get autoUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set autoUpdate($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAutoUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoUpdate() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updateIntervalSeconds => $_getI64(5);
  @$pb.TagNumber(6)
  set updateIntervalSeconds($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdateIntervalSeconds() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdateIntervalSeconds() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get headers => $_getMap(6);

  @$pb.TagNumber(8)
  $core.bool get activate => $_getBF(7);
  @$pb.TagNumber(8)
  set activate($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasActivate() => $_has(7);
  @$pb.TagNumber(8)
  void clearActivate() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get updateNow => $_getBF(8);
  @$pb.TagNumber(9)
  set updateNow($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdateNow() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdateNow() => $_clearField(9);
}

class RenameSubscriptionRequest extends $pb.GeneratedMessage {
  factory RenameSubscriptionRequest({
    $core.String? id,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  RenameSubscriptionRequest._();

  factory RenameSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameSubscriptionRequest copyWith(
          void Function(RenameSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as RenameSubscriptionRequest))
          as RenameSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameSubscriptionRequest create() => RenameSubscriptionRequest._();
  @$core.override
  RenameSubscriptionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameSubscriptionRequest>(create);
  static RenameSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class SetSubscriptionEnabledRequest extends $pb.GeneratedMessage {
  factory SetSubscriptionEnabledRequest({
    $core.String? id,
    $core.bool? enabled,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetSubscriptionEnabledRequest._();

  factory SetSubscriptionEnabledRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetSubscriptionEnabledRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSubscriptionEnabledRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSubscriptionEnabledRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSubscriptionEnabledRequest copyWith(
          void Function(SetSubscriptionEnabledRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetSubscriptionEnabledRequest))
          as SetSubscriptionEnabledRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetSubscriptionEnabledRequest create() =>
      SetSubscriptionEnabledRequest._();
  @$core.override
  SetSubscriptionEnabledRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetSubscriptionEnabledRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSubscriptionEnabledRequest>(create);
  static SetSubscriptionEnabledRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class ConfigureSubscriptionUpdatesRequest extends $pb.GeneratedMessage {
  factory ConfigureSubscriptionUpdatesRequest({
    $core.String? id,
    $core.bool? enabled,
    $fixnum.Int64? updateIntervalSeconds,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (enabled != null) result.enabled = enabled;
    if (updateIntervalSeconds != null)
      result.updateIntervalSeconds = updateIntervalSeconds;
    return result;
  }

  ConfigureSubscriptionUpdatesRequest._();

  factory ConfigureSubscriptionUpdatesRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConfigureSubscriptionUpdatesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfigureSubscriptionUpdatesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aInt64(3, _omitFieldNames ? '' : 'updateIntervalSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigureSubscriptionUpdatesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigureSubscriptionUpdatesRequest copyWith(
          void Function(ConfigureSubscriptionUpdatesRequest) updates) =>
      super.copyWith((message) =>
              updates(message as ConfigureSubscriptionUpdatesRequest))
          as ConfigureSubscriptionUpdatesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfigureSubscriptionUpdatesRequest create() =>
      ConfigureSubscriptionUpdatesRequest._();
  @$core.override
  ConfigureSubscriptionUpdatesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConfigureSubscriptionUpdatesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          ConfigureSubscriptionUpdatesRequest>(create);
  static ConfigureSubscriptionUpdatesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get updateIntervalSeconds => $_getI64(2);
  @$pb.TagNumber(3)
  set updateIntervalSeconds($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdateIntervalSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateIntervalSeconds() => $_clearField(3);
}

class ResolvedEndpointsRequest extends $pb.GeneratedMessage {
  factory ResolvedEndpointsRequest({
    $core.bool? enabledOnly,
  }) {
    final result = create();
    if (enabledOnly != null) result.enabledOnly = enabledOnly;
    return result;
  }

  ResolvedEndpointsRequest._();

  factory ResolvedEndpointsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolvedEndpointsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolvedEndpointsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabledOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedEndpointsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedEndpointsRequest copyWith(
          void Function(ResolvedEndpointsRequest) updates) =>
      super.copyWith((message) => updates(message as ResolvedEndpointsRequest))
          as ResolvedEndpointsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedEndpointsRequest create() => ResolvedEndpointsRequest._();
  @$core.override
  ResolvedEndpointsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResolvedEndpointsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolvedEndpointsRequest>(create);
  static ResolvedEndpointsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabledOnly => $_getBF(0);
  @$pb.TagNumber(1)
  set enabledOnly($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabledOnly() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabledOnly() => $_clearField(1);
}

class SubscriptionList extends $pb.GeneratedMessage {
  factory SubscriptionList({
    $core.Iterable<SubscriptionView>? subscriptions,
    $core.String? activeId,
  }) {
    final result = create();
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
    if (activeId != null) result.activeId = activeId;
    return result;
  }

  SubscriptionList._();

  factory SubscriptionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..pPM<SubscriptionView>(1, _omitFieldNames ? '' : 'subscriptions',
        subBuilder: SubscriptionView.create)
    ..aOS(2, _omitFieldNames ? '' : 'activeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionList copyWith(void Function(SubscriptionList) updates) =>
      super.copyWith((message) => updates(message as SubscriptionList))
          as SubscriptionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionList create() => SubscriptionList._();
  @$core.override
  SubscriptionList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionList>(create);
  static SubscriptionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SubscriptionView> get subscriptions => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get activeId => $_getSZ(1);
  @$pb.TagNumber(2)
  set activeId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActiveId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActiveId() => $_clearField(2);
}

class SubscriptionView extends $pb.GeneratedMessage {
  factory SubscriptionView({
    $core.String? id,
    $core.String? name,
    $core.String? source,
    $core.bool? enabled,
    $core.bool? autoUpdate,
    $fixnum.Int64? updateIntervalSeconds,
    SubscriptionStatus? status,
    SubscriptionUpdateStage? stage,
    $core.Iterable<SubscriptionNode>? nodes,
    $core.String? errorCode,
    $core.String? errorMessage,
    $fixnum.Int64? updatedAtUnixMs,
    $fixnum.Int64? nextUpdateAtUnixMs,
    $fixnum.Int64? uploadBytes,
    $fixnum.Int64? downloadBytes,
    $fixnum.Int64? totalBytes,
    $fixnum.Int64? expiresAtUnixMs,
    $core.String? title,
    $core.String? webPageUrl,
    $core.String? supportUrl,
    $core.String? movedPermanentlyTo,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (source != null) result.source = source;
    if (enabled != null) result.enabled = enabled;
    if (autoUpdate != null) result.autoUpdate = autoUpdate;
    if (updateIntervalSeconds != null)
      result.updateIntervalSeconds = updateIntervalSeconds;
    if (status != null) result.status = status;
    if (stage != null) result.stage = stage;
    if (nodes != null) result.nodes.addAll(nodes);
    if (errorCode != null) result.errorCode = errorCode;
    if (errorMessage != null) result.errorMessage = errorMessage;
    if (updatedAtUnixMs != null) result.updatedAtUnixMs = updatedAtUnixMs;
    if (nextUpdateAtUnixMs != null)
      result.nextUpdateAtUnixMs = nextUpdateAtUnixMs;
    if (uploadBytes != null) result.uploadBytes = uploadBytes;
    if (downloadBytes != null) result.downloadBytes = downloadBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (expiresAtUnixMs != null) result.expiresAtUnixMs = expiresAtUnixMs;
    if (title != null) result.title = title;
    if (webPageUrl != null) result.webPageUrl = webPageUrl;
    if (supportUrl != null) result.supportUrl = supportUrl;
    if (movedPermanentlyTo != null)
      result.movedPermanentlyTo = movedPermanentlyTo;
    return result;
  }

  SubscriptionView._();

  factory SubscriptionView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionView',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..aOB(5, _omitFieldNames ? '' : 'autoUpdate')
    ..aInt64(6, _omitFieldNames ? '' : 'updateIntervalSeconds')
    ..aE<SubscriptionStatus>(7, _omitFieldNames ? '' : 'status',
        enumValues: SubscriptionStatus.values)
    ..aE<SubscriptionUpdateStage>(8, _omitFieldNames ? '' : 'stage',
        enumValues: SubscriptionUpdateStage.values)
    ..pPM<SubscriptionNode>(9, _omitFieldNames ? '' : 'nodes',
        subBuilder: SubscriptionNode.create)
    ..aOS(10, _omitFieldNames ? '' : 'errorCode')
    ..aOS(11, _omitFieldNames ? '' : 'errorMessage')
    ..aInt64(12, _omitFieldNames ? '' : 'updatedAtUnixMs')
    ..aInt64(13, _omitFieldNames ? '' : 'nextUpdateAtUnixMs')
    ..aInt64(14, _omitFieldNames ? '' : 'uploadBytes')
    ..aInt64(15, _omitFieldNames ? '' : 'downloadBytes')
    ..aInt64(16, _omitFieldNames ? '' : 'totalBytes')
    ..aInt64(17, _omitFieldNames ? '' : 'expiresAtUnixMs')
    ..aOS(18, _omitFieldNames ? '' : 'title')
    ..aOS(19, _omitFieldNames ? '' : 'webPageUrl')
    ..aOS(20, _omitFieldNames ? '' : 'supportUrl')
    ..aOS(21, _omitFieldNames ? '' : 'movedPermanentlyTo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionView clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionView copyWith(void Function(SubscriptionView) updates) =>
      super.copyWith((message) => updates(message as SubscriptionView))
          as SubscriptionView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionView create() => SubscriptionView._();
  @$core.override
  SubscriptionView createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionView getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionView>(create);
  static SubscriptionView? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get autoUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set autoUpdate($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAutoUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoUpdate() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get updateIntervalSeconds => $_getI64(5);
  @$pb.TagNumber(6)
  set updateIntervalSeconds($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdateIntervalSeconds() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdateIntervalSeconds() => $_clearField(6);

  @$pb.TagNumber(7)
  SubscriptionStatus get status => $_getN(6);
  @$pb.TagNumber(7)
  set status(SubscriptionStatus value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);

  @$pb.TagNumber(8)
  SubscriptionUpdateStage get stage => $_getN(7);
  @$pb.TagNumber(8)
  set stage(SubscriptionUpdateStage value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStage() => $_has(7);
  @$pb.TagNumber(8)
  void clearStage() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<SubscriptionNode> get nodes => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get errorCode => $_getSZ(9);
  @$pb.TagNumber(10)
  set errorCode($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasErrorCode() => $_has(9);
  @$pb.TagNumber(10)
  void clearErrorCode() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get errorMessage => $_getSZ(10);
  @$pb.TagNumber(11)
  set errorMessage($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasErrorMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearErrorMessage() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get updatedAtUnixMs => $_getI64(11);
  @$pb.TagNumber(12)
  set updatedAtUnixMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAtUnixMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAtUnixMs() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get nextUpdateAtUnixMs => $_getI64(12);
  @$pb.TagNumber(13)
  set nextUpdateAtUnixMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasNextUpdateAtUnixMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearNextUpdateAtUnixMs() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get uploadBytes => $_getI64(13);
  @$pb.TagNumber(14)
  set uploadBytes($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasUploadBytes() => $_has(13);
  @$pb.TagNumber(14)
  void clearUploadBytes() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get downloadBytes => $_getI64(14);
  @$pb.TagNumber(15)
  set downloadBytes($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasDownloadBytes() => $_has(14);
  @$pb.TagNumber(15)
  void clearDownloadBytes() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get totalBytes => $_getI64(15);
  @$pb.TagNumber(16)
  set totalBytes($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasTotalBytes() => $_has(15);
  @$pb.TagNumber(16)
  void clearTotalBytes() => $_clearField(16);

  /// 订阅协议响应头元数据，服务器未提供时为零值。
  @$pb.TagNumber(17)
  $fixnum.Int64 get expiresAtUnixMs => $_getI64(16);
  @$pb.TagNumber(17)
  set expiresAtUnixMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasExpiresAtUnixMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearExpiresAtUnixMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get title => $_getSZ(17);
  @$pb.TagNumber(18)
  set title($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasTitle() => $_has(17);
  @$pb.TagNumber(18)
  void clearTitle() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get webPageUrl => $_getSZ(18);
  @$pb.TagNumber(19)
  set webPageUrl($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasWebPageUrl() => $_has(18);
  @$pb.TagNumber(19)
  void clearWebPageUrl() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get supportUrl => $_getSZ(19);
  @$pb.TagNumber(20)
  set supportUrl($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasSupportUrl() => $_has(19);
  @$pb.TagNumber(20)
  void clearSupportUrl() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get movedPermanentlyTo => $_getSZ(20);
  @$pb.TagNumber(21)
  set movedPermanentlyTo($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasMovedPermanentlyTo() => $_has(20);
  @$pb.TagNumber(21)
  void clearMovedPermanentlyTo() => $_clearField(21);
}

class SubscriptionNode extends $pb.GeneratedMessage {
  factory SubscriptionNode({
    $core.String? id,
    $core.String? name,
    $core.String? type,
    $core.String? server,
    $core.int? port,
    $core.String? group,
    $core.Iterable<$core.String>? groups,
    SubscriptionNodePhase? phase,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (server != null) result.server = server;
    if (port != null) result.port = port;
    if (group != null) result.group = group;
    if (groups != null) result.groups.addAll(groups);
    if (phase != null) result.phase = phase;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  SubscriptionNode._();

  factory SubscriptionNode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionNode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionNode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'server')
    ..aI(5, _omitFieldNames ? '' : 'port')
    ..aOS(6, _omitFieldNames ? '' : 'group')
    ..pPS(7, _omitFieldNames ? '' : 'groups')
    ..aE<SubscriptionNodePhase>(8, _omitFieldNames ? '' : 'phase',
        enumValues: SubscriptionNodePhase.values)
    ..aOS(9, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionNode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionNode copyWith(void Function(SubscriptionNode) updates) =>
      super.copyWith((message) => updates(message as SubscriptionNode))
          as SubscriptionNode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionNode create() => SubscriptionNode._();
  @$core.override
  SubscriptionNode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionNode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionNode>(create);
  static SubscriptionNode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get server => $_getSZ(3);
  @$pb.TagNumber(4)
  set server($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServer() => $_has(3);
  @$pb.TagNumber(4)
  void clearServer() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get port => $_getIZ(4);
  @$pb.TagNumber(5)
  set port($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get group => $_getSZ(5);
  @$pb.TagNumber(6)
  set group($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGroup() => $_has(5);
  @$pb.TagNumber(6)
  void clearGroup() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get groups => $_getList(6);

  @$pb.TagNumber(8)
  SubscriptionNodePhase get phase => $_getN(7);
  @$pb.TagNumber(8)
  set phase(SubscriptionNodePhase value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasPhase() => $_has(7);
  @$pb.TagNumber(8)
  void clearPhase() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get errorMessage => $_getSZ(8);
  @$pb.TagNumber(9)
  set errorMessage($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasErrorMessage() => $_has(8);
  @$pb.TagNumber(9)
  void clearErrorMessage() => $_clearField(9);
}

class SubscriptionUpdateResult extends $pb.GeneratedMessage {
  factory SubscriptionUpdateResult({
    SubscriptionView? subscription,
    $core.bool? changed,
    $core.bool? notModified,
    $fixnum.Int64? durationMilliseconds,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (changed != null) result.changed = changed;
    if (notModified != null) result.notModified = notModified;
    if (durationMilliseconds != null)
      result.durationMilliseconds = durationMilliseconds;
    return result;
  }

  SubscriptionUpdateResult._();

  factory SubscriptionUpdateResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionUpdateResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionUpdateResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOM<SubscriptionView>(1, _omitFieldNames ? '' : 'subscription',
        subBuilder: SubscriptionView.create)
    ..aOB(2, _omitFieldNames ? '' : 'changed')
    ..aOB(3, _omitFieldNames ? '' : 'notModified')
    ..aInt64(4, _omitFieldNames ? '' : 'durationMilliseconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionUpdateResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionUpdateResult copyWith(
          void Function(SubscriptionUpdateResult) updates) =>
      super.copyWith((message) => updates(message as SubscriptionUpdateResult))
          as SubscriptionUpdateResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionUpdateResult create() => SubscriptionUpdateResult._();
  @$core.override
  SubscriptionUpdateResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionUpdateResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionUpdateResult>(create);
  static SubscriptionUpdateResult? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionView get subscription => $_getN(0);
  @$pb.TagNumber(1)
  set subscription(SubscriptionView value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionView ensureSubscription() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get changed => $_getBF(1);
  @$pb.TagNumber(2)
  set changed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearChanged() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get notModified => $_getBF(2);
  @$pb.TagNumber(3)
  set notModified($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNotModified() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotModified() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get durationMilliseconds => $_getI64(3);
  @$pb.TagNumber(4)
  set durationMilliseconds($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDurationMilliseconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearDurationMilliseconds() => $_clearField(4);
}

class SubscriptionConfig extends $pb.GeneratedMessage {
  factory SubscriptionConfig({
    $core.List<$core.int>? content,
  }) {
    final result = create();
    if (content != null) result.content = content;
    return result;
  }

  SubscriptionConfig._();

  factory SubscriptionConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'content', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionConfig copyWith(void Function(SubscriptionConfig) updates) =>
      super.copyWith((message) => updates(message as SubscriptionConfig))
          as SubscriptionConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionConfig create() => SubscriptionConfig._();
  @$core.override
  SubscriptionConfig createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionConfig>(create);
  static SubscriptionConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get content => $_getN(0);
  @$pb.TagNumber(1)
  set content($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
}

class BuildConfigSettings extends $pb.GeneratedMessage {
  factory BuildConfigSettings({
    $core.String? listenAddress,
    $core.int? mixedPort,
    ProxyMode? proxyMode,
    $core.bool? ipv6,
    $core.String? cacheFilePath,
  }) {
    final result = create();
    if (listenAddress != null) result.listenAddress = listenAddress;
    if (mixedPort != null) result.mixedPort = mixedPort;
    if (proxyMode != null) result.proxyMode = proxyMode;
    if (ipv6 != null) result.ipv6 = ipv6;
    if (cacheFilePath != null) result.cacheFilePath = cacheFilePath;
    return result;
  }

  BuildConfigSettings._();

  factory BuildConfigSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BuildConfigSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildConfigSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'listenAddress')
    ..aI(2, _omitFieldNames ? '' : 'mixedPort', fieldType: $pb.PbFieldType.OU3)
    ..aE<ProxyMode>(3, _omitFieldNames ? '' : 'proxyMode',
        enumValues: ProxyMode.values)
    ..aOB(5, _omitFieldNames ? '' : 'ipv6')
    ..aOS(6, _omitFieldNames ? '' : 'cacheFilePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuildConfigSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuildConfigSettings copyWith(void Function(BuildConfigSettings) updates) =>
      super.copyWith((message) => updates(message as BuildConfigSettings))
          as BuildConfigSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildConfigSettings create() => BuildConfigSettings._();
  @$core.override
  BuildConfigSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BuildConfigSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildConfigSettings>(create);
  static BuildConfigSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get listenAddress => $_getSZ(0);
  @$pb.TagNumber(1)
  set listenAddress($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasListenAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearListenAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get mixedPort => $_getIZ(1);
  @$pb.TagNumber(2)
  set mixedPort($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMixedPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearMixedPort() => $_clearField(2);

  @$pb.TagNumber(3)
  ProxyMode get proxyMode => $_getN(2);
  @$pb.TagNumber(3)
  set proxyMode(ProxyMode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProxyMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearProxyMode() => $_clearField(3);

  @$pb.TagNumber(5)
  $core.bool get ipv6 => $_getBF(3);
  @$pb.TagNumber(5)
  set ipv6($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasIpv6() => $_has(3);
  @$pb.TagNumber(5)
  void clearIpv6() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get cacheFilePath => $_getSZ(4);
  @$pb.TagNumber(6)
  set cacheFilePath($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasCacheFilePath() => $_has(4);
  @$pb.TagNumber(6)
  void clearCacheFilePath() => $_clearField(6);
}

enum BuildConfigRequest_Source { subscriptionId, rawConfig, notSet }

class BuildConfigRequest extends $pb.GeneratedMessage {
  factory BuildConfigRequest({
    BuildConfigSettings? settings,
    $core.String? subscriptionId,
    $core.List<$core.int>? rawConfig,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (rawConfig != null) result.rawConfig = rawConfig;
    return result;
  }

  BuildConfigRequest._();

  factory BuildConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BuildConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, BuildConfigRequest_Source>
      _BuildConfigRequest_SourceByTag = {
    2: BuildConfigRequest_Source.subscriptionId,
    3: BuildConfigRequest_Source.rawConfig,
    0: BuildConfigRequest_Source.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOM<BuildConfigSettings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: BuildConfigSettings.create)
    ..aOS(2, _omitFieldNames ? '' : 'subscriptionId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'rawConfig', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuildConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BuildConfigRequest copyWith(void Function(BuildConfigRequest) updates) =>
      super.copyWith((message) => updates(message as BuildConfigRequest))
          as BuildConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildConfigRequest create() => BuildConfigRequest._();
  @$core.override
  BuildConfigRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BuildConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildConfigRequest>(create);
  static BuildConfigRequest? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  BuildConfigRequest_Source whichSource() =>
      _BuildConfigRequest_SourceByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearSource() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BuildConfigSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(BuildConfigSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  BuildConfigSettings ensureSettings() => $_ensure(0);

  /// 基于订阅中间态节点合成配置（urltest/selector 包装 + 应用入站主权）。
  @$pb.TagNumber(2)
  $core.String get subscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscriptionId() => $_clearField(2);

  /// 透传原始配置：替换 inbounds、迁移遗留写法、注入 cache_file。
  @$pb.TagNumber(3)
  $core.List<$core.int> get rawConfig => $_getN(2);
  @$pb.TagNumber(3)
  set rawConfig($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRawConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearRawConfig() => $_clearField(3);
}

class TestOutboundRequest extends $pb.GeneratedMessage {
  factory TestOutboundRequest({
    $core.String? outboundTag,
    $core.int? timeoutMilliseconds,
  }) {
    final result = create();
    if (outboundTag != null) result.outboundTag = outboundTag;
    if (timeoutMilliseconds != null)
      result.timeoutMilliseconds = timeoutMilliseconds;
    return result;
  }

  TestOutboundRequest._();

  factory TestOutboundRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestOutboundRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestOutboundRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outboundTag')
    ..aI(2, _omitFieldNames ? '' : 'timeoutMilliseconds',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestOutboundRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestOutboundRequest copyWith(void Function(TestOutboundRequest) updates) =>
      super.copyWith((message) => updates(message as TestOutboundRequest))
          as TestOutboundRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestOutboundRequest create() => TestOutboundRequest._();
  @$core.override
  TestOutboundRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestOutboundRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestOutboundRequest>(create);
  static TestOutboundRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outboundTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set outboundTag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOutboundTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutboundTag() => $_clearField(1);

  /// Zero uses the server default. Values above 60 seconds are rejected.
  @$pb.TagNumber(2)
  $core.int get timeoutMilliseconds => $_getIZ(1);
  @$pb.TagNumber(2)
  set timeoutMilliseconds($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeoutMilliseconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeoutMilliseconds() => $_clearField(2);
}

class TestOutboundsRequest extends $pb.GeneratedMessage {
  factory TestOutboundsRequest({
    $core.Iterable<$core.String>? outboundTags,
    $core.int? timeoutMilliseconds,
    $core.int? maxConcurrency,
  }) {
    final result = create();
    if (outboundTags != null) result.outboundTags.addAll(outboundTags);
    if (timeoutMilliseconds != null)
      result.timeoutMilliseconds = timeoutMilliseconds;
    if (maxConcurrency != null) result.maxConcurrency = maxConcurrency;
    return result;
  }

  TestOutboundsRequest._();

  factory TestOutboundsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TestOutboundsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestOutboundsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'outboundTags')
    ..aI(2, _omitFieldNames ? '' : 'timeoutMilliseconds',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'maxConcurrency',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestOutboundsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestOutboundsRequest copyWith(void Function(TestOutboundsRequest) updates) =>
      super.copyWith((message) => updates(message as TestOutboundsRequest))
          as TestOutboundsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestOutboundsRequest create() => TestOutboundsRequest._();
  @$core.override
  TestOutboundsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TestOutboundsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestOutboundsRequest>(create);
  static TestOutboundsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get outboundTags => $_getList(0);

  /// Zero uses the server default. Values above 60 seconds are rejected.
  @$pb.TagNumber(2)
  $core.int get timeoutMilliseconds => $_getIZ(1);
  @$pb.TagNumber(2)
  set timeoutMilliseconds($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeoutMilliseconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeoutMilliseconds() => $_clearField(2);

  /// Number of URLTest groups tested concurrently. Zero uses the server
  /// default; the server caps this at four.
  @$pb.TagNumber(3)
  $core.int get maxConcurrency => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxConcurrency($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxConcurrency() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxConcurrency() => $_clearField(3);
}

class LatencyTestResult extends $pb.GeneratedMessage {
  factory LatencyTestResult({
    $core.String? outboundTag,
    LatencyTestStatus? status,
    $core.int? delayMilliseconds,
    $fixnum.Int64? testedAtUnixMs,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (outboundTag != null) result.outboundTag = outboundTag;
    if (status != null) result.status = status;
    if (delayMilliseconds != null) result.delayMilliseconds = delayMilliseconds;
    if (testedAtUnixMs != null) result.testedAtUnixMs = testedAtUnixMs;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  LatencyTestResult._();

  factory LatencyTestResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LatencyTestResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LatencyTestResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outboundTag')
    ..aE<LatencyTestStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: LatencyTestStatus.values)
    ..aI(3, _omitFieldNames ? '' : 'delayMilliseconds',
        fieldType: $pb.PbFieldType.OU3)
    ..aInt64(4, _omitFieldNames ? '' : 'testedAtUnixMs')
    ..aOS(5, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LatencyTestResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LatencyTestResult copyWith(void Function(LatencyTestResult) updates) =>
      super.copyWith((message) => updates(message as LatencyTestResult))
          as LatencyTestResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LatencyTestResult create() => LatencyTestResult._();
  @$core.override
  LatencyTestResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LatencyTestResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LatencyTestResult>(create);
  static LatencyTestResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outboundTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set outboundTag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOutboundTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutboundTag() => $_clearField(1);

  @$pb.TagNumber(2)
  LatencyTestStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(LatencyTestStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get delayMilliseconds => $_getIZ(2);
  @$pb.TagNumber(3)
  set delayMilliseconds($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDelayMilliseconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearDelayMilliseconds() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get testedAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set testedAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTestedAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTestedAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get errorMessage => $_getSZ(4);
  @$pb.TagNumber(5)
  set errorMessage($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasErrorMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearErrorMessage() => $_clearField(5);
}

class ResolvedEndpoints extends $pb.GeneratedMessage {
  factory ResolvedEndpoints({
    $core.Iterable<$core.String>? addresses,
  }) {
    final result = create();
    if (addresses != null) result.addresses.addAll(addresses);
    return result;
  }

  ResolvedEndpoints._();

  factory ResolvedEndpoints.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolvedEndpoints.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolvedEndpoints',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'addresses')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedEndpoints clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolvedEndpoints copyWith(void Function(ResolvedEndpoints) updates) =>
      super.copyWith((message) => updates(message as ResolvedEndpoints))
          as ResolvedEndpoints;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedEndpoints create() => ResolvedEndpoints._();
  @$core.override
  ResolvedEndpoints createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResolvedEndpoints getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolvedEndpoints>(create);
  static ResolvedEndpoints? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get addresses => $_getList(0);
}

class SetActiveSubscriptionRequest extends $pb.GeneratedMessage {
  factory SetActiveSubscriptionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  SetActiveSubscriptionRequest._();

  factory SetActiveSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetActiveSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetActiveSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetActiveSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetActiveSubscriptionRequest copyWith(
          void Function(SetActiveSubscriptionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetActiveSubscriptionRequest))
          as SetActiveSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetActiveSubscriptionRequest create() =>
      SetActiveSubscriptionRequest._();
  @$core.override
  SetActiveSubscriptionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetActiveSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetActiveSubscriptionRequest>(create);
  static SetActiveSubscriptionRequest? _defaultInstance;

  /// Empty id clears the active subscription (backend falls back to the
  /// default direct-only configuration).
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ActiveSubscriptionResponse extends $pb.GeneratedMessage {
  factory ActiveSubscriptionResponse({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  ActiveSubscriptionResponse._();

  factory ActiveSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActiveSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveSubscriptionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveSubscriptionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveSubscriptionResponse copyWith(
          void Function(ActiveSubscriptionResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ActiveSubscriptionResponse))
          as ActiveSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveSubscriptionResponse create() => ActiveSubscriptionResponse._();
  @$core.override
  ActiveSubscriptionResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActiveSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveSubscriptionResponse>(create);
  static ActiveSubscriptionResponse? _defaultInstance;

  /// Empty when no subscription is active.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class IpInfoResponse extends $pb.GeneratedMessage {
  factory IpInfoResponse({
    $core.String? ip,
    $core.String? country,
    $core.String? countryCode,
    $core.String? city,
    $core.String? isp,
    $core.String? org,
    $core.String? asName,
  }) {
    final result = create();
    if (ip != null) result.ip = ip;
    if (country != null) result.country = country;
    if (countryCode != null) result.countryCode = countryCode;
    if (city != null) result.city = city;
    if (isp != null) result.isp = isp;
    if (org != null) result.org = org;
    if (asName != null) result.asName = asName;
    return result;
  }

  IpInfoResponse._();

  factory IpInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IpInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IpInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ip')
    ..aOS(2, _omitFieldNames ? '' : 'country')
    ..aOS(3, _omitFieldNames ? '' : 'countryCode')
    ..aOS(4, _omitFieldNames ? '' : 'city')
    ..aOS(5, _omitFieldNames ? '' : 'isp')
    ..aOS(6, _omitFieldNames ? '' : 'org')
    ..aOS(7, _omitFieldNames ? '' : 'asName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IpInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IpInfoResponse copyWith(void Function(IpInfoResponse) updates) =>
      super.copyWith((message) => updates(message as IpInfoResponse))
          as IpInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IpInfoResponse create() => IpInfoResponse._();
  @$core.override
  IpInfoResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IpInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IpInfoResponse>(create);
  static IpInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ip => $_getSZ(0);
  @$pb.TagNumber(1)
  set ip($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIp() => $_has(0);
  @$pb.TagNumber(1)
  void clearIp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get country => $_getSZ(1);
  @$pb.TagNumber(2)
  set country($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCountry() => $_has(1);
  @$pb.TagNumber(2)
  void clearCountry() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get countryCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set countryCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCountryCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCountryCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get city => $_getSZ(3);
  @$pb.TagNumber(4)
  set city($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCity() => $_has(3);
  @$pb.TagNumber(4)
  void clearCity() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get isp => $_getSZ(4);
  @$pb.TagNumber(5)
  set isp($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsp() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get org => $_getSZ(5);
  @$pb.TagNumber(6)
  set org($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOrg() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrg() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get asName => $_getSZ(6);
  @$pb.TagNumber(7)
  set asName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAsName() => $_has(6);
  @$pb.TagNumber(7)
  void clearAsName() => $_clearField(7);
}

class SubscriptionEvent extends $pb.GeneratedMessage {
  factory SubscriptionEvent({
    SubscriptionEventType? type,
    SubscriptionView? subscription,
    $fixnum.Int64? occurredAtUnixMs,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (subscription != null) result.subscription = subscription;
    if (occurredAtUnixMs != null) result.occurredAtUnixMs = occurredAtUnixMs;
    return result;
  }

  SubscriptionEvent._();

  factory SubscriptionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'targetlib'),
      createEmptyInstance: create)
    ..aE<SubscriptionEventType>(1, _omitFieldNames ? '' : 'type',
        enumValues: SubscriptionEventType.values)
    ..aOM<SubscriptionView>(2, _omitFieldNames ? '' : 'subscription',
        subBuilder: SubscriptionView.create)
    ..aInt64(3, _omitFieldNames ? '' : 'occurredAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionEvent copyWith(void Function(SubscriptionEvent) updates) =>
      super.copyWith((message) => updates(message as SubscriptionEvent))
          as SubscriptionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionEvent create() => SubscriptionEvent._();
  @$core.override
  SubscriptionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscriptionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionEvent>(create);
  static SubscriptionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionEventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SubscriptionEventType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  SubscriptionView get subscription => $_getN(1);
  @$pb.TagNumber(2)
  set subscription(SubscriptionView value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscription() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscription() => $_clearField(2);
  @$pb.TagNumber(2)
  SubscriptionView ensureSubscription() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get occurredAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set occurredAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOccurredAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearOccurredAtUnixMs() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
