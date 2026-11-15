//
//  Generated code. Do not modify.
//  source: anki/ankidroid.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'generic.pb.dart' as $0;
import 'scheduler.pb.dart' as $7;

class DebugActiveDatabaseSequenceNumbersResponse extends $pb.GeneratedMessage {
  factory DebugActiveDatabaseSequenceNumbersResponse({
    $core.Iterable<$core.int>? sequenceNumbers,
  }) {
    final $result = create();
    if (sequenceNumbers != null) {
      $result.sequenceNumbers.addAll(sequenceNumbers);
    }
    return $result;
  }
  DebugActiveDatabaseSequenceNumbersResponse._() : super();
  factory DebugActiveDatabaseSequenceNumbersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DebugActiveDatabaseSequenceNumbersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DebugActiveDatabaseSequenceNumbersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'sequenceNumbers', $pb.PbFieldType.K3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DebugActiveDatabaseSequenceNumbersResponse clone() => DebugActiveDatabaseSequenceNumbersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DebugActiveDatabaseSequenceNumbersResponse copyWith(void Function(DebugActiveDatabaseSequenceNumbersResponse) updates) => super.copyWith((message) => updates(message as DebugActiveDatabaseSequenceNumbersResponse)) as DebugActiveDatabaseSequenceNumbersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DebugActiveDatabaseSequenceNumbersResponse create() => DebugActiveDatabaseSequenceNumbersResponse._();
  DebugActiveDatabaseSequenceNumbersResponse createEmptyInstance() => create();
  static $pb.PbList<DebugActiveDatabaseSequenceNumbersResponse> createRepeated() => $pb.PbList<DebugActiveDatabaseSequenceNumbersResponse>();
  @$core.pragma('dart2js:noInline')
  static DebugActiveDatabaseSequenceNumbersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DebugActiveDatabaseSequenceNumbersResponse>(create);
  static DebugActiveDatabaseSequenceNumbersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get sequenceNumbers => $_getList(0);
}

