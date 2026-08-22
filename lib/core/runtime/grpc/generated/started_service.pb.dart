// This is a generated file - do not edit.
//
// Generated from started_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'started_service.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'started_service.pbenum.dart';

class ServiceStatus extends $pb.GeneratedMessage {
  factory ServiceStatus({
    ServiceStatus_Type? status,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  ServiceStatus._();

  factory ServiceStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServiceStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServiceStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aE<ServiceStatus_Type>(1, _omitFieldNames ? '' : 'status',
        enumValues: ServiceStatus_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage', protoName: 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServiceStatus copyWith(void Function(ServiceStatus) updates) =>
      super.copyWith((message) => updates(message as ServiceStatus))
          as ServiceStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServiceStatus create() => ServiceStatus._();
  @$core.override
  ServiceStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServiceStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServiceStatus>(create);
  static ServiceStatus? _defaultInstance;

  @$pb.TagNumber(1)
  ServiceStatus_Type get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ServiceStatus_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);
}

class Log_Message extends $pb.GeneratedMessage {
  factory Log_Message({
    LogLevel? level,
    $core.String? message,
  }) {
    final result = create();
    if (level != null) result.level = level;
    if (message != null) result.message = message;
    return result;
  }

  Log_Message._();

  factory Log_Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Log_Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Log.Message',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aE<LogLevel>(1, _omitFieldNames ? '' : 'level',
        enumValues: LogLevel.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log_Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log_Message copyWith(void Function(Log_Message) updates) =>
      super.copyWith((message) => updates(message as Log_Message))
          as Log_Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Log_Message create() => Log_Message._();
  @$core.override
  Log_Message createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Log_Message getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Log_Message>(create);
  static Log_Message? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get level => $_getN(0);
  @$pb.TagNumber(1)
  set level(LogLevel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class Log extends $pb.GeneratedMessage {
  factory Log({
    $core.Iterable<Log_Message>? messages,
    $core.bool? reset,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    if (reset != null) result.reset = reset;
    return result;
  }

  Log._();

  factory Log.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Log.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Log',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..pPM<Log_Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: Log_Message.create)
    ..aOB(2, _omitFieldNames ? '' : 'reset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Log copyWith(void Function(Log) updates) =>
      super.copyWith((message) => updates(message as Log)) as Log;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Log create() => Log._();
  @$core.override
  Log createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Log getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Log>(create);
  static Log? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Log_Message> get messages => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get reset => $_getBF(1);
  @$pb.TagNumber(2)
  set reset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearReset() => $_clearField(2);
}

class SubscribeStatusRequest extends $pb.GeneratedMessage {
  factory SubscribeStatusRequest({
    $fixnum.Int64? interval,
  }) {
    final result = create();
    if (interval != null) result.interval = interval;
    return result;
  }

  SubscribeStatusRequest._();

  factory SubscribeStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'interval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeStatusRequest copyWith(
          void Function(SubscribeStatusRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeStatusRequest))
          as SubscribeStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeStatusRequest create() => SubscribeStatusRequest._();
  @$core.override
  SubscribeStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeStatusRequest>(create);
  static SubscribeStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get interval => $_getI64(0);
  @$pb.TagNumber(1)
  set interval($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearInterval() => $_clearField(1);
}

class Status extends $pb.GeneratedMessage {
  factory Status({
    $fixnum.Int64? memory,
    $core.int? goroutines,
    $core.int? connectionsIn,
    $core.int? connectionsOut,
    $core.bool? trafficAvailable,
    $fixnum.Int64? uplink,
    $fixnum.Int64? downlink,
    $fixnum.Int64? uplinkTotal,
    $fixnum.Int64? downlinkTotal,
  }) {
    final result = create();
    if (memory != null) result.memory = memory;
    if (goroutines != null) result.goroutines = goroutines;
    if (connectionsIn != null) result.connectionsIn = connectionsIn;
    if (connectionsOut != null) result.connectionsOut = connectionsOut;
    if (trafficAvailable != null) result.trafficAvailable = trafficAvailable;
    if (uplink != null) result.uplink = uplink;
    if (downlink != null) result.downlink = downlink;
    if (uplinkTotal != null) result.uplinkTotal = uplinkTotal;
    if (downlinkTotal != null) result.downlinkTotal = downlinkTotal;
    return result;
  }

  Status._();

  factory Status.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Status.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Status',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'memory', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(2, _omitFieldNames ? '' : 'goroutines')
    ..aI(3, _omitFieldNames ? '' : 'connectionsIn', protoName: 'connectionsIn')
    ..aI(4, _omitFieldNames ? '' : 'connectionsOut',
        protoName: 'connectionsOut')
    ..aOB(5, _omitFieldNames ? '' : 'trafficAvailable',
        protoName: 'trafficAvailable')
    ..aInt64(6, _omitFieldNames ? '' : 'uplink')
    ..aInt64(7, _omitFieldNames ? '' : 'downlink')
    ..aInt64(8, _omitFieldNames ? '' : 'uplinkTotal', protoName: 'uplinkTotal')
    ..aInt64(9, _omitFieldNames ? '' : 'downlinkTotal',
        protoName: 'downlinkTotal')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Status copyWith(void Function(Status) updates) =>
      super.copyWith((message) => updates(message as Status)) as Status;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Status create() => Status._();
  @$core.override
  Status createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Status getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Status>(create);
  static Status? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get memory => $_getI64(0);
  @$pb.TagNumber(1)
  set memory($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemory() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemory() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get goroutines => $_getIZ(1);
  @$pb.TagNumber(2)
  set goroutines($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGoroutines() => $_has(1);
  @$pb.TagNumber(2)
  void clearGoroutines() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get connectionsIn => $_getIZ(2);
  @$pb.TagNumber(3)
  set connectionsIn($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConnectionsIn() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnectionsIn() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get connectionsOut => $_getIZ(3);
  @$pb.TagNumber(4)
  set connectionsOut($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConnectionsOut() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectionsOut() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get trafficAvailable => $_getBF(4);
  @$pb.TagNumber(5)
  set trafficAvailable($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTrafficAvailable() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrafficAvailable() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get uplink => $_getI64(5);
  @$pb.TagNumber(6)
  set uplink($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUplink() => $_has(5);
  @$pb.TagNumber(6)
  void clearUplink() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get downlink => $_getI64(6);
  @$pb.TagNumber(7)
  set downlink($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDownlink() => $_has(6);
  @$pb.TagNumber(7)
  void clearDownlink() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get uplinkTotal => $_getI64(7);
  @$pb.TagNumber(8)
  set uplinkTotal($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUplinkTotal() => $_has(7);
  @$pb.TagNumber(8)
  void clearUplinkTotal() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get downlinkTotal => $_getI64(8);
  @$pb.TagNumber(9)
  set downlinkTotal($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDownlinkTotal() => $_has(8);
  @$pb.TagNumber(9)
  void clearDownlinkTotal() => $_clearField(9);
}

class Groups extends $pb.GeneratedMessage {
  factory Groups({
    $core.Iterable<Group>? group,
  }) {
    final result = create();
    if (group != null) result.group.addAll(group);
    return result;
  }

  Groups._();

  factory Groups.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Groups.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Groups',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..pPM<Group>(1, _omitFieldNames ? '' : 'group', subBuilder: Group.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Groups clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Groups copyWith(void Function(Groups) updates) =>
      super.copyWith((message) => updates(message as Groups)) as Groups;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Groups create() => Groups._();
  @$core.override
  Groups createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Groups getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Groups>(create);
  static Groups? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Group> get group => $_getList(0);
}

class Group extends $pb.GeneratedMessage {
  factory Group({
    $core.String? tag,
    $core.String? type,
    $core.bool? selectable,
    $core.String? selected,
    $core.bool? isExpand,
    $core.Iterable<GroupItem>? items,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    if (type != null) result.type = type;
    if (selectable != null) result.selectable = selectable;
    if (selected != null) result.selected = selected;
    if (isExpand != null) result.isExpand = isExpand;
    if (items != null) result.items.addAll(items);
    return result;
  }

  Group._();

  factory Group.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Group.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Group',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOB(3, _omitFieldNames ? '' : 'selectable')
    ..aOS(4, _omitFieldNames ? '' : 'selected')
    ..aOB(5, _omitFieldNames ? '' : 'isExpand', protoName: 'isExpand')
    ..pPM<GroupItem>(6, _omitFieldNames ? '' : 'items',
        subBuilder: GroupItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Group copyWith(void Function(Group) updates) =>
      super.copyWith((message) => updates(message as Group)) as Group;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Group create() => Group._();
  @$core.override
  Group createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Group getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Group>(create);
  static Group? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get selectable => $_getBF(2);
  @$pb.TagNumber(3)
  set selectable($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSelectable() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelectable() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get selected => $_getSZ(3);
  @$pb.TagNumber(4)
  set selected($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelected() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelected() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isExpand => $_getBF(4);
  @$pb.TagNumber(5)
  set isExpand($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsExpand() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsExpand() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<GroupItem> get items => $_getList(5);
}

class GroupItem extends $pb.GeneratedMessage {
  factory GroupItem({
    $core.String? tag,
    $core.String? type,
    $fixnum.Int64? urlTestTime,
    $core.int? urlTestDelay,
    $core.int? consecutiveFailures,
    $core.String? lastError,
    $fixnum.Int64? lastSuccessTime,
  }) {
    final result = create();
    if (tag != null) result.tag = tag;
    if (type != null) result.type = type;
    if (urlTestTime != null) result.urlTestTime = urlTestTime;
    if (urlTestDelay != null) result.urlTestDelay = urlTestDelay;
    if (consecutiveFailures != null)
      result.consecutiveFailures = consecutiveFailures;
    if (lastError != null) result.lastError = lastError;
    if (lastSuccessTime != null) result.lastSuccessTime = lastSuccessTime;
    return result;
  }

  GroupItem._();

  factory GroupItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GroupItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tag')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aInt64(3, _omitFieldNames ? '' : 'urlTestTime', protoName: 'urlTestTime')
    ..aI(4, _omitFieldNames ? '' : 'urlTestDelay', protoName: 'urlTestDelay')
    ..aI(5, _omitFieldNames ? '' : 'consecutiveFailures',
        protoName: 'consecutiveFailures', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'lastError', protoName: 'lastError')
    ..aInt64(7, _omitFieldNames ? '' : 'lastSuccessTime',
        protoName: 'lastSuccessTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupItem copyWith(void Function(GroupItem) updates) =>
      super.copyWith((message) => updates(message as GroupItem)) as GroupItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupItem create() => GroupItem._();
  @$core.override
  GroupItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GroupItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupItem>(create);
  static GroupItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tag => $_getSZ(0);
  @$pb.TagNumber(1)
  set tag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get urlTestTime => $_getI64(2);
  @$pb.TagNumber(3)
  set urlTestTime($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrlTestTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrlTestTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get urlTestDelay => $_getIZ(3);
  @$pb.TagNumber(4)
  set urlTestDelay($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUrlTestDelay() => $_has(3);
  @$pb.TagNumber(4)
  void clearUrlTestDelay() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get consecutiveFailures => $_getIZ(4);
  @$pb.TagNumber(5)
  set consecutiveFailures($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConsecutiveFailures() => $_has(4);
  @$pb.TagNumber(5)
  void clearConsecutiveFailures() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastError => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastError($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastError() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastError() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastSuccessTime => $_getI64(6);
  @$pb.TagNumber(7)
  set lastSuccessTime($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastSuccessTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastSuccessTime() => $_clearField(7);
}

class URLTestRequest extends $pb.GeneratedMessage {
  factory URLTestRequest({
    $core.String? outboundTag,
  }) {
    final result = create();
    if (outboundTag != null) result.outboundTag = outboundTag;
    return result;
  }

  URLTestRequest._();

  factory URLTestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory URLTestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'URLTestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outboundTag', protoName: 'outboundTag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  URLTestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  URLTestRequest copyWith(void Function(URLTestRequest) updates) =>
      super.copyWith((message) => updates(message as URLTestRequest))
          as URLTestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static URLTestRequest create() => URLTestRequest._();
  @$core.override
  URLTestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static URLTestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<URLTestRequest>(create);
  static URLTestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outboundTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set outboundTag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOutboundTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutboundTag() => $_clearField(1);
}

class SelectOutboundRequest extends $pb.GeneratedMessage {
  factory SelectOutboundRequest({
    $core.String? groupTag,
    $core.String? outboundTag,
  }) {
    final result = create();
    if (groupTag != null) result.groupTag = groupTag;
    if (outboundTag != null) result.outboundTag = outboundTag;
    return result;
  }

  SelectOutboundRequest._();

  factory SelectOutboundRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SelectOutboundRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SelectOutboundRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupTag', protoName: 'groupTag')
    ..aOS(2, _omitFieldNames ? '' : 'outboundTag', protoName: 'outboundTag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SelectOutboundRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SelectOutboundRequest copyWith(
          void Function(SelectOutboundRequest) updates) =>
      super.copyWith((message) => updates(message as SelectOutboundRequest))
          as SelectOutboundRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SelectOutboundRequest create() => SelectOutboundRequest._();
  @$core.override
  SelectOutboundRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SelectOutboundRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SelectOutboundRequest>(create);
  static SelectOutboundRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupTag => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupTag($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupTag() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get outboundTag => $_getSZ(1);
  @$pb.TagNumber(2)
  set outboundTag($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutboundTag() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutboundTag() => $_clearField(2);
}

class SubscribeConnectionsRequest extends $pb.GeneratedMessage {
  factory SubscribeConnectionsRequest({
    $fixnum.Int64? interval,
  }) {
    final result = create();
    if (interval != null) result.interval = interval;
    return result;
  }

  SubscribeConnectionsRequest._();

  factory SubscribeConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribeConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeConnectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'interval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeConnectionsRequest copyWith(
          void Function(SubscribeConnectionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SubscribeConnectionsRequest))
          as SubscribeConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribeConnectionsRequest create() =>
      SubscribeConnectionsRequest._();
  @$core.override
  SubscribeConnectionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribeConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribeConnectionsRequest>(create);
  static SubscribeConnectionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get interval => $_getI64(0);
  @$pb.TagNumber(1)
  set interval($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInterval() => $_has(0);
  @$pb.TagNumber(1)
  void clearInterval() => $_clearField(1);
}

class ConnectionEvent extends $pb.GeneratedMessage {
  factory ConnectionEvent({
    ConnectionEventType? type,
    $core.String? id,
    Connection? connection,
    $fixnum.Int64? uplinkDelta,
    $fixnum.Int64? downlinkDelta,
    $fixnum.Int64? closedAt,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (id != null) result.id = id;
    if (connection != null) result.connection = connection;
    if (uplinkDelta != null) result.uplinkDelta = uplinkDelta;
    if (downlinkDelta != null) result.downlinkDelta = downlinkDelta;
    if (closedAt != null) result.closedAt = closedAt;
    return result;
  }

  ConnectionEvent._();

  factory ConnectionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aE<ConnectionEventType>(1, _omitFieldNames ? '' : 'type',
        enumValues: ConnectionEventType.values)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOM<Connection>(3, _omitFieldNames ? '' : 'connection',
        subBuilder: Connection.create)
    ..aInt64(4, _omitFieldNames ? '' : 'uplinkDelta', protoName: 'uplinkDelta')
    ..aInt64(5, _omitFieldNames ? '' : 'downlinkDelta',
        protoName: 'downlinkDelta')
    ..aInt64(6, _omitFieldNames ? '' : 'closedAt', protoName: 'closedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionEvent copyWith(void Function(ConnectionEvent) updates) =>
      super.copyWith((message) => updates(message as ConnectionEvent))
          as ConnectionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionEvent create() => ConnectionEvent._();
  @$core.override
  ConnectionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionEvent>(create);
  static ConnectionEvent? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionEventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(ConnectionEventType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  Connection get connection => $_getN(2);
  @$pb.TagNumber(3)
  set connection(Connection value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasConnection() => $_has(2);
  @$pb.TagNumber(3)
  void clearConnection() => $_clearField(3);
  @$pb.TagNumber(3)
  Connection ensureConnection() => $_ensure(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get uplinkDelta => $_getI64(3);
  @$pb.TagNumber(4)
  set uplinkDelta($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUplinkDelta() => $_has(3);
  @$pb.TagNumber(4)
  void clearUplinkDelta() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get downlinkDelta => $_getI64(4);
  @$pb.TagNumber(5)
  set downlinkDelta($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDownlinkDelta() => $_has(4);
  @$pb.TagNumber(5)
  void clearDownlinkDelta() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get closedAt => $_getI64(5);
  @$pb.TagNumber(6)
  set closedAt($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClosedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearClosedAt() => $_clearField(6);
}

class ConnectionEvents extends $pb.GeneratedMessage {
  factory ConnectionEvents({
    $core.Iterable<ConnectionEvent>? events,
    $core.bool? reset,
  }) {
    final result = create();
    if (events != null) result.events.addAll(events);
    if (reset != null) result.reset = reset;
    return result;
  }

  ConnectionEvents._();

  factory ConnectionEvents.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConnectionEvents.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionEvents',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..pPM<ConnectionEvent>(1, _omitFieldNames ? '' : 'events',
        subBuilder: ConnectionEvent.create)
    ..aOB(2, _omitFieldNames ? '' : 'reset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionEvents clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionEvents copyWith(void Function(ConnectionEvents) updates) =>
      super.copyWith((message) => updates(message as ConnectionEvents))
          as ConnectionEvents;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionEvents create() => ConnectionEvents._();
  @$core.override
  ConnectionEvents createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConnectionEvents getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionEvents>(create);
  static ConnectionEvents? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ConnectionEvent> get events => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get reset => $_getBF(1);
  @$pb.TagNumber(2)
  set reset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearReset() => $_clearField(2);
}

class Connection extends $pb.GeneratedMessage {
  factory Connection({
    $core.String? id,
    $core.String? inbound,
    $core.String? inboundType,
    $core.int? ipVersion,
    $core.String? network,
    $core.String? source,
    $core.String? destination,
    $core.String? domain,
    $core.String? protocol,
    $core.String? user,
    $core.String? fromOutbound,
    $fixnum.Int64? createdAt,
    $fixnum.Int64? closedAt,
    $fixnum.Int64? uplink,
    $fixnum.Int64? downlink,
    $fixnum.Int64? uplinkTotal,
    $fixnum.Int64? downlinkTotal,
    $core.String? rule,
    $core.String? outbound,
    $core.String? outboundType,
    $core.Iterable<$core.String>? chainList,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (inbound != null) result.inbound = inbound;
    if (inboundType != null) result.inboundType = inboundType;
    if (ipVersion != null) result.ipVersion = ipVersion;
    if (network != null) result.network = network;
    if (source != null) result.source = source;
    if (destination != null) result.destination = destination;
    if (domain != null) result.domain = domain;
    if (protocol != null) result.protocol = protocol;
    if (user != null) result.user = user;
    if (fromOutbound != null) result.fromOutbound = fromOutbound;
    if (createdAt != null) result.createdAt = createdAt;
    if (closedAt != null) result.closedAt = closedAt;
    if (uplink != null) result.uplink = uplink;
    if (downlink != null) result.downlink = downlink;
    if (uplinkTotal != null) result.uplinkTotal = uplinkTotal;
    if (downlinkTotal != null) result.downlinkTotal = downlinkTotal;
    if (rule != null) result.rule = rule;
    if (outbound != null) result.outbound = outbound;
    if (outboundType != null) result.outboundType = outboundType;
    if (chainList != null) result.chainList.addAll(chainList);
    return result;
  }

  Connection._();

  factory Connection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Connection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Connection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'inbound')
    ..aOS(3, _omitFieldNames ? '' : 'inboundType', protoName: 'inboundType')
    ..aI(4, _omitFieldNames ? '' : 'ipVersion', protoName: 'ipVersion')
    ..aOS(5, _omitFieldNames ? '' : 'network')
    ..aOS(6, _omitFieldNames ? '' : 'source')
    ..aOS(7, _omitFieldNames ? '' : 'destination')
    ..aOS(8, _omitFieldNames ? '' : 'domain')
    ..aOS(9, _omitFieldNames ? '' : 'protocol')
    ..aOS(10, _omitFieldNames ? '' : 'user')
    ..aOS(11, _omitFieldNames ? '' : 'fromOutbound', protoName: 'fromOutbound')
    ..aInt64(12, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aInt64(13, _omitFieldNames ? '' : 'closedAt', protoName: 'closedAt')
    ..aInt64(14, _omitFieldNames ? '' : 'uplink')
    ..aInt64(15, _omitFieldNames ? '' : 'downlink')
    ..aInt64(16, _omitFieldNames ? '' : 'uplinkTotal', protoName: 'uplinkTotal')
    ..aInt64(17, _omitFieldNames ? '' : 'downlinkTotal',
        protoName: 'downlinkTotal')
    ..aOS(18, _omitFieldNames ? '' : 'rule')
    ..aOS(19, _omitFieldNames ? '' : 'outbound')
    ..aOS(20, _omitFieldNames ? '' : 'outboundType', protoName: 'outboundType')
    ..pPS(21, _omitFieldNames ? '' : 'chainList', protoName: 'chainList')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection copyWith(void Function(Connection) updates) =>
      super.copyWith((message) => updates(message as Connection)) as Connection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Connection create() => Connection._();
  @$core.override
  Connection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Connection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Connection>(create);
  static Connection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get inbound => $_getSZ(1);
  @$pb.TagNumber(2)
  set inbound($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInbound() => $_has(1);
  @$pb.TagNumber(2)
  void clearInbound() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get inboundType => $_getSZ(2);
  @$pb.TagNumber(3)
  set inboundType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInboundType() => $_has(2);
  @$pb.TagNumber(3)
  void clearInboundType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get ipVersion => $_getIZ(3);
  @$pb.TagNumber(4)
  set ipVersion($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIpVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearIpVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get network => $_getSZ(4);
  @$pb.TagNumber(5)
  set network($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNetwork() => $_has(4);
  @$pb.TagNumber(5)
  void clearNetwork() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get source => $_getSZ(5);
  @$pb.TagNumber(6)
  set source($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSource() => $_has(5);
  @$pb.TagNumber(6)
  void clearSource() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get destination => $_getSZ(6);
  @$pb.TagNumber(7)
  set destination($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDestination() => $_has(6);
  @$pb.TagNumber(7)
  void clearDestination() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get domain => $_getSZ(7);
  @$pb.TagNumber(8)
  set domain($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDomain() => $_has(7);
  @$pb.TagNumber(8)
  void clearDomain() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get protocol => $_getSZ(8);
  @$pb.TagNumber(9)
  set protocol($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProtocol() => $_has(8);
  @$pb.TagNumber(9)
  void clearProtocol() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get user => $_getSZ(9);
  @$pb.TagNumber(10)
  set user($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUser() => $_has(9);
  @$pb.TagNumber(10)
  void clearUser() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get fromOutbound => $_getSZ(10);
  @$pb.TagNumber(11)
  set fromOutbound($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasFromOutbound() => $_has(10);
  @$pb.TagNumber(11)
  void clearFromOutbound() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get createdAt => $_getI64(11);
  @$pb.TagNumber(12)
  set createdAt($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCreatedAt() => $_has(11);
  @$pb.TagNumber(12)
  void clearCreatedAt() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get closedAt => $_getI64(12);
  @$pb.TagNumber(13)
  set closedAt($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasClosedAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearClosedAt() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get uplink => $_getI64(13);
  @$pb.TagNumber(14)
  set uplink($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasUplink() => $_has(13);
  @$pb.TagNumber(14)
  void clearUplink() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get downlink => $_getI64(14);
  @$pb.TagNumber(15)
  set downlink($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasDownlink() => $_has(14);
  @$pb.TagNumber(15)
  void clearDownlink() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get uplinkTotal => $_getI64(15);
  @$pb.TagNumber(16)
  set uplinkTotal($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasUplinkTotal() => $_has(15);
  @$pb.TagNumber(16)
  void clearUplinkTotal() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get downlinkTotal => $_getI64(16);
  @$pb.TagNumber(17)
  set downlinkTotal($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDownlinkTotal() => $_has(16);
  @$pb.TagNumber(17)
  void clearDownlinkTotal() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get rule => $_getSZ(17);
  @$pb.TagNumber(18)
  set rule($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasRule() => $_has(17);
  @$pb.TagNumber(18)
  void clearRule() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get outbound => $_getSZ(18);
  @$pb.TagNumber(19)
  set outbound($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasOutbound() => $_has(18);
  @$pb.TagNumber(19)
  void clearOutbound() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get outboundType => $_getSZ(19);
  @$pb.TagNumber(20)
  set outboundType($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasOutboundType() => $_has(19);
  @$pb.TagNumber(20)
  void clearOutboundType() => $_clearField(20);

  @$pb.TagNumber(21)
  $pb.PbList<$core.String> get chainList => $_getList(20);
}

class CloseConnectionRequest extends $pb.GeneratedMessage {
  factory CloseConnectionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  CloseConnectionRequest._();

  factory CloseConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'daemon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionRequest copyWith(
          void Function(CloseConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as CloseConnectionRequest))
          as CloseConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseConnectionRequest create() => CloseConnectionRequest._();
  @$core.override
  CloseConnectionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseConnectionRequest>(create);
  static CloseConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
