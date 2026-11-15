//
//  Generated code. Do not modify.
//  source: anki/import_export.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'generic.pb.dart' as $0;
import 'import_export.pb.dart' as $20;
import 'import_export.pbjson.dart';

export 'import_export.pb.dart';

abstract class ImportExportServiceBase extends $pb.GeneratedService {
  $async.Future<$20.ImportResponse> importAnkiPackage($pb.ServerContext ctx, $20.ImportAnkiPackageRequest request);
  $async.Future<$20.ImportAnkiPackageOptions> getImportAnkiPackagePresets($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.UInt32> exportAnkiPackage($pb.ServerContext ctx, $20.ExportAnkiPackageRequest request);
  $async.Future<$20.CsvMetadata> getCsvMetadata($pb.ServerContext ctx, $20.CsvMetadataRequest request);
  $async.Future<$20.ImportResponse> importCsv($pb.ServerContext ctx, $20.ImportCsvRequest request);
  $async.Future<$0.UInt32> exportNoteCsv($pb.ServerContext ctx, $20.ExportNoteCsvRequest request);
  $async.Future<$0.UInt32> exportCardCsv($pb.ServerContext ctx, $20.ExportCardCsvRequest request);
  $async.Future<$20.ImportResponse> importJsonFile($pb.ServerContext ctx, $0.String request);
  $async.Future<$20.ImportResponse> importJsonString($pb.ServerContext ctx, $0.String request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ImportAnkiPackage': return $20.ImportAnkiPackageRequest();
      case 'GetImportAnkiPackagePresets': return $0.Empty();
      case 'ExportAnkiPackage': return $20.ExportAnkiPackageRequest();
      case 'GetCsvMetadata': return $20.CsvMetadataRequest();
      case 'ImportCsv': return $20.ImportCsvRequest();
      case 'ExportNoteCsv': return $20.ExportNoteCsvRequest();
      case 'ExportCardCsv': return $20.ExportCardCsvRequest();
      case 'ImportJsonFile': return $0.String();
      case 'ImportJsonString': return $0.String();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ImportAnkiPackage': return this.importAnkiPackage(ctx, request as $20.ImportAnkiPackageRequest);
      case 'GetImportAnkiPackagePresets': return this.getImportAnkiPackagePresets(ctx, request as $0.Empty);
      case 'ExportAnkiPackage': return this.exportAnkiPackage(ctx, request as $20.ExportAnkiPackageRequest);
      case 'GetCsvMetadata': return this.getCsvMetadata(ctx, request as $20.CsvMetadataRequest);
      case 'ImportCsv': return this.importCsv(ctx, request as $20.ImportCsvRequest);
      case 'ExportNoteCsv': return this.exportNoteCsv(ctx, request as $20.ExportNoteCsvRequest);
      case 'ExportCardCsv': return this.exportCardCsv(ctx, request as $20.ExportCardCsvRequest);
      case 'ImportJsonFile': return this.importJsonFile(ctx, request as $0.String);
      case 'ImportJsonString': return this.importJsonString(ctx, request as $0.String);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ImportExportServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => ImportExportServiceBase$messageJson;
}

abstract class BackendImportExportServiceBase extends $pb.GeneratedService {
  $async.Future<$0.Empty> importCollectionPackage($pb.ServerContext ctx, $20.ImportCollectionPackageRequest request);
  $async.Future<$0.Empty> exportCollectionPackage($pb.ServerContext ctx, $20.ExportCollectionPackageRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ImportCollectionPackage': return $20.ImportCollectionPackageRequest();
      case 'ExportCollectionPackage': return $20.ExportCollectionPackageRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ImportCollectionPackage': return this.importCollectionPackage(ctx, request as $20.ImportCollectionPackageRequest);
      case 'ExportCollectionPackage': return this.exportCollectionPackage(ctx, request as $20.ExportCollectionPackageRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendImportExportServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendImportExportServiceBase$messageJson;
}
