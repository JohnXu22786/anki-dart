//
//  Generated code. Do not modify.
//  source: anki/frontend.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'cards.pbjson.dart' as $3;
import 'generic.pbjson.dart' as $0;
import 'scheduler.pbjson.dart' as $7;
import 'search.pbjson.dart' as $15;

@$core.Deprecated('Use schedulingStatesWithContextDescriptor instead')
const SchedulingStatesWithContext$json = {
  '1': 'SchedulingStatesWithContext',
  '2': [
    {'1': 'states', '3': 1, '4': 1, '5': 11, '6': '.anki.scheduler.SchedulingStates', '10': 'states'},
    {'1': 'context', '3': 2, '4': 1, '5': 11, '6': '.anki.scheduler.SchedulingContext', '10': 'context'},
  ],
};

/// Descriptor for `SchedulingStatesWithContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schedulingStatesWithContextDescriptor = $convert.base64Decode(
    'ChtTY2hlZHVsaW5nU3RhdGVzV2l0aENvbnRleHQSOAoGc3RhdGVzGAEgASgLMiAuYW5raS5zY2'
    'hlZHVsZXIuU2NoZWR1bGluZ1N0YXRlc1IGc3RhdGVzEjsKB2NvbnRleHQYAiABKAsyIS5hbmtp'
    'LnNjaGVkdWxlci5TY2hlZHVsaW5nQ29udGV4dFIHY29udGV4dA==');

@$core.Deprecated('Use setSchedulingStatesRequestDescriptor instead')
const SetSchedulingStatesRequest$json = {
  '1': 'SetSchedulingStatesRequest',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'states', '3': 2, '4': 1, '5': 11, '6': '.anki.scheduler.SchedulingStates', '10': 'states'},
  ],
};

/// Descriptor for `SetSchedulingStatesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSchedulingStatesRequestDescriptor = $convert.base64Decode(
    'ChpTZXRTY2hlZHVsaW5nU3RhdGVzUmVxdWVzdBIQCgNrZXkYASABKAlSA2tleRI4CgZzdGF0ZX'
    'MYAiABKAsyIC5hbmtpLnNjaGVkdWxlci5TY2hlZHVsaW5nU3RhdGVzUgZzdGF0ZXM=');

const $core.Map<$core.String, $core.dynamic> FrontendServiceBase$json = {
  '1': 'FrontendService',
  '2': [
    {'1': 'GetSchedulingStatesWithContext', '2': '.anki.generic.Empty', '3': '.anki.frontend.SchedulingStatesWithContext'},
    {'1': 'SetSchedulingStates', '2': '.anki.frontend.SetSchedulingStatesRequest', '3': '.anki.generic.Empty'},
    {'1': 'ImportDone', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
    {'1': 'SearchInBrowser', '2': '.anki.search.SearchNode', '3': '.anki.generic.Empty'},
    {'1': 'deckOptionsRequireClose', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
    {'1': 'deckOptionsReady', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
    {'1': 'SaveCustomColours', '2': '.anki.generic.Empty', '3': '.anki.generic.Empty'},
  ],
};

@$core.Deprecated('Use frontendServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> FrontendServiceBase$messageJson = {
  '.anki.generic.Empty': $0.Empty$json,
  '.anki.frontend.SchedulingStatesWithContext': SchedulingStatesWithContext$json,
  '.anki.scheduler.SchedulingStates': $7.SchedulingStates$json,
  '.anki.scheduler.SchedulingState': $7.SchedulingState$json,
  '.anki.scheduler.SchedulingState.Normal': $7.SchedulingState_Normal$json,
  '.anki.scheduler.SchedulingState.New': $7.SchedulingState_New$json,
  '.anki.scheduler.SchedulingState.Learning': $7.SchedulingState_Learning$json,
  '.anki.cards.FsrsMemoryState': $3.FsrsMemoryState$json,
  '.anki.scheduler.SchedulingState.Review': $7.SchedulingState_Review$json,
  '.anki.scheduler.SchedulingState.Relearning': $7.SchedulingState_Relearning$json,
  '.anki.scheduler.SchedulingState.Filtered': $7.SchedulingState_Filtered$json,
  '.anki.scheduler.SchedulingState.Preview': $7.SchedulingState_Preview$json,
  '.anki.scheduler.SchedulingState.ReschedulingFilter': $7.SchedulingState_ReschedulingFilter$json,
  '.anki.scheduler.SchedulingContext': $7.SchedulingContext$json,
  '.anki.frontend.SetSchedulingStatesRequest': SetSchedulingStatesRequest$json,
  '.anki.search.SearchNode': $15.SearchNode$json,
  '.anki.search.SearchNode.Group': $15.SearchNode_Group$json,
  '.anki.search.SearchNode.Dupe': $15.SearchNode_Dupe$json,
  '.anki.search.SearchNode.Rated': $15.SearchNode_Rated$json,
  '.anki.search.SearchNode.IdList': $15.SearchNode_IdList$json,
  '.anki.search.SearchNode.Field': $15.SearchNode_Field$json,
};

/// Descriptor for `FrontendService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List frontendServiceDescriptor = $convert.base64Decode(
    'Cg9Gcm9udGVuZFNlcnZpY2USYQoeR2V0U2NoZWR1bGluZ1N0YXRlc1dpdGhDb250ZXh0EhMuYW'
    '5raS5nZW5lcmljLkVtcHR5GiouYW5raS5mcm9udGVuZC5TY2hlZHVsaW5nU3RhdGVzV2l0aENv'
    'bnRleHQSVQoTU2V0U2NoZWR1bGluZ1N0YXRlcxIpLmFua2kuZnJvbnRlbmQuU2V0U2NoZWR1bG'
    'luZ1N0YXRlc1JlcXVlc3QaEy5hbmtpLmdlbmVyaWMuRW1wdHkSNgoKSW1wb3J0RG9uZRITLmFu'
    'a2kuZ2VuZXJpYy5FbXB0eRoTLmFua2kuZ2VuZXJpYy5FbXB0eRI/Cg9TZWFyY2hJbkJyb3dzZX'
    'ISFy5hbmtpLnNlYXJjaC5TZWFyY2hOb2RlGhMuYW5raS5nZW5lcmljLkVtcHR5EkMKF2RlY2tP'
    'cHRpb25zUmVxdWlyZUNsb3NlEhMuYW5raS5nZW5lcmljLkVtcHR5GhMuYW5raS5nZW5lcmljLk'
    'VtcHR5EjwKEGRlY2tPcHRpb25zUmVhZHkSEy5hbmtpLmdlbmVyaWMuRW1wdHkaEy5hbmtpLmdl'
    'bmVyaWMuRW1wdHkSPQoRU2F2ZUN1c3RvbUNvbG91cnMSEy5hbmtpLmdlbmVyaWMuRW1wdHkaEy'
    '5hbmtpLmdlbmVyaWMuRW1wdHk=');

const $core.Map<$core.String, $core.dynamic> BackendFrontendServiceBase$json = {'1': 'BackendFrontendService'};

@$core.Deprecated('Use backendFrontendServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> BackendFrontendServiceBase$messageJson = {
};

/// Descriptor for `BackendFrontendService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List backendFrontendServiceDescriptor = $convert.base64Decode(
    'ChZCYWNrZW5kRnJvbnRlbmRTZXJ2aWNl');
