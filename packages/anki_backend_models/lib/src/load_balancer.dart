// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'deck_config.dart';
import 'easy_day_load.dart';
import 'ids.dart';
import 'interval_load_weight.dart';
import 'interval_to_weekday.dart';
import 'load_balancer_day.dart';
import 'review_state.dart' show constrainedFuzzBounds;
import 'sibling_modifiers.dart';
import 'weighted_interval_selection.dart';

const _maxLoadBalanceInterval = 90;
const _loadBalanceDays = 99;
const _maxU32 = 0xffffffff;

/// Selects a target interval from caller-supplied cached load-balancer state.
///
/// The selected preset supplies review counts and easy-day settings, while
/// sibling notes are considered across every preset. Each present preset must
/// contain exactly 99 cached days, and each easy-day config exactly seven
/// weekdays. This helper does not load storage or assemble scheduler context.
int? findLoadBalancedInterval({
  required Map<DeckConfigId, List<LoadBalancerDay>> daysByPreset,
  required Map<DeckConfigId, List<EasyDay>> easyDaysByPreset,
  required TimestampSecs nextDayAt,
  required DeckConfigId deckConfigId,
  required NoteId? noteId,
  required double interval,
  required int minimum,
  required int maximum,
  required BigInt? fuzzSeed,
}) {
  if (minimum < 0 || minimum > _maxU32) {
    throw ArgumentError.value(minimum, 'minimum', 'must fit in a Core u32');
  }
  if (maximum < 0 || maximum > _maxU32) {
    throw ArgumentError.value(maximum, 'maximum', 'must fit in a Core u32');
  }

  final coreInterval = _float32(interval);
  if (_rustUsizeFromInterval(coreInterval) > _maxLoadBalanceInterval ||
      minimum > _maxLoadBalanceInterval) {
    return null;
  }

  for (final entry in daysByPreset.entries) {
    if (entry.value.length != _loadBalanceDays) {
      throw ArgumentError.value(
        entry.value.length,
        'daysByPreset[${entry.key}] length',
        'expected exactly $_loadBalanceDays day buckets',
      );
    }
  }
  for (final entry in easyDaysByPreset.entries) {
    if (entry.value.length != 7) {
      throw ArgumentError.value(
        entry.value.length,
        'easyDaysByPreset[${entry.key}] length',
        'expected exactly 7 weekdays',
      );
    }
  }

  final days = daysByPreset[deckConfigId];
  final easyDays = easyDaysByPreset[deckConfigId];
  if (days == null || easyDays == null) return null;

  final (beforeDays, afterDays) =
      constrainedFuzzBounds(coreInterval, minimum, maximum);
  final reviewCounts = <int>[];
  final weekdays = <int>[];
  for (var target = beforeDays; target <= afterDays; target++) {
    reviewCounts.add(days[target].cardCount);
    weekdays.add(intervalToWeekday(target, nextDayAt));
  }

  final easyDaysModifiers =
      calculateEasyDaysModifiers(easyDays, weekdays, reviewCounts);
  final siblingModifiers = calculateSiblingModifiers(
    daysByPreset,
    beforeDays: beforeDays,
    afterDays: afterDays,
    noteId: noteId,
  );
  final candidates = <IntervalLoadCandidate>[];
  for (var index = 0; index < reviewCounts.length; index++) {
    candidates.add(
      IntervalLoadCandidate(
        targetInterval: beforeDays + index,
        reviewCount: reviewCounts[index],
        siblingModifier: siblingModifiers[index],
        easyDaysModifier: easyDaysModifiers[index],
      ),
    );
  }
  return selectWeightedInterval(candidates, fuzzSeed);
}

int _rustUsizeFromInterval(double interval) {
  if (interval.isNaN || interval <= 0) return 0;
  if (!interval.isFinite) return _maxU32;
  return interval.toInt();
}

double _float32(double value) => (Float32List(1)..[0] = value)[0];
