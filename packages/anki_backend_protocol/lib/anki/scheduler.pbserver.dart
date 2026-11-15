//
//  Generated code. Do not modify.
//  source: anki/scheduler.proto
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

import 'cards.pb.dart' as $3;
import 'collection.pb.dart' as $2;
import 'decks.pb.dart' as $4;
import 'generic.pb.dart' as $0;
import 'scheduler.pb.dart' as $7;
import 'scheduler.pbjson.dart';

export 'scheduler.pb.dart';

abstract class SchedulerServiceBase extends $pb.GeneratedService {
  $async.Future<$7.QueuedCards> getQueuedCards($pb.ServerContext ctx, $7.GetQueuedCardsRequest request);
  $async.Future<$2.OpChanges> answerCard($pb.ServerContext ctx, $7.CardAnswer request);
  $async.Future<$7.SchedTimingTodayResponse> schedTimingToday($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.String> studiedToday($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$0.String> studiedTodayMessage($pb.ServerContext ctx, $7.StudiedTodayMessageRequest request);
  $async.Future<$0.Empty> updateStats($pb.ServerContext ctx, $7.UpdateStatsRequest request);
  $async.Future<$0.Empty> extendLimits($pb.ServerContext ctx, $7.ExtendLimitsRequest request);
  $async.Future<$7.CountsForDeckTodayResponse> countsForDeckToday($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$7.CongratsInfoResponse> congratsInfo($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChanges> restoreBuriedAndSuspendedCards($pb.ServerContext ctx, $3.CardIds request);
  $async.Future<$2.OpChanges> unburyDeck($pb.ServerContext ctx, $7.UnburyDeckRequest request);
  $async.Future<$2.OpChangesWithCount> buryOrSuspendCards($pb.ServerContext ctx, $7.BuryOrSuspendCardsRequest request);
  $async.Future<$2.OpChanges> emptyFilteredDeck($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$2.OpChangesWithCount> rebuildFilteredDeck($pb.ServerContext ctx, $4.DeckId request);
  $async.Future<$2.OpChanges> scheduleCardsAsNew($pb.ServerContext ctx, $7.ScheduleCardsAsNewRequest request);
  $async.Future<$7.ScheduleCardsAsNewDefaultsResponse> scheduleCardsAsNewDefaults($pb.ServerContext ctx, $7.ScheduleCardsAsNewDefaultsRequest request);
  $async.Future<$2.OpChanges> setDueDate($pb.ServerContext ctx, $7.SetDueDateRequest request);
  $async.Future<$2.OpChanges> gradeNow($pb.ServerContext ctx, $7.GradeNowRequest request);
  $async.Future<$2.OpChangesWithCount> sortCards($pb.ServerContext ctx, $7.SortCardsRequest request);
  $async.Future<$2.OpChangesWithCount> sortDeck($pb.ServerContext ctx, $7.SortDeckRequest request);
  $async.Future<$7.SchedulingStates> getSchedulingStates($pb.ServerContext ctx, $3.CardId request);
  $async.Future<$0.StringList> describeNextStates($pb.ServerContext ctx, $7.SchedulingStates request);
  $async.Future<$0.Bool> stateIsLeech($pb.ServerContext ctx, $7.SchedulingState request);
  $async.Future<$0.Empty> upgradeScheduler($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$2.OpChanges> customStudy($pb.ServerContext ctx, $7.CustomStudyRequest request);
  $async.Future<$7.CustomStudyDefaultsResponse> customStudyDefaults($pb.ServerContext ctx, $7.CustomStudyDefaultsRequest request);
  $async.Future<$7.RepositionDefaultsResponse> repositionDefaults($pb.ServerContext ctx, $0.Empty request);
  $async.Future<$7.ComputeFsrsParamsResponse> computeFsrsParams($pb.ServerContext ctx, $7.ComputeFsrsParamsRequest request);
  $async.Future<$7.GetOptimalRetentionParametersResponse> getOptimalRetentionParameters($pb.ServerContext ctx, $7.GetOptimalRetentionParametersRequest request);
  $async.Future<$7.ComputeOptimalRetentionResponse> computeOptimalRetention($pb.ServerContext ctx, $7.SimulateFsrsReviewRequest request);
  $async.Future<$7.SimulateFsrsReviewResponse> simulateFsrsReview($pb.ServerContext ctx, $7.SimulateFsrsReviewRequest request);
  $async.Future<$7.SimulateFsrsWorkloadResponse> simulateFsrsWorkload($pb.ServerContext ctx, $7.SimulateFsrsReviewRequest request);
  $async.Future<$7.EvaluateParamsResponse> evaluateParams($pb.ServerContext ctx, $7.EvaluateParamsRequest request);
  $async.Future<$7.EvaluateParamsResponse> evaluateParamsLegacy($pb.ServerContext ctx, $7.EvaluateParamsLegacyRequest request);
  $async.Future<$7.ComputeMemoryStateResponse> computeMemoryState($pb.ServerContext ctx, $3.CardId request);
  $async.Future<$7.FuzzDeltaResponse> fuzzDelta($pb.ServerContext ctx, $7.FuzzDeltaRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetQueuedCards': return $7.GetQueuedCardsRequest();
      case 'AnswerCard': return $7.CardAnswer();
      case 'SchedTimingToday': return $0.Empty();
      case 'StudiedToday': return $0.Empty();
      case 'StudiedTodayMessage': return $7.StudiedTodayMessageRequest();
      case 'UpdateStats': return $7.UpdateStatsRequest();
      case 'ExtendLimits': return $7.ExtendLimitsRequest();
      case 'CountsForDeckToday': return $4.DeckId();
      case 'CongratsInfo': return $0.Empty();
      case 'RestoreBuriedAndSuspendedCards': return $3.CardIds();
      case 'UnburyDeck': return $7.UnburyDeckRequest();
      case 'BuryOrSuspendCards': return $7.BuryOrSuspendCardsRequest();
      case 'EmptyFilteredDeck': return $4.DeckId();
      case 'RebuildFilteredDeck': return $4.DeckId();
      case 'ScheduleCardsAsNew': return $7.ScheduleCardsAsNewRequest();
      case 'ScheduleCardsAsNewDefaults': return $7.ScheduleCardsAsNewDefaultsRequest();
      case 'SetDueDate': return $7.SetDueDateRequest();
      case 'GradeNow': return $7.GradeNowRequest();
      case 'SortCards': return $7.SortCardsRequest();
      case 'SortDeck': return $7.SortDeckRequest();
      case 'GetSchedulingStates': return $3.CardId();
      case 'DescribeNextStates': return $7.SchedulingStates();
      case 'StateIsLeech': return $7.SchedulingState();
      case 'UpgradeScheduler': return $0.Empty();
      case 'CustomStudy': return $7.CustomStudyRequest();
      case 'CustomStudyDefaults': return $7.CustomStudyDefaultsRequest();
      case 'RepositionDefaults': return $0.Empty();
      case 'ComputeFsrsParams': return $7.ComputeFsrsParamsRequest();
      case 'GetOptimalRetentionParameters': return $7.GetOptimalRetentionParametersRequest();
      case 'ComputeOptimalRetention': return $7.SimulateFsrsReviewRequest();
      case 'SimulateFsrsReview': return $7.SimulateFsrsReviewRequest();
      case 'SimulateFsrsWorkload': return $7.SimulateFsrsReviewRequest();
      case 'EvaluateParams': return $7.EvaluateParamsRequest();
      case 'EvaluateParamsLegacy': return $7.EvaluateParamsLegacyRequest();
      case 'ComputeMemoryState': return $3.CardId();
      case 'FuzzDelta': return $7.FuzzDeltaRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetQueuedCards': return this.getQueuedCards(ctx, request as $7.GetQueuedCardsRequest);
      case 'AnswerCard': return this.answerCard(ctx, request as $7.CardAnswer);
      case 'SchedTimingToday': return this.schedTimingToday(ctx, request as $0.Empty);
      case 'StudiedToday': return this.studiedToday(ctx, request as $0.Empty);
      case 'StudiedTodayMessage': return this.studiedTodayMessage(ctx, request as $7.StudiedTodayMessageRequest);
      case 'UpdateStats': return this.updateStats(ctx, request as $7.UpdateStatsRequest);
      case 'ExtendLimits': return this.extendLimits(ctx, request as $7.ExtendLimitsRequest);
      case 'CountsForDeckToday': return this.countsForDeckToday(ctx, request as $4.DeckId);
      case 'CongratsInfo': return this.congratsInfo(ctx, request as $0.Empty);
      case 'RestoreBuriedAndSuspendedCards': return this.restoreBuriedAndSuspendedCards(ctx, request as $3.CardIds);
      case 'UnburyDeck': return this.unburyDeck(ctx, request as $7.UnburyDeckRequest);
      case 'BuryOrSuspendCards': return this.buryOrSuspendCards(ctx, request as $7.BuryOrSuspendCardsRequest);
      case 'EmptyFilteredDeck': return this.emptyFilteredDeck(ctx, request as $4.DeckId);
      case 'RebuildFilteredDeck': return this.rebuildFilteredDeck(ctx, request as $4.DeckId);
      case 'ScheduleCardsAsNew': return this.scheduleCardsAsNew(ctx, request as $7.ScheduleCardsAsNewRequest);
      case 'ScheduleCardsAsNewDefaults': return this.scheduleCardsAsNewDefaults(ctx, request as $7.ScheduleCardsAsNewDefaultsRequest);
      case 'SetDueDate': return this.setDueDate(ctx, request as $7.SetDueDateRequest);
      case 'GradeNow': return this.gradeNow(ctx, request as $7.GradeNowRequest);
      case 'SortCards': return this.sortCards(ctx, request as $7.SortCardsRequest);
      case 'SortDeck': return this.sortDeck(ctx, request as $7.SortDeckRequest);
      case 'GetSchedulingStates': return this.getSchedulingStates(ctx, request as $3.CardId);
      case 'DescribeNextStates': return this.describeNextStates(ctx, request as $7.SchedulingStates);
      case 'StateIsLeech': return this.stateIsLeech(ctx, request as $7.SchedulingState);
      case 'UpgradeScheduler': return this.upgradeScheduler(ctx, request as $0.Empty);
      case 'CustomStudy': return this.customStudy(ctx, request as $7.CustomStudyRequest);
      case 'CustomStudyDefaults': return this.customStudyDefaults(ctx, request as $7.CustomStudyDefaultsRequest);
      case 'RepositionDefaults': return this.repositionDefaults(ctx, request as $0.Empty);
      case 'ComputeFsrsParams': return this.computeFsrsParams(ctx, request as $7.ComputeFsrsParamsRequest);
      case 'GetOptimalRetentionParameters': return this.getOptimalRetentionParameters(ctx, request as $7.GetOptimalRetentionParametersRequest);
      case 'ComputeOptimalRetention': return this.computeOptimalRetention(ctx, request as $7.SimulateFsrsReviewRequest);
      case 'SimulateFsrsReview': return this.simulateFsrsReview(ctx, request as $7.SimulateFsrsReviewRequest);
      case 'SimulateFsrsWorkload': return this.simulateFsrsWorkload(ctx, request as $7.SimulateFsrsReviewRequest);
      case 'EvaluateParams': return this.evaluateParams(ctx, request as $7.EvaluateParamsRequest);
      case 'EvaluateParamsLegacy': return this.evaluateParamsLegacy(ctx, request as $7.EvaluateParamsLegacyRequest);
      case 'ComputeMemoryState': return this.computeMemoryState(ctx, request as $3.CardId);
      case 'FuzzDelta': return this.fuzzDelta(ctx, request as $7.FuzzDeltaRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SchedulerServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => SchedulerServiceBase$messageJson;
}

abstract class BackendSchedulerServiceBase extends $pb.GeneratedService {
  $async.Future<$7.ComputeFsrsParamsResponse> computeFsrsParamsFromItems($pb.ServerContext ctx, $7.ComputeFsrsParamsFromItemsRequest request);
  $async.Future<$7.FsrsBenchmarkResponse> fsrsBenchmark($pb.ServerContext ctx, $7.FsrsBenchmarkRequest request);
  $async.Future<$0.Empty> exportDataset($pb.ServerContext ctx, $7.ExportDatasetRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ComputeFsrsParamsFromItems': return $7.ComputeFsrsParamsFromItemsRequest();
      case 'FsrsBenchmark': return $7.FsrsBenchmarkRequest();
      case 'ExportDataset': return $7.ExportDatasetRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ComputeFsrsParamsFromItems': return this.computeFsrsParamsFromItems(ctx, request as $7.ComputeFsrsParamsFromItemsRequest);
      case 'FsrsBenchmark': return this.fsrsBenchmark(ctx, request as $7.FsrsBenchmarkRequest);
      case 'ExportDataset': return this.exportDataset(ctx, request as $7.ExportDatasetRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendSchedulerServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendSchedulerServiceBase$messageJson;
}
