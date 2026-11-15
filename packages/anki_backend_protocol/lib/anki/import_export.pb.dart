//
//  Generated code. Do not modify.
//  source: anki/import_export.proto
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

import 'cards.pb.dart' as $3;
import 'collection.pb.dart' as $2;
import 'generic.pb.dart' as $0;
import 'import_export.pbenum.dart';
import 'notes.pb.dart' as $13;

export 'import_export.pbenum.dart';

class ImportCollectionPackageRequest extends $pb.GeneratedMessage {
  factory ImportCollectionPackageRequest({
    $core.String? colPath,
    $core.String? backupPath,
    $core.String? mediaFolder,
    $core.String? mediaDb,
  }) {
    final $result = create();
    if (colPath != null) {
      $result.colPath = colPath;
    }
    if (backupPath != null) {
      $result.backupPath = backupPath;
    }
    if (mediaFolder != null) {
      $result.mediaFolder = mediaFolder;
    }
    if (mediaDb != null) {
      $result.mediaDb = mediaDb;
    }
    return $result;
  }
  ImportCollectionPackageRequest._() : super();
  factory ImportCollectionPackageRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportCollectionPackageRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportCollectionPackageRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'colPath')
    ..aOS(2, _omitFieldNames ? '' : 'backupPath')
    ..aOS(3, _omitFieldNames ? '' : 'mediaFolder')
    ..aOS(4, _omitFieldNames ? '' : 'mediaDb')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportCollectionPackageRequest clone() => ImportCollectionPackageRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportCollectionPackageRequest copyWith(void Function(ImportCollectionPackageRequest) updates) => super.copyWith((message) => updates(message as ImportCollectionPackageRequest)) as ImportCollectionPackageRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportCollectionPackageRequest create() => ImportCollectionPackageRequest._();
  ImportCollectionPackageRequest createEmptyInstance() => create();
  static $pb.PbList<ImportCollectionPackageRequest> createRepeated() => $pb.PbList<ImportCollectionPackageRequest>();
  @$core.pragma('dart2js:noInline')
  static ImportCollectionPackageRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportCollectionPackageRequest>(create);
  static ImportCollectionPackageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get colPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set colPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasColPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearColPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get backupPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set backupPath($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBackupPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackupPath() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get mediaFolder => $_getSZ(2);
  @$pb.TagNumber(3)
  set mediaFolder($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMediaFolder() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaFolder() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get mediaDb => $_getSZ(3);
  @$pb.TagNumber(4)
  set mediaDb($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMediaDb() => $_has(3);
  @$pb.TagNumber(4)
  void clearMediaDb() => clearField(4);
}

class ExportCollectionPackageRequest extends $pb.GeneratedMessage {
  factory ExportCollectionPackageRequest({
    $core.String? outPath,
    $core.bool? includeMedia,
    $core.bool? legacy,
  }) {
    final $result = create();
    if (outPath != null) {
      $result.outPath = outPath;
    }
    if (includeMedia != null) {
      $result.includeMedia = includeMedia;
    }
    if (legacy != null) {
      $result.legacy = legacy;
    }
    return $result;
  }
  ExportCollectionPackageRequest._() : super();
  factory ExportCollectionPackageRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportCollectionPackageRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportCollectionPackageRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outPath')
    ..aOB(2, _omitFieldNames ? '' : 'includeMedia')
    ..aOB(3, _omitFieldNames ? '' : 'legacy')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportCollectionPackageRequest clone() => ExportCollectionPackageRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportCollectionPackageRequest copyWith(void Function(ExportCollectionPackageRequest) updates) => super.copyWith((message) => updates(message as ExportCollectionPackageRequest)) as ExportCollectionPackageRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportCollectionPackageRequest create() => ExportCollectionPackageRequest._();
  ExportCollectionPackageRequest createEmptyInstance() => create();
  static $pb.PbList<ExportCollectionPackageRequest> createRepeated() => $pb.PbList<ExportCollectionPackageRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportCollectionPackageRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportCollectionPackageRequest>(create);
  static ExportCollectionPackageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set outPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOutPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get includeMedia => $_getBF(1);
  @$pb.TagNumber(2)
  set includeMedia($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIncludeMedia() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeMedia() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get legacy => $_getBF(2);
  @$pb.TagNumber(3)
  set legacy($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLegacy() => $_has(2);
  @$pb.TagNumber(3)
  void clearLegacy() => clearField(3);
}

class ImportAnkiPackageOptions extends $pb.GeneratedMessage {
  factory ImportAnkiPackageOptions({
    $core.bool? mergeNotetypes,
    ImportAnkiPackageUpdateCondition? updateNotes,
    ImportAnkiPackageUpdateCondition? updateNotetypes,
    $core.bool? withScheduling,
    $core.bool? withDeckConfigs,
  }) {
    final $result = create();
    if (mergeNotetypes != null) {
      $result.mergeNotetypes = mergeNotetypes;
    }
    if (updateNotes != null) {
      $result.updateNotes = updateNotes;
    }
    if (updateNotetypes != null) {
      $result.updateNotetypes = updateNotetypes;
    }
    if (withScheduling != null) {
      $result.withScheduling = withScheduling;
    }
    if (withDeckConfigs != null) {
      $result.withDeckConfigs = withDeckConfigs;
    }
    return $result;
  }
  ImportAnkiPackageOptions._() : super();
  factory ImportAnkiPackageOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportAnkiPackageOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportAnkiPackageOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'mergeNotetypes')
    ..e<ImportAnkiPackageUpdateCondition>(2, _omitFieldNames ? '' : 'updateNotes', $pb.PbFieldType.OE, defaultOrMaker: ImportAnkiPackageUpdateCondition.IMPORT_ANKI_PACKAGE_UPDATE_CONDITION_IF_NEWER, valueOf: ImportAnkiPackageUpdateCondition.valueOf, enumValues: ImportAnkiPackageUpdateCondition.values)
    ..e<ImportAnkiPackageUpdateCondition>(3, _omitFieldNames ? '' : 'updateNotetypes', $pb.PbFieldType.OE, defaultOrMaker: ImportAnkiPackageUpdateCondition.IMPORT_ANKI_PACKAGE_UPDATE_CONDITION_IF_NEWER, valueOf: ImportAnkiPackageUpdateCondition.valueOf, enumValues: ImportAnkiPackageUpdateCondition.values)
    ..aOB(4, _omitFieldNames ? '' : 'withScheduling')
    ..aOB(5, _omitFieldNames ? '' : 'withDeckConfigs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportAnkiPackageOptions clone() => ImportAnkiPackageOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportAnkiPackageOptions copyWith(void Function(ImportAnkiPackageOptions) updates) => super.copyWith((message) => updates(message as ImportAnkiPackageOptions)) as ImportAnkiPackageOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportAnkiPackageOptions create() => ImportAnkiPackageOptions._();
  ImportAnkiPackageOptions createEmptyInstance() => create();
  static $pb.PbList<ImportAnkiPackageOptions> createRepeated() => $pb.PbList<ImportAnkiPackageOptions>();
  @$core.pragma('dart2js:noInline')
  static ImportAnkiPackageOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportAnkiPackageOptions>(create);
  static ImportAnkiPackageOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get mergeNotetypes => $_getBF(0);
  @$pb.TagNumber(1)
  set mergeNotetypes($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMergeNotetypes() => $_has(0);
  @$pb.TagNumber(1)
  void clearMergeNotetypes() => clearField(1);

  @$pb.TagNumber(2)
  ImportAnkiPackageUpdateCondition get updateNotes => $_getN(1);
  @$pb.TagNumber(2)
  set updateNotes(ImportAnkiPackageUpdateCondition v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasUpdateNotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateNotes() => clearField(2);

  @$pb.TagNumber(3)
  ImportAnkiPackageUpdateCondition get updateNotetypes => $_getN(2);
  @$pb.TagNumber(3)
  set updateNotetypes(ImportAnkiPackageUpdateCondition v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasUpdateNotetypes() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateNotetypes() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get withScheduling => $_getBF(3);
  @$pb.TagNumber(4)
  set withScheduling($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasWithScheduling() => $_has(3);
  @$pb.TagNumber(4)
  void clearWithScheduling() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get withDeckConfigs => $_getBF(4);
  @$pb.TagNumber(5)
  set withDeckConfigs($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasWithDeckConfigs() => $_has(4);
  @$pb.TagNumber(5)
  void clearWithDeckConfigs() => clearField(5);
}

class ImportAnkiPackageRequest extends $pb.GeneratedMessage {
  factory ImportAnkiPackageRequest({
    $core.String? packagePath,
    ImportAnkiPackageOptions? options,
  }) {
    final $result = create();
    if (packagePath != null) {
      $result.packagePath = packagePath;
    }
    if (options != null) {
      $result.options = options;
    }
    return $result;
  }
  ImportAnkiPackageRequest._() : super();
  factory ImportAnkiPackageRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportAnkiPackageRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportAnkiPackageRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'packagePath')
    ..aOM<ImportAnkiPackageOptions>(2, _omitFieldNames ? '' : 'options', subBuilder: ImportAnkiPackageOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportAnkiPackageRequest clone() => ImportAnkiPackageRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportAnkiPackageRequest copyWith(void Function(ImportAnkiPackageRequest) updates) => super.copyWith((message) => updates(message as ImportAnkiPackageRequest)) as ImportAnkiPackageRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportAnkiPackageRequest create() => ImportAnkiPackageRequest._();
  ImportAnkiPackageRequest createEmptyInstance() => create();
  static $pb.PbList<ImportAnkiPackageRequest> createRepeated() => $pb.PbList<ImportAnkiPackageRequest>();
  @$core.pragma('dart2js:noInline')
  static ImportAnkiPackageRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportAnkiPackageRequest>(create);
  static ImportAnkiPackageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get packagePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set packagePath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPackagePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackagePath() => clearField(1);

  @$pb.TagNumber(2)
  ImportAnkiPackageOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options(ImportAnkiPackageOptions v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => clearField(2);
  @$pb.TagNumber(2)
  ImportAnkiPackageOptions ensureOptions() => $_ensure(1);
}

class ImportResponse_Note extends $pb.GeneratedMessage {
  factory ImportResponse_Note({
    $13.NoteId? id,
    $core.Iterable<$core.String>? fields,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    return $result;
  }
  ImportResponse_Note._() : super();
  factory ImportResponse_Note.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportResponse_Note.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportResponse.Note', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOM<$13.NoteId>(1, _omitFieldNames ? '' : 'id', subBuilder: $13.NoteId.create)
    ..pPS(2, _omitFieldNames ? '' : 'fields')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportResponse_Note clone() => ImportResponse_Note()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportResponse_Note copyWith(void Function(ImportResponse_Note) updates) => super.copyWith((message) => updates(message as ImportResponse_Note)) as ImportResponse_Note;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportResponse_Note create() => ImportResponse_Note._();
  ImportResponse_Note createEmptyInstance() => create();
  static $pb.PbList<ImportResponse_Note> createRepeated() => $pb.PbList<ImportResponse_Note>();
  @$core.pragma('dart2js:noInline')
  static ImportResponse_Note getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportResponse_Note>(create);
  static ImportResponse_Note? _defaultInstance;

  @$pb.TagNumber(1)
  $13.NoteId get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($13.NoteId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
  @$pb.TagNumber(1)
  $13.NoteId ensureId() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get fields => $_getList(1);
}

class ImportResponse_Log extends $pb.GeneratedMessage {
  factory ImportResponse_Log({
    $core.Iterable<ImportResponse_Note>? new_1,
    $core.Iterable<ImportResponse_Note>? updated,
    $core.Iterable<ImportResponse_Note>? duplicate,
    $core.Iterable<ImportResponse_Note>? conflicting,
    $core.Iterable<ImportResponse_Note>? firstFieldMatch,
    $core.Iterable<ImportResponse_Note>? missingNotetype,
    $core.Iterable<ImportResponse_Note>? missingDeck,
    $core.Iterable<ImportResponse_Note>? emptyFirstField,
    CsvMetadata_DupeResolution? dupeResolution,
    $core.int? foundNotes,
  }) {
    final $result = create();
    if (new_1 != null) {
      $result.new_1.addAll(new_1);
    }
    if (updated != null) {
      $result.updated.addAll(updated);
    }
    if (duplicate != null) {
      $result.duplicate.addAll(duplicate);
    }
    if (conflicting != null) {
      $result.conflicting.addAll(conflicting);
    }
    if (firstFieldMatch != null) {
      $result.firstFieldMatch.addAll(firstFieldMatch);
    }
    if (missingNotetype != null) {
      $result.missingNotetype.addAll(missingNotetype);
    }
    if (missingDeck != null) {
      $result.missingDeck.addAll(missingDeck);
    }
    if (emptyFirstField != null) {
      $result.emptyFirstField.addAll(emptyFirstField);
    }
    if (dupeResolution != null) {
      $result.dupeResolution = dupeResolution;
    }
    if (foundNotes != null) {
      $result.foundNotes = foundNotes;
    }
    return $result;
  }
  ImportResponse_Log._() : super();
  factory ImportResponse_Log.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportResponse_Log.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportResponse.Log', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..pc<ImportResponse_Note>(1, _omitFieldNames ? '' : 'new', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(2, _omitFieldNames ? '' : 'updated', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(3, _omitFieldNames ? '' : 'duplicate', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(4, _omitFieldNames ? '' : 'conflicting', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(5, _omitFieldNames ? '' : 'firstFieldMatch', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(6, _omitFieldNames ? '' : 'missingNotetype', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(7, _omitFieldNames ? '' : 'missingDeck', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..pc<ImportResponse_Note>(8, _omitFieldNames ? '' : 'emptyFirstField', $pb.PbFieldType.PM, subBuilder: ImportResponse_Note.create)
    ..e<CsvMetadata_DupeResolution>(9, _omitFieldNames ? '' : 'dupeResolution', $pb.PbFieldType.OE, defaultOrMaker: CsvMetadata_DupeResolution.UPDATE, valueOf: CsvMetadata_DupeResolution.valueOf, enumValues: CsvMetadata_DupeResolution.values)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'foundNotes', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportResponse_Log clone() => ImportResponse_Log()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportResponse_Log copyWith(void Function(ImportResponse_Log) updates) => super.copyWith((message) => updates(message as ImportResponse_Log)) as ImportResponse_Log;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportResponse_Log create() => ImportResponse_Log._();
  ImportResponse_Log createEmptyInstance() => create();
  static $pb.PbList<ImportResponse_Log> createRepeated() => $pb.PbList<ImportResponse_Log>();
  @$core.pragma('dart2js:noInline')
  static ImportResponse_Log getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportResponse_Log>(create);
  static ImportResponse_Log? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ImportResponse_Note> get new_1 => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ImportResponse_Note> get updated => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<ImportResponse_Note> get duplicate => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<ImportResponse_Note> get conflicting => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<ImportResponse_Note> get firstFieldMatch => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<ImportResponse_Note> get missingNotetype => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<ImportResponse_Note> get missingDeck => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<ImportResponse_Note> get emptyFirstField => $_getList(7);

  @$pb.TagNumber(9)
  CsvMetadata_DupeResolution get dupeResolution => $_getN(8);
  @$pb.TagNumber(9)
  set dupeResolution(CsvMetadata_DupeResolution v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasDupeResolution() => $_has(8);
  @$pb.TagNumber(9)
  void clearDupeResolution() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get foundNotes => $_getIZ(9);
  @$pb.TagNumber(10)
  set foundNotes($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasFoundNotes() => $_has(9);
  @$pb.TagNumber(10)
  void clearFoundNotes() => clearField(10);
}

class ImportResponse extends $pb.GeneratedMessage {
  factory ImportResponse({
    $2.OpChanges? changes,
    ImportResponse_Log? log,
  }) {
    final $result = create();
    if (changes != null) {
      $result.changes = changes;
    }
    if (log != null) {
      $result.log = log;
    }
    return $result;
  }
  ImportResponse._() : super();
  factory ImportResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOM<$2.OpChanges>(1, _omitFieldNames ? '' : 'changes', subBuilder: $2.OpChanges.create)
    ..aOM<ImportResponse_Log>(2, _omitFieldNames ? '' : 'log', subBuilder: ImportResponse_Log.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportResponse clone() => ImportResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportResponse copyWith(void Function(ImportResponse) updates) => super.copyWith((message) => updates(message as ImportResponse)) as ImportResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportResponse create() => ImportResponse._();
  ImportResponse createEmptyInstance() => create();
  static $pb.PbList<ImportResponse> createRepeated() => $pb.PbList<ImportResponse>();
  @$core.pragma('dart2js:noInline')
  static ImportResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportResponse>(create);
  static ImportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $2.OpChanges get changes => $_getN(0);
  @$pb.TagNumber(1)
  set changes($2.OpChanges v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasChanges() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanges() => clearField(1);
  @$pb.TagNumber(1)
  $2.OpChanges ensureChanges() => $_ensure(0);

  @$pb.TagNumber(2)
  ImportResponse_Log get log => $_getN(1);
  @$pb.TagNumber(2)
  set log(ImportResponse_Log v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLog() => $_has(1);
  @$pb.TagNumber(2)
  void clearLog() => clearField(2);
  @$pb.TagNumber(2)
  ImportResponse_Log ensureLog() => $_ensure(1);
}

class ExportAnkiPackageRequest extends $pb.GeneratedMessage {
  factory ExportAnkiPackageRequest({
    $core.String? outPath,
    ExportAnkiPackageOptions? options,
    ExportLimit? limit,
  }) {
    final $result = create();
    if (outPath != null) {
      $result.outPath = outPath;
    }
    if (options != null) {
      $result.options = options;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ExportAnkiPackageRequest._() : super();
  factory ExportAnkiPackageRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportAnkiPackageRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportAnkiPackageRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outPath')
    ..aOM<ExportAnkiPackageOptions>(2, _omitFieldNames ? '' : 'options', subBuilder: ExportAnkiPackageOptions.create)
    ..aOM<ExportLimit>(3, _omitFieldNames ? '' : 'limit', subBuilder: ExportLimit.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportAnkiPackageRequest clone() => ExportAnkiPackageRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportAnkiPackageRequest copyWith(void Function(ExportAnkiPackageRequest) updates) => super.copyWith((message) => updates(message as ExportAnkiPackageRequest)) as ExportAnkiPackageRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportAnkiPackageRequest create() => ExportAnkiPackageRequest._();
  ExportAnkiPackageRequest createEmptyInstance() => create();
  static $pb.PbList<ExportAnkiPackageRequest> createRepeated() => $pb.PbList<ExportAnkiPackageRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportAnkiPackageRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportAnkiPackageRequest>(create);
  static ExportAnkiPackageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set outPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOutPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutPath() => clearField(1);

  @$pb.TagNumber(2)
  ExportAnkiPackageOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options(ExportAnkiPackageOptions v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => clearField(2);
  @$pb.TagNumber(2)
  ExportAnkiPackageOptions ensureOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  ExportLimit get limit => $_getN(2);
  @$pb.TagNumber(3)
  set limit(ExportLimit v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);
  @$pb.TagNumber(3)
  ExportLimit ensureLimit() => $_ensure(2);
}

class ExportAnkiPackageOptions extends $pb.GeneratedMessage {
  factory ExportAnkiPackageOptions({
    $core.bool? withScheduling,
    $core.bool? withDeckConfigs,
    $core.bool? withMedia,
    $core.bool? legacy,
  }) {
    final $result = create();
    if (withScheduling != null) {
      $result.withScheduling = withScheduling;
    }
    if (withDeckConfigs != null) {
      $result.withDeckConfigs = withDeckConfigs;
    }
    if (withMedia != null) {
      $result.withMedia = withMedia;
    }
    if (legacy != null) {
      $result.legacy = legacy;
    }
    return $result;
  }
  ExportAnkiPackageOptions._() : super();
  factory ExportAnkiPackageOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportAnkiPackageOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportAnkiPackageOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'withScheduling')
    ..aOB(2, _omitFieldNames ? '' : 'withDeckConfigs')
    ..aOB(3, _omitFieldNames ? '' : 'withMedia')
    ..aOB(4, _omitFieldNames ? '' : 'legacy')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportAnkiPackageOptions clone() => ExportAnkiPackageOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportAnkiPackageOptions copyWith(void Function(ExportAnkiPackageOptions) updates) => super.copyWith((message) => updates(message as ExportAnkiPackageOptions)) as ExportAnkiPackageOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportAnkiPackageOptions create() => ExportAnkiPackageOptions._();
  ExportAnkiPackageOptions createEmptyInstance() => create();
  static $pb.PbList<ExportAnkiPackageOptions> createRepeated() => $pb.PbList<ExportAnkiPackageOptions>();
  @$core.pragma('dart2js:noInline')
  static ExportAnkiPackageOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportAnkiPackageOptions>(create);
  static ExportAnkiPackageOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get withScheduling => $_getBF(0);
  @$pb.TagNumber(1)
  set withScheduling($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWithScheduling() => $_has(0);
  @$pb.TagNumber(1)
  void clearWithScheduling() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get withDeckConfigs => $_getBF(1);
  @$pb.TagNumber(2)
  set withDeckConfigs($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWithDeckConfigs() => $_has(1);
  @$pb.TagNumber(2)
  void clearWithDeckConfigs() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get withMedia => $_getBF(2);
  @$pb.TagNumber(3)
  set withMedia($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWithMedia() => $_has(2);
  @$pb.TagNumber(3)
  void clearWithMedia() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get legacy => $_getBF(3);
  @$pb.TagNumber(4)
  set legacy($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLegacy() => $_has(3);
  @$pb.TagNumber(4)
  void clearLegacy() => clearField(4);
}

class PackageMetadata extends $pb.GeneratedMessage {
  factory PackageMetadata({
    PackageMetadata_Version? version,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  PackageMetadata._() : super();
  factory PackageMetadata.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PackageMetadata.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PackageMetadata', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..e<PackageMetadata_Version>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OE, defaultOrMaker: PackageMetadata_Version.VERSION_UNKNOWN, valueOf: PackageMetadata_Version.valueOf, enumValues: PackageMetadata_Version.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PackageMetadata clone() => PackageMetadata()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PackageMetadata copyWith(void Function(PackageMetadata) updates) => super.copyWith((message) => updates(message as PackageMetadata)) as PackageMetadata;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PackageMetadata create() => PackageMetadata._();
  PackageMetadata createEmptyInstance() => create();
  static $pb.PbList<PackageMetadata> createRepeated() => $pb.PbList<PackageMetadata>();
  @$core.pragma('dart2js:noInline')
  static PackageMetadata getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PackageMetadata>(create);
  static PackageMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  PackageMetadata_Version get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(PackageMetadata_Version v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);
}

class MediaEntries_MediaEntry extends $pb.GeneratedMessage {
  factory MediaEntries_MediaEntry({
    $core.String? name,
    $core.int? size,
    $core.List<$core.int>? sha1,
    $core.int? legacyZipFilename,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (size != null) {
      $result.size = size;
    }
    if (sha1 != null) {
      $result.sha1 = sha1;
    }
    if (legacyZipFilename != null) {
      $result.legacyZipFilename = legacyZipFilename;
    }
    return $result;
  }
  MediaEntries_MediaEntry._() : super();
  factory MediaEntries_MediaEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MediaEntries_MediaEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MediaEntries.MediaEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'sha1', $pb.PbFieldType.OY)
    ..a<$core.int>(255, _omitFieldNames ? '' : 'legacyZipFilename', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MediaEntries_MediaEntry clone() => MediaEntries_MediaEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MediaEntries_MediaEntry copyWith(void Function(MediaEntries_MediaEntry) updates) => super.copyWith((message) => updates(message as MediaEntries_MediaEntry)) as MediaEntries_MediaEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MediaEntries_MediaEntry create() => MediaEntries_MediaEntry._();
  MediaEntries_MediaEntry createEmptyInstance() => create();
  static $pb.PbList<MediaEntries_MediaEntry> createRepeated() => $pb.PbList<MediaEntries_MediaEntry>();
  @$core.pragma('dart2js:noInline')
  static MediaEntries_MediaEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaEntries_MediaEntry>(create);
  static MediaEntries_MediaEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get size => $_getIZ(1);
  @$pb.TagNumber(2)
  set size($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get sha1 => $_getN(2);
  @$pb.TagNumber(3)
  set sha1($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSha1() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha1() => clearField(3);

  /// / Legacy media maps may include gaps in the media list, so the original
  /// / file index is recorded when importing from a HashMap. This field is not
  /// / set when exporting.
  @$pb.TagNumber(255)
  $core.int get legacyZipFilename => $_getIZ(3);
  @$pb.TagNumber(255)
  set legacyZipFilename($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(255)
  $core.bool hasLegacyZipFilename() => $_has(3);
  @$pb.TagNumber(255)
  void clearLegacyZipFilename() => clearField(255);
}

class MediaEntries extends $pb.GeneratedMessage {
  factory MediaEntries({
    $core.Iterable<MediaEntries_MediaEntry>? entries,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    return $result;
  }
  MediaEntries._() : super();
  factory MediaEntries.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MediaEntries.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MediaEntries', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..pc<MediaEntries_MediaEntry>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: MediaEntries_MediaEntry.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MediaEntries clone() => MediaEntries()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MediaEntries copyWith(void Function(MediaEntries) updates) => super.copyWith((message) => updates(message as MediaEntries)) as MediaEntries;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MediaEntries create() => MediaEntries._();
  MediaEntries createEmptyInstance() => create();
  static $pb.PbList<MediaEntries> createRepeated() => $pb.PbList<MediaEntries>();
  @$core.pragma('dart2js:noInline')
  static MediaEntries getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MediaEntries>(create);
  static MediaEntries? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<MediaEntries_MediaEntry> get entries => $_getList(0);
}

class ImportCsvRequest extends $pb.GeneratedMessage {
  factory ImportCsvRequest({
    $core.String? path,
    CsvMetadata? metadata,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  ImportCsvRequest._() : super();
  factory ImportCsvRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImportCsvRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImportCsvRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOM<CsvMetadata>(2, _omitFieldNames ? '' : 'metadata', subBuilder: CsvMetadata.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImportCsvRequest clone() => ImportCsvRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImportCsvRequest copyWith(void Function(ImportCsvRequest) updates) => super.copyWith((message) => updates(message as ImportCsvRequest)) as ImportCsvRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportCsvRequest create() => ImportCsvRequest._();
  ImportCsvRequest createEmptyInstance() => create();
  static $pb.PbList<ImportCsvRequest> createRepeated() => $pb.PbList<ImportCsvRequest>();
  @$core.pragma('dart2js:noInline')
  static ImportCsvRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImportCsvRequest>(create);
  static ImportCsvRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  CsvMetadata get metadata => $_getN(1);
  @$pb.TagNumber(2)
  set metadata(CsvMetadata v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasMetadata() => $_has(1);
  @$pb.TagNumber(2)
  void clearMetadata() => clearField(2);
  @$pb.TagNumber(2)
  CsvMetadata ensureMetadata() => $_ensure(1);
}

class CsvMetadataRequest extends $pb.GeneratedMessage {
  factory CsvMetadataRequest({
    $core.String? path,
    CsvMetadata_Delimiter? delimiter,
    $fixnum.Int64? notetypeId,
    $fixnum.Int64? deckId,
    $core.bool? isHtml,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (delimiter != null) {
      $result.delimiter = delimiter;
    }
    if (notetypeId != null) {
      $result.notetypeId = notetypeId;
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (isHtml != null) {
      $result.isHtml = isHtml;
    }
    return $result;
  }
  CsvMetadataRequest._() : super();
  factory CsvMetadataRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CsvMetadataRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CsvMetadataRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..e<CsvMetadata_Delimiter>(2, _omitFieldNames ? '' : 'delimiter', $pb.PbFieldType.OE, defaultOrMaker: CsvMetadata_Delimiter.TAB, valueOf: CsvMetadata_Delimiter.valueOf, enumValues: CsvMetadata_Delimiter.values)
    ..aInt64(3, _omitFieldNames ? '' : 'notetypeId')
    ..aInt64(4, _omitFieldNames ? '' : 'deckId')
    ..aOB(5, _omitFieldNames ? '' : 'isHtml')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CsvMetadataRequest clone() => CsvMetadataRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CsvMetadataRequest copyWith(void Function(CsvMetadataRequest) updates) => super.copyWith((message) => updates(message as CsvMetadataRequest)) as CsvMetadataRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CsvMetadataRequest create() => CsvMetadataRequest._();
  CsvMetadataRequest createEmptyInstance() => create();
  static $pb.PbList<CsvMetadataRequest> createRepeated() => $pb.PbList<CsvMetadataRequest>();
  @$core.pragma('dart2js:noInline')
  static CsvMetadataRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CsvMetadataRequest>(create);
  static CsvMetadataRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  CsvMetadata_Delimiter get delimiter => $_getN(1);
  @$pb.TagNumber(2)
  set delimiter(CsvMetadata_Delimiter v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDelimiter() => $_has(1);
  @$pb.TagNumber(2)
  void clearDelimiter() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get notetypeId => $_getI64(2);
  @$pb.TagNumber(3)
  set notetypeId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNotetypeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotetypeId() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deckId => $_getI64(3);
  @$pb.TagNumber(4)
  set deckId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeckId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeckId() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isHtml => $_getBF(4);
  @$pb.TagNumber(5)
  set isHtml($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsHtml() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsHtml() => clearField(5);
}

class CsvMetadata_MappedNotetype extends $pb.GeneratedMessage {
  factory CsvMetadata_MappedNotetype({
    $fixnum.Int64? id,
    $core.Iterable<$core.int>? fieldColumns,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (fieldColumns != null) {
      $result.fieldColumns.addAll(fieldColumns);
    }
    return $result;
  }
  CsvMetadata_MappedNotetype._() : super();
  factory CsvMetadata_MappedNotetype.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CsvMetadata_MappedNotetype.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CsvMetadata.MappedNotetype', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..p<$core.int>(2, _omitFieldNames ? '' : 'fieldColumns', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CsvMetadata_MappedNotetype clone() => CsvMetadata_MappedNotetype()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CsvMetadata_MappedNotetype copyWith(void Function(CsvMetadata_MappedNotetype) updates) => super.copyWith((message) => updates(message as CsvMetadata_MappedNotetype)) as CsvMetadata_MappedNotetype;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CsvMetadata_MappedNotetype create() => CsvMetadata_MappedNotetype._();
  CsvMetadata_MappedNotetype createEmptyInstance() => create();
  static $pb.PbList<CsvMetadata_MappedNotetype> createRepeated() => $pb.PbList<CsvMetadata_MappedNotetype>();
  @$core.pragma('dart2js:noInline')
  static CsvMetadata_MappedNotetype getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CsvMetadata_MappedNotetype>(create);
  static CsvMetadata_MappedNotetype? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Source column indices for note fields. One-based. 0 means n/a.
  @$pb.TagNumber(2)
  $core.List<$core.int> get fieldColumns => $_getList(1);
}

enum CsvMetadata_Deck {
  deckId,
  deckColumn,
  deckName,
  notSet
}

enum CsvMetadata_Notetype {
  globalNotetype,
  notetypeColumn,
  notSet
}

/// Column indices are 1-based to make working with them in TS easier, where
/// unset numerical fields default to 0.
class CsvMetadata extends $pb.GeneratedMessage {
  factory CsvMetadata({
    CsvMetadata_Delimiter? delimiter,
    $core.bool? isHtml,
    $core.Iterable<$core.String>? globalTags,
    $core.Iterable<$core.String>? updatedTags,
    $core.Iterable<$core.String>? columnLabels,
    $fixnum.Int64? deckId,
    $core.int? deckColumn,
    CsvMetadata_MappedNotetype? globalNotetype,
    $core.int? notetypeColumn,
    $core.int? tagsColumn,
    $core.bool? forceDelimiter,
    $core.bool? forceIsHtml,
    $core.Iterable<$0.StringList>? preview,
    $core.int? guidColumn,
    CsvMetadata_DupeResolution? dupeResolution,
    CsvMetadata_MatchScope? matchScope,
    $core.String? deckName,
  }) {
    final $result = create();
    if (delimiter != null) {
      $result.delimiter = delimiter;
    }
    if (isHtml != null) {
      $result.isHtml = isHtml;
    }
    if (globalTags != null) {
      $result.globalTags.addAll(globalTags);
    }
    if (updatedTags != null) {
      $result.updatedTags.addAll(updatedTags);
    }
    if (columnLabels != null) {
      $result.columnLabels.addAll(columnLabels);
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (deckColumn != null) {
      $result.deckColumn = deckColumn;
    }
    if (globalNotetype != null) {
      $result.globalNotetype = globalNotetype;
    }
    if (notetypeColumn != null) {
      $result.notetypeColumn = notetypeColumn;
    }
    if (tagsColumn != null) {
      $result.tagsColumn = tagsColumn;
    }
    if (forceDelimiter != null) {
      $result.forceDelimiter = forceDelimiter;
    }
    if (forceIsHtml != null) {
      $result.forceIsHtml = forceIsHtml;
    }
    if (preview != null) {
      $result.preview.addAll(preview);
    }
    if (guidColumn != null) {
      $result.guidColumn = guidColumn;
    }
    if (dupeResolution != null) {
      $result.dupeResolution = dupeResolution;
    }
    if (matchScope != null) {
      $result.matchScope = matchScope;
    }
    if (deckName != null) {
      $result.deckName = deckName;
    }
    return $result;
  }
  CsvMetadata._() : super();
  factory CsvMetadata.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CsvMetadata.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, CsvMetadata_Deck> _CsvMetadata_DeckByTag = {
    6 : CsvMetadata_Deck.deckId,
    7 : CsvMetadata_Deck.deckColumn,
    17 : CsvMetadata_Deck.deckName,
    0 : CsvMetadata_Deck.notSet
  };
  static const $core.Map<$core.int, CsvMetadata_Notetype> _CsvMetadata_NotetypeByTag = {
    8 : CsvMetadata_Notetype.globalNotetype,
    9 : CsvMetadata_Notetype.notetypeColumn,
    0 : CsvMetadata_Notetype.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CsvMetadata', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..oo(0, [6, 7, 17])
    ..oo(1, [8, 9])
    ..e<CsvMetadata_Delimiter>(1, _omitFieldNames ? '' : 'delimiter', $pb.PbFieldType.OE, defaultOrMaker: CsvMetadata_Delimiter.TAB, valueOf: CsvMetadata_Delimiter.valueOf, enumValues: CsvMetadata_Delimiter.values)
    ..aOB(2, _omitFieldNames ? '' : 'isHtml')
    ..pPS(3, _omitFieldNames ? '' : 'globalTags')
    ..pPS(4, _omitFieldNames ? '' : 'updatedTags')
    ..pPS(5, _omitFieldNames ? '' : 'columnLabels')
    ..aInt64(6, _omitFieldNames ? '' : 'deckId')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'deckColumn', $pb.PbFieldType.OU3)
    ..aOM<CsvMetadata_MappedNotetype>(8, _omitFieldNames ? '' : 'globalNotetype', subBuilder: CsvMetadata_MappedNotetype.create)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'notetypeColumn', $pb.PbFieldType.OU3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'tagsColumn', $pb.PbFieldType.OU3)
    ..aOB(11, _omitFieldNames ? '' : 'forceDelimiter')
    ..aOB(12, _omitFieldNames ? '' : 'forceIsHtml')
    ..pc<$0.StringList>(13, _omitFieldNames ? '' : 'preview', $pb.PbFieldType.PM, subBuilder: $0.StringList.create)
    ..a<$core.int>(14, _omitFieldNames ? '' : 'guidColumn', $pb.PbFieldType.OU3)
    ..e<CsvMetadata_DupeResolution>(15, _omitFieldNames ? '' : 'dupeResolution', $pb.PbFieldType.OE, defaultOrMaker: CsvMetadata_DupeResolution.UPDATE, valueOf: CsvMetadata_DupeResolution.valueOf, enumValues: CsvMetadata_DupeResolution.values)
    ..e<CsvMetadata_MatchScope>(16, _omitFieldNames ? '' : 'matchScope', $pb.PbFieldType.OE, defaultOrMaker: CsvMetadata_MatchScope.NOTETYPE, valueOf: CsvMetadata_MatchScope.valueOf, enumValues: CsvMetadata_MatchScope.values)
    ..aOS(17, _omitFieldNames ? '' : 'deckName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CsvMetadata clone() => CsvMetadata()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CsvMetadata copyWith(void Function(CsvMetadata) updates) => super.copyWith((message) => updates(message as CsvMetadata)) as CsvMetadata;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CsvMetadata create() => CsvMetadata._();
  CsvMetadata createEmptyInstance() => create();
  static $pb.PbList<CsvMetadata> createRepeated() => $pb.PbList<CsvMetadata>();
  @$core.pragma('dart2js:noInline')
  static CsvMetadata getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CsvMetadata>(create);
  static CsvMetadata? _defaultInstance;

  CsvMetadata_Deck whichDeck() => _CsvMetadata_DeckByTag[$_whichOneof(0)]!;
  void clearDeck() => clearField($_whichOneof(0));

  CsvMetadata_Notetype whichNotetype() => _CsvMetadata_NotetypeByTag[$_whichOneof(1)]!;
  void clearNotetype() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  CsvMetadata_Delimiter get delimiter => $_getN(0);
  @$pb.TagNumber(1)
  set delimiter(CsvMetadata_Delimiter v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDelimiter() => $_has(0);
  @$pb.TagNumber(1)
  void clearDelimiter() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isHtml => $_getBF(1);
  @$pb.TagNumber(2)
  set isHtml($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIsHtml() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsHtml() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get globalTags => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get updatedTags => $_getList(3);

  /// Column names as defined by the file or empty strings otherwise. Also used
  /// to determine the number of columns.
  @$pb.TagNumber(5)
  $core.List<$core.String> get columnLabels => $_getList(4);

  /// id of an existing deck
  @$pb.TagNumber(6)
  $fixnum.Int64 get deckId => $_getI64(5);
  @$pb.TagNumber(6)
  set deckId($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeckId() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeckId() => clearField(6);

  /// One-based. 0 means n/a.
  @$pb.TagNumber(7)
  $core.int get deckColumn => $_getIZ(6);
  @$pb.TagNumber(7)
  set deckColumn($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDeckColumn() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeckColumn() => clearField(7);

  /// One notetype for all rows with given column mapping.
  @$pb.TagNumber(8)
  CsvMetadata_MappedNotetype get globalNotetype => $_getN(7);
  @$pb.TagNumber(8)
  set globalNotetype(CsvMetadata_MappedNotetype v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasGlobalNotetype() => $_has(7);
  @$pb.TagNumber(8)
  void clearGlobalNotetype() => clearField(8);
  @$pb.TagNumber(8)
  CsvMetadata_MappedNotetype ensureGlobalNotetype() => $_ensure(7);

  /// Row-specific notetypes with automatic mapping by index.
  /// One-based. 0 means n/a.
  @$pb.TagNumber(9)
  $core.int get notetypeColumn => $_getIZ(8);
  @$pb.TagNumber(9)
  set notetypeColumn($core.int v) { $_setUnsignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasNotetypeColumn() => $_has(8);
  @$pb.TagNumber(9)
  void clearNotetypeColumn() => clearField(9);

  /// One-based. 0 means n/a.
  @$pb.TagNumber(10)
  $core.int get tagsColumn => $_getIZ(9);
  @$pb.TagNumber(10)
  set tagsColumn($core.int v) { $_setUnsignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasTagsColumn() => $_has(9);
  @$pb.TagNumber(10)
  void clearTagsColumn() => clearField(10);

  @$pb.TagNumber(11)
  $core.bool get forceDelimiter => $_getBF(10);
  @$pb.TagNumber(11)
  set forceDelimiter($core.bool v) { $_setBool(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasForceDelimiter() => $_has(10);
  @$pb.TagNumber(11)
  void clearForceDelimiter() => clearField(11);

  @$pb.TagNumber(12)
  $core.bool get forceIsHtml => $_getBF(11);
  @$pb.TagNumber(12)
  set forceIsHtml($core.bool v) { $_setBool(11, v); }
  @$pb.TagNumber(12)
  $core.bool hasForceIsHtml() => $_has(11);
  @$pb.TagNumber(12)
  void clearForceIsHtml() => clearField(12);

  @$pb.TagNumber(13)
  $core.List<$0.StringList> get preview => $_getList(12);

  @$pb.TagNumber(14)
  $core.int get guidColumn => $_getIZ(13);
  @$pb.TagNumber(14)
  set guidColumn($core.int v) { $_setUnsignedInt32(13, v); }
  @$pb.TagNumber(14)
  $core.bool hasGuidColumn() => $_has(13);
  @$pb.TagNumber(14)
  void clearGuidColumn() => clearField(14);

  @$pb.TagNumber(15)
  CsvMetadata_DupeResolution get dupeResolution => $_getN(14);
  @$pb.TagNumber(15)
  set dupeResolution(CsvMetadata_DupeResolution v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasDupeResolution() => $_has(14);
  @$pb.TagNumber(15)
  void clearDupeResolution() => clearField(15);

  @$pb.TagNumber(16)
  CsvMetadata_MatchScope get matchScope => $_getN(15);
  @$pb.TagNumber(16)
  set matchScope(CsvMetadata_MatchScope v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasMatchScope() => $_has(15);
  @$pb.TagNumber(16)
  void clearMatchScope() => clearField(16);

  /// name of new deck to be created
  @$pb.TagNumber(17)
  $core.String get deckName => $_getSZ(16);
  @$pb.TagNumber(17)
  set deckName($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(17)
  $core.bool hasDeckName() => $_has(16);
  @$pb.TagNumber(17)
  void clearDeckName() => clearField(17);
}

class ExportCardCsvRequest extends $pb.GeneratedMessage {
  factory ExportCardCsvRequest({
    $core.String? outPath,
    $core.bool? withHtml,
    ExportLimit? limit,
  }) {
    final $result = create();
    if (outPath != null) {
      $result.outPath = outPath;
    }
    if (withHtml != null) {
      $result.withHtml = withHtml;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ExportCardCsvRequest._() : super();
  factory ExportCardCsvRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportCardCsvRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportCardCsvRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outPath')
    ..aOB(2, _omitFieldNames ? '' : 'withHtml')
    ..aOM<ExportLimit>(3, _omitFieldNames ? '' : 'limit', subBuilder: ExportLimit.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportCardCsvRequest clone() => ExportCardCsvRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportCardCsvRequest copyWith(void Function(ExportCardCsvRequest) updates) => super.copyWith((message) => updates(message as ExportCardCsvRequest)) as ExportCardCsvRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportCardCsvRequest create() => ExportCardCsvRequest._();
  ExportCardCsvRequest createEmptyInstance() => create();
  static $pb.PbList<ExportCardCsvRequest> createRepeated() => $pb.PbList<ExportCardCsvRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportCardCsvRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportCardCsvRequest>(create);
  static ExportCardCsvRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set outPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOutPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get withHtml => $_getBF(1);
  @$pb.TagNumber(2)
  set withHtml($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWithHtml() => $_has(1);
  @$pb.TagNumber(2)
  void clearWithHtml() => clearField(2);

  @$pb.TagNumber(3)
  ExportLimit get limit => $_getN(2);
  @$pb.TagNumber(3)
  set limit(ExportLimit v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);
  @$pb.TagNumber(3)
  ExportLimit ensureLimit() => $_ensure(2);
}

class ExportNoteCsvRequest extends $pb.GeneratedMessage {
  factory ExportNoteCsvRequest({
    $core.String? outPath,
    $core.bool? withHtml,
    $core.bool? withTags,
    $core.bool? withDeck,
    $core.bool? withNotetype,
    $core.bool? withGuid,
    ExportLimit? limit,
  }) {
    final $result = create();
    if (outPath != null) {
      $result.outPath = outPath;
    }
    if (withHtml != null) {
      $result.withHtml = withHtml;
    }
    if (withTags != null) {
      $result.withTags = withTags;
    }
    if (withDeck != null) {
      $result.withDeck = withDeck;
    }
    if (withNotetype != null) {
      $result.withNotetype = withNotetype;
    }
    if (withGuid != null) {
      $result.withGuid = withGuid;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  ExportNoteCsvRequest._() : super();
  factory ExportNoteCsvRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportNoteCsvRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportNoteCsvRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outPath')
    ..aOB(2, _omitFieldNames ? '' : 'withHtml')
    ..aOB(3, _omitFieldNames ? '' : 'withTags')
    ..aOB(4, _omitFieldNames ? '' : 'withDeck')
    ..aOB(5, _omitFieldNames ? '' : 'withNotetype')
    ..aOB(6, _omitFieldNames ? '' : 'withGuid')
    ..aOM<ExportLimit>(7, _omitFieldNames ? '' : 'limit', subBuilder: ExportLimit.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportNoteCsvRequest clone() => ExportNoteCsvRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportNoteCsvRequest copyWith(void Function(ExportNoteCsvRequest) updates) => super.copyWith((message) => updates(message as ExportNoteCsvRequest)) as ExportNoteCsvRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportNoteCsvRequest create() => ExportNoteCsvRequest._();
  ExportNoteCsvRequest createEmptyInstance() => create();
  static $pb.PbList<ExportNoteCsvRequest> createRepeated() => $pb.PbList<ExportNoteCsvRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportNoteCsvRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportNoteCsvRequest>(create);
  static ExportNoteCsvRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set outPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOutPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get withHtml => $_getBF(1);
  @$pb.TagNumber(2)
  set withHtml($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWithHtml() => $_has(1);
  @$pb.TagNumber(2)
  void clearWithHtml() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get withTags => $_getBF(2);
  @$pb.TagNumber(3)
  set withTags($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWithTags() => $_has(2);
  @$pb.TagNumber(3)
  void clearWithTags() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get withDeck => $_getBF(3);
  @$pb.TagNumber(4)
  set withDeck($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasWithDeck() => $_has(3);
  @$pb.TagNumber(4)
  void clearWithDeck() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get withNotetype => $_getBF(4);
  @$pb.TagNumber(5)
  set withNotetype($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasWithNotetype() => $_has(4);
  @$pb.TagNumber(5)
  void clearWithNotetype() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get withGuid => $_getBF(5);
  @$pb.TagNumber(6)
  set withGuid($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasWithGuid() => $_has(5);
  @$pb.TagNumber(6)
  void clearWithGuid() => clearField(6);

  @$pb.TagNumber(7)
  ExportLimit get limit => $_getN(6);
  @$pb.TagNumber(7)
  set limit(ExportLimit v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearLimit() => clearField(7);
  @$pb.TagNumber(7)
  ExportLimit ensureLimit() => $_ensure(6);
}

enum ExportLimit_Limit {
  wholeCollection,
  deckId,
  noteIds,
  cardIds,
  notSet
}

class ExportLimit extends $pb.GeneratedMessage {
  factory ExportLimit({
    $0.Empty? wholeCollection,
    $fixnum.Int64? deckId,
    $13.NoteIds? noteIds,
    $3.CardIds? cardIds,
  }) {
    final $result = create();
    if (wholeCollection != null) {
      $result.wholeCollection = wholeCollection;
    }
    if (deckId != null) {
      $result.deckId = deckId;
    }
    if (noteIds != null) {
      $result.noteIds = noteIds;
    }
    if (cardIds != null) {
      $result.cardIds = cardIds;
    }
    return $result;
  }
  ExportLimit._() : super();
  factory ExportLimit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportLimit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ExportLimit_Limit> _ExportLimit_LimitByTag = {
    1 : ExportLimit_Limit.wholeCollection,
    2 : ExportLimit_Limit.deckId,
    3 : ExportLimit_Limit.noteIds,
    4 : ExportLimit_Limit.cardIds,
    0 : ExportLimit_Limit.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportLimit', package: const $pb.PackageName(_omitMessageNames ? '' : 'anki.import_export'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<$0.Empty>(1, _omitFieldNames ? '' : 'wholeCollection', subBuilder: $0.Empty.create)
    ..aInt64(2, _omitFieldNames ? '' : 'deckId')
    ..aOM<$13.NoteIds>(3, _omitFieldNames ? '' : 'noteIds', subBuilder: $13.NoteIds.create)
    ..aOM<$3.CardIds>(4, _omitFieldNames ? '' : 'cardIds', subBuilder: $3.CardIds.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportLimit clone() => ExportLimit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportLimit copyWith(void Function(ExportLimit) updates) => super.copyWith((message) => updates(message as ExportLimit)) as ExportLimit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportLimit create() => ExportLimit._();
  ExportLimit createEmptyInstance() => create();
  static $pb.PbList<ExportLimit> createRepeated() => $pb.PbList<ExportLimit>();
  @$core.pragma('dart2js:noInline')
  static ExportLimit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportLimit>(create);
  static ExportLimit? _defaultInstance;

  ExportLimit_Limit whichLimit() => _ExportLimit_LimitByTag[$_whichOneof(0)]!;
  void clearLimit() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Empty get wholeCollection => $_getN(0);
  @$pb.TagNumber(1)
  set wholeCollection($0.Empty v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasWholeCollection() => $_has(0);
  @$pb.TagNumber(1)
  void clearWholeCollection() => clearField(1);
  @$pb.TagNumber(1)
  $0.Empty ensureWholeCollection() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get deckId => $_getI64(1);
  @$pb.TagNumber(2)
  set deckId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeckId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeckId() => clearField(2);

  @$pb.TagNumber(3)
  $13.NoteIds get noteIds => $_getN(2);
  @$pb.TagNumber(3)
  set noteIds($13.NoteIds v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasNoteIds() => $_has(2);
  @$pb.TagNumber(3)
  void clearNoteIds() => clearField(3);
  @$pb.TagNumber(3)
  $13.NoteIds ensureNoteIds() => $_ensure(2);

  @$pb.TagNumber(4)
  $3.CardIds get cardIds => $_getN(3);
  @$pb.TagNumber(4)
  set cardIds($3.CardIds v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCardIds() => $_has(3);
  @$pb.TagNumber(4)
  void clearCardIds() => clearField(4);
  @$pb.TagNumber(4)
  $3.CardIds ensureCardIds() => $_ensure(3);
}

class ImportExportServiceApi {
  $pb.RpcClient _client;
  ImportExportServiceApi(this._client);

  $async.Future<ImportResponse> importAnkiPackage($pb.ClientContext? ctx, ImportAnkiPackageRequest request) =>
    _client.invoke<ImportResponse>(ctx, 'ImportExportService', 'ImportAnkiPackage', request, ImportResponse())
  ;
  $async.Future<ImportAnkiPackageOptions> getImportAnkiPackagePresets($pb.ClientContext? ctx, $0.Empty request) =>
    _client.invoke<ImportAnkiPackageOptions>(ctx, 'ImportExportService', 'GetImportAnkiPackagePresets', request, ImportAnkiPackageOptions())
  ;
  $async.Future<$0.UInt32> exportAnkiPackage($pb.ClientContext? ctx, ExportAnkiPackageRequest request) =>
    _client.invoke<$0.UInt32>(ctx, 'ImportExportService', 'ExportAnkiPackage', request, $0.UInt32())
  ;
  $async.Future<CsvMetadata> getCsvMetadata($pb.ClientContext? ctx, CsvMetadataRequest request) =>
    _client.invoke<CsvMetadata>(ctx, 'ImportExportService', 'GetCsvMetadata', request, CsvMetadata())
  ;
  $async.Future<ImportResponse> importCsv($pb.ClientContext? ctx, ImportCsvRequest request) =>
    _client.invoke<ImportResponse>(ctx, 'ImportExportService', 'ImportCsv', request, ImportResponse())
  ;
  $async.Future<$0.UInt32> exportNoteCsv($pb.ClientContext? ctx, ExportNoteCsvRequest request) =>
    _client.invoke<$0.UInt32>(ctx, 'ImportExportService', 'ExportNoteCsv', request, $0.UInt32())
  ;
  $async.Future<$0.UInt32> exportCardCsv($pb.ClientContext? ctx, ExportCardCsvRequest request) =>
    _client.invoke<$0.UInt32>(ctx, 'ImportExportService', 'ExportCardCsv', request, $0.UInt32())
  ;
  $async.Future<ImportResponse> importJsonFile($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<ImportResponse>(ctx, 'ImportExportService', 'ImportJsonFile', request, ImportResponse())
  ;
  $async.Future<ImportResponse> importJsonString($pb.ClientContext? ctx, $0.String request) =>
    _client.invoke<ImportResponse>(ctx, 'ImportExportService', 'ImportJsonString', request, ImportResponse())
  ;
}

class BackendImportExportServiceApi {
  $pb.RpcClient _client;
  BackendImportExportServiceApi(this._client);

  $async.Future<$0.Empty> importCollectionPackage($pb.ClientContext? ctx, ImportCollectionPackageRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'BackendImportExportService', 'ImportCollectionPackage', request, $0.Empty())
  ;
  $async.Future<$0.Empty> exportCollectionPackage($pb.ClientContext? ctx, ExportCollectionPackageRequest request) =>
    _client.invoke<$0.Empty>(ctx, 'BackendImportExportService', 'ExportCollectionPackage', request, $0.Empty())
  ;
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