class SchedTimingTodayLegacyRequest extends $pb.GeneratedMessage {
  factory SchedTimingTodayLegacyRequest({
    $fixnum.Int64? createdSecs,
    $core.int? createdMinsWest,
    $fixnum.Int64? nowSecs,
    $core.int? nowMinsWest,
    $core.int? rolloverHour,
  }) {
    final $result = create();
    if (createdSecs != null) {
      $result.createdSecs = createdSecs;
    }
    if (createdMinsWest != null) {
      $result.createdMinsWest = createdMinsWest;
    }
    if (nowSecs != null) {
      $result.nowSecs = nowSecs;
    }
    if (nowMinsWest != null) {
      $result.nowMinsWest = nowMinsWest;
    }
    if (rolloverHour != null) {
      $result.rolloverHour = rolloverHour;
    }
    return $result;
  }
  SchedTimingTodayLegacyRequest._() : super();
  factory SchedTimingTodayLegacyRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SchedTimingTodayLegacyRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SchedTimingTodayLegacyRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'createdSecs')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'createdMinsWest', $pb.PbFieldType.OS3)
    ..aInt64(3, _omitFieldNames ? '' : 'nowSecs')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'nowMinsWest', $pb.PbFieldType.OS3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'rolloverHour', $pb.PbFieldType.OS3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SchedTimingTodayLegacyRequest clone() => SchedTimingTodayLegacyRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SchedTimingTodayLegacyRequest copyWith(void Function(SchedTimingTodayLegacyRequest) updates) => super.copyWith((message) => updates(message as SchedTimingTodayLegacyRequest)) as SchedTimingTodayLegacyRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchedTimingTodayLegacyRequest create() => SchedTimingTodayLegacyRequest._();
  SchedTimingTodayLegacyRequest createEmptyInstance() => create();
  static $pb.PbList<SchedTimingTodayLegacyRequest> createRepeated() => $pb.PbList<SchedTimingTodayLegacyRequest>();
  @$core.pragma('dart2js:noInline')
  static SchedTimingTodayLegacyRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SchedTimingTodayLegacyRequest>(create);
  static SchedTimingTodayLegacyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get createdSecs => $_getI64(0);
  @$pb.TagNumber(1)
  set createdSecs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCreatedSecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearCreatedSecs() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get createdMinsWest => $_getIZ(1);
  @$pb.TagNumber(2)
  set createdMinsWest($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCreatedMinsWest() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreatedMinsWest() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get nowSecs => $_getI64(2);
  @$pb.TagNumber(3)
  set nowSecs($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNowSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearNowSecs() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get nowMinsWest => $_getIZ(3);
  @$pb.TagNumber(4)
  set nowMinsWest($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNowMinsWest() => $_has(3);
  @$pb.TagNumber(4)
  void clearNowMinsWest() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get rolloverHour => $_getIZ(4);
  @$pb.TagNumber(5)
  set rolloverHour($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasRolloverHour() => $_has(4);
  @$pb.TagNumber(5)
  void clearRolloverHour() => clearField(5);
}

enum SqlValue_Data {
  stringValue,
  longValue,
  doubleValue,
  blobValue,
  notSet
}

/// We expect in Java: Null, String, Short, Int, Long, Float, Double, Boolean,
/// Blob (unused) We get: DbResult (Null, String, i64, f64, Vec<u8>), which
/// matches SQLite documentation
class SqlValue extends $pb.GeneratedMessage {
  factory SqlValue({
    $core.String? stringValue,
    $fixnum.Int64? longValue,
    $core.double? doubleValue,
    $core.List<$core.int>? blobValue,
  }) {
    final $result = create();
    if (stringValue != null) {
      $result.stringValue = stringValue;
    }
    if (longValue != null) {
      $result.longValue = longValue;
    }
    if (doubleValue != null) {
      $result.doubleValue = doubleValue;
    }
    if (blobValue != null) {
      $result.blobValue = blobValue;
    }
    return $result;
  }
  SqlValue._() : super();
  factory SqlValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SqlValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SqlValue_Data> _SqlValue_DataByTag = {
    1 : SqlValue_Data.stringValue,
    2 : SqlValue_Data.longValue,
    3 : SqlValue_Data.doubleValue,
    4 : SqlValue_Data.blobValue,
    0 : SqlValue_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SqlValue', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'stringValue', protoName: 'stringValue')
    ..aInt64(2, _omitFieldNames ? '' : 'longValue', protoName: 'longValue')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'doubleValue', $pb.PbFieldType.OD, protoName: 'doubleValue')
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'blobValue', $pb.PbFieldType.OY, protoName: 'blobValue')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SqlValue clone() => SqlValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SqlValue copyWith(void Function(SqlValue) updates) => super.copyWith((message) => updates(message as SqlValue)) as SqlValue;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SqlValue create() => SqlValue._();
  SqlValue createEmptyInstance() => create();
  static $pb.PbList<SqlValue> createRepeated() => $pb.PbList<SqlValue>();
  @$core.pragma('dart2js:noInline')
  static SqlValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SqlValue>(create);
  static SqlValue? _defaultInstance;

  SqlValue_Data whichData() => _SqlValue_DataByTag[$_whichOneof(0)]!;
  void clearData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get stringValue => $_getSZ(0);
  @$pb.TagNumber(1)
  set stringValue($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStringValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearStringValue() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get longValue => $_getI64(1);
  @$pb.TagNumber(2)
  set longValue($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLongValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearLongValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get doubleValue => $_getN(2);
  @$pb.TagNumber(3)
  set doubleValue($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDoubleValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoubleValue() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get blobValue => $_getN(3);
  @$pb.TagNumber(4)
  set blobValue($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBlobValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlobValue() => clearField(4);
}

class Row extends $pb.GeneratedMessage {
  factory Row({
    $core.Iterable<SqlValue>? fields,
  }) {
    final $result = create();
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    return $result;
  }
  Row._() : super();
  factory Row.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Row.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Row', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..pc<SqlValue>(1, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.PM, subBuilder: SqlValue.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Row clone() => Row()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Row copyWith(void Function(Row) updates) => super.copyWith((message) => updates(message as Row)) as Row;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Row create() => Row._();
  Row createEmptyInstance() => create();
  static $pb.PbList<Row> createRepeated() => $pb.PbList<Row>();
  @$core.pragma('dart2js:noInline')
  static Row getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Row>(create);
  static Row? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SqlValue> get fields => $_getList(0);
}

class DbResult extends $pb.GeneratedMessage {
  factory DbResult({
    $core.Iterable<Row>? rows,
  }) {
    final $result = create();
    if (rows != null) {
      $result.rows.addAll(rows);
    }
    return $result;
  }
  DbResult._() : super();
  factory DbResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DbResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DbResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..pc<Row>(1, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.PM, subBuilder: Row.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DbResult clone() => DbResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DbResult copyWith(void Function(DbResult) updates) => super.copyWith((message) => updates(message as DbResult)) as DbResult;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DbResult create() => DbResult._();
  DbResult createEmptyInstance() => create();
  static $pb.PbList<DbResult> createRepeated() => $pb.PbList<DbResult>();
  @$core.pragma('dart2js:noInline')
  static DbResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DbResult>(create);
  static DbResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Row> get rows => $_getList(0);
}

class DbResponse extends $pb.GeneratedMessage {
  factory DbResponse({
    DbResult? result,
    $core.int? sequenceNumber,
    $core.int? rowCount,
    $fixnum.Int64? startIndex,
  }) {
    final $result = create();
    if (result != null) {
      $result.result = result;
    }
    if (sequenceNumber != null) {
      $result.sequenceNumber = sequenceNumber;
    }
    if (rowCount != null) {
      $result.rowCount = rowCount;
    }
    if (startIndex != null) {
      $result.startIndex = startIndex;
    }
    return $result;
  }
  DbResponse._() : super();
  factory DbResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DbResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DbResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..aOM<DbResult>(1, _omitFieldNames ? '' : 'result', subBuilder: DbResult.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'sequenceNumber', $pb.PbFieldType.O3, protoName: 'sequenceNumber')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'rowCount', $pb.PbFieldType.O3, protoName: 'rowCount')
    ..aInt64(4, _omitFieldNames ? '' : 'startIndex', protoName: 'startIndex')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DbResponse clone() => DbResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DbResponse copyWith(void Function(DbResponse) updates) => super.copyWith((message) => updates(message as DbResponse)) as DbResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DbResponse create() => DbResponse._();
  DbResponse createEmptyInstance() => create();
  static $pb.PbList<DbResponse> createRepeated() => $pb.PbList<DbResponse>();
  @$core.pragma('dart2js:noInline')
  static DbResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DbResponse>(create);
  static DbResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DbResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(DbResult v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);
  @$pb.TagNumber(1)
  DbResult ensureResult() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get sequenceNumber => $_getIZ(1);
  @$pb.TagNumber(2)
  set sequenceNumber($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSequenceNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequenceNumber() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get rowCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set rowCount($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRowCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearRowCount() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startIndex => $_getI64(3);
  @$pb.TagNumber(4)
  set startIndex($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasStartIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartIndex() => clearField(4);
}

class GetNextResultPageRequest extends $pb.GeneratedMessage {
  factory GetNextResultPageRequest({
    $core.int? sequence,
    $fixnum.Int64? index,
  }) {
    final $result = create();
    if (sequence != null) {
      $result.sequence = sequence;
    }
    if (index != null) {
      $result.index = index;
    }
    return $result;
  }
  GetNextResultPageRequest._() : super();
  factory GetNextResultPageRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetNextResultPageRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetNextResultPageRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.O3)
    ..aInt64(2, _omitFieldNames ? '' : 'index')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetNextResultPageRequest clone() => GetNextResultPageRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetNextResultPageRequest copyWith(void Function(GetNextResultPageRequest) updates) => super.copyWith((message) => updates(message as GetNextResultPageRequest)) as GetNextResultPageRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetNextResultPageRequest create() => GetNextResultPageRequest._();
  GetNextResultPageRequest createEmptyInstance() => create();
  static $pb.PbList<GetNextResultPageRequest> createRepeated() => $pb.PbList<GetNextResultPageRequest>();
  @$core.pragma('dart2js:noInline')
  static GetNextResultPageRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetNextResultPageRequest>(create);
  static GetNextResultPageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get sequence => $_getIZ(0);
  @$pb.TagNumber(1)
  set sequence($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get index => $_getI64(1);
  @$pb.TagNumber(2)
  set index($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

class GetActiveSequenceNumbersResponse extends $pb.GeneratedMessage {
  factory GetActiveSequenceNumbersResponse({
    $core.Iterable<$core.int>? numbers,
  }) {
    final $result = create();
    if (numbers != null) {
      $result.numbers.addAll(numbers);
    }
    return $result;
  }
  GetActiveSequenceNumbersResponse._() : super();
  factory GetActiveSequenceNumbersResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetActiveSequenceNumbersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetActiveSequenceNumbersResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.ankidroid'), createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'numbers', $pb.PbFieldType.K3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetActiveSequenceNumbersResponse clone() => GetActiveSequenceNumbersResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetActiveSequenceNumbersResponse copyWith(void Function(GetActiveSequenceNumbersResponse) updates) => super.copyWith((message) => updates(message as GetActiveSequenceNumbersResponse)) as GetActiveSequenceNumbersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetActiveSequenceNumbersResponse create() => GetActiveSequenceNumbersResponse._();
  GetActiveSequenceNumbersResponse createEmptyInstance() => create();
  static $pb.PbList<GetActiveSequenceNumbersResponse> createRepeated() => $pb.PbList<GetActiveSequenceNumbersResponse>();
  @$core.pragma('dart2js:noInline')
  static GetActiveSequenceNumbersResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetActiveSequenceNumbersResponse>(create);
  static GetActiveSequenceNumbersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get numbers => $_getList(0);
}

class AnkidroidServiceApi {
  $pb.RpcClient _client;
  AnkidroidServiceApi(this._client);

  $async.Future<$0.Json> runDbCommand($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$0.Json>(ctx, 'AnkidroidService', 'RunDbCommand', request, $0.Json())
  ;
  $async.Future<DbResponse> runDbCommandProto($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<DbResponse>(ctx, 'AnkidroidService', 'RunDbCommandProto', request, DbResponse())
  ;
  $async.Future<$0.Int64> insertForId($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$0.Int64>(ctx, 'AnkidroidService', 'InsertForId', request, $0.Int64())
  ;
  $async.Future<$0.Int64> runDbCommandForRowCount($pb.ClientContext? ctx, $0.Json request) =>
    _client.invoke<$0.Int64>(ctx, 'AnkidroidService', 'RunDbCommandForRowCount', request, $0.Int64())
  ;
  $async.Future<$0.Empty> flushAllQueries($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<$0.Empty>(ctx, 'AnkidroidService', 'FlushAllQueries', request, $0.Empty())
  ;
  $async.Future<$0.Empty> flushQuery($pb.ClientContext? ctx, $0.Int32 request) =>
    _client.invoke<$0.Empty>(ctx, 'AnkidroidService', 'FlushQuery', request, $0.Empty())
  ;
  $async.Future<DbResponse> getNextResultPage($pb.ClientContext? ctx, GetNextResultPageRequest request) =>
    _client.invoke<DbResponse>(ctx, 'AnkidroidService', 'GetNextResultPage', request, DbResponse())
  ;
  $async.Future<$0.StringList> getColumnNamesFromQuery($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.StringList>(ctx, 'AnkidroidService', 'GetColumnNamesFromQuery', request, $0.StringList())
  ;
  $async.Future<GetActiveSequenceNumbersResponse> getActiveSequenceNumbers($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<GetActiveSequenceNumbersResponse>(ctx, 'AnkidroidService', 'GetActiveSequenceNumbers', request, GetActiveSequenceNumbersResponse())
  ;
}

class BackendAnkidroidServiceApi {
  $pb.RpcClient _client;
  BackendAnkidroidServiceApi(this._client);

  $async.Future<$7.SchedTimingTodayResponse> schedTimingTodayLegacy($pb.ClientContext? ctx, SchedTimingTodayLegacyRequest request) =>
    _client.invoke<$7.SchedTimingTodayResponse>(ctx, 'BackendAnkidroidService', 'SchedTimingTodayLegacy', request, $7.SchedTimingTodayResponse())
  ;
  $async.Future<$0.Int32> localMinutesWestLegacy($pb.ClientContext? ctx, $0.Int64 request) =>
    _client.invoke<$0.Int32>(ctx, 'BackendAnkidroidService', 'LocalMinutesWestLegacy', request, $0.Int32())
  ;
  $async.Future<$0.Empty> setPageSize($pb.ClientContext? ctx, $0.Int64 request) =>
    _client.invoke<$0.Empty>(ctx, 'BackendAnkidroidService', 'SetPageSize', request, $0.Empty())
  ;
  $async.Future<$0.Empty> debugProduceError($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<$0.Empty>(ctx, 'BackendAnkidroidService', 'DebugProduceError', request, $0.Empty())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
