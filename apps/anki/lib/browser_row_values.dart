/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:math' as math;

import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:anki_dart/anki_dart.dart';
import 'package:anki_scheduler_timing/anki_scheduler_timing.dart';
import 'package:fixnum/fixnum.dart';

import 'dart:typed_data';

import 'l10n/app_localizations.dart';

/// Projects persisted Card/Note scheduling values for the Browser table.
/// Date and timespan strings remain compact, platform-neutral text.
Map<String, String> browserRowValues({
  required List<models.Card> cards,
  required models.Note note,
  required BrowserColumnMode mode,
  required SchedTimingToday timing,
  required AppLocalizations l10n,
}) {
  if (cards.isEmpty) return const {};
  final card = cards.first;
  return {
    'cardDue': _due(cards, mode, timing, l10n),
    'cardEase': _ease(cards),
    'cardMod': _dateTime(
      cards.map((c) => c.mtimeSecs.toInt()).reduce(math.max),
    ),
    'noteCrt': _dateTime(note.id.toInt() ~/ 1000),
    'noteMod': _dateTime(note.mtimeSecs.toInt()),
    'cardIvl': _interval(cards, mode, l10n),
    'cardLapses': cards
        .fold<int>(0, (sum, c) => (sum + c.lapses).toUnsigned(32))
        .toString(),
    'cardReps': cards
        .fold<int>(0, (sum, c) => (sum + c.reps).toUnsigned(32))
        .toString(),
    'originalPosition':
        card.originalPosition?.toString() ??
        (card.ctype == models.CardType.newCard ? card.due.toString() : ''),
    'stability': card.memoryState == null
        ? ''
        : _timeSpan(card.memoryState!.stability * 86400, l10n),
    'difficulty': card.memoryState == null
        ? ''
        : '${_f32((card.memoryState!.difficulty - 1) / 9 * 100).round()}%',
    'retrievability': _retrievability(card, timing),
  };
}

String _due(
  List<models.Card> cards,
  BrowserColumnMode mode,
  SchedTimingToday timing,
  AppLocalizations l10n,
) {
  if (mode == BrowserColumnMode.notes) {
    final dates =
        cards
            .where(
              (c) =>
                  c.originalDeckId == Int64.ZERO &&
                  !_new(c) &&
                  c.queue.value >= 0,
            )
            .map((c) => _dueDate(c, timing))
            .whereType<String>()
            .toList()
          ..sort();
    return dates.isEmpty ? '' : dates.first;
  }
  final card = cards.first;
  final value = card.originalDeckId != Int64.ZERO
      ? l10n.browserDueFiltered
      : _new(card)
      ? l10n.browserDueNew(card.due)
      : _dueDate(card, timing) ?? '';
  return card.queue.value < 0 && value.isNotEmpty ? '($value)' : value;
}

bool _new(models.Card card) =>
    card.queue == models.CardQueue.newCard ||
    card.ctype == models.CardType.newCard;

bool _dueInDays(models.Card card) {
  final due = card.originalDue == 0 ? card.due : card.originalDue;
  return (card.ctype != models.CardType.newCard && due <= 365000) ||
      card.queue == models.CardQueue.dayLearn ||
      card.queue == models.CardQueue.review ||
      (card.ctype == models.CardType.review && card.queue.value < 0);
}

String? _dueDate(models.Card card, SchedTimingToday timing) {
  final due = card.originalDue == 0 ? card.due : card.originalDue;
  if (card.queue == models.CardQueue.learn) return _date(due);
  if (!_dueInDays(card)) return null;
  return _date(timing.now + (due - timing.daysElapsed) * 86400);
}

String _ease(List<models.Card> cards) {
  final existing = cards
      .where((c) => c.ctype != models.CardType.newCard)
      .toList();
  if (existing.isEmpty) return 'New';
  final sum = existing.fold<int>(
    0,
    (total, c) => (total + c.easeFactorRaw).toUnsigned(16),
  );
  return '${sum ~/ existing.length.toUnsigned(16) ~/ 10}%';
}

String _interval(
  List<models.Card> cards,
  BrowserColumnMode mode,
  AppLocalizations l10n,
) {
  if (mode == BrowserColumnMode.cards) {
    switch (cards.first.ctype) {
      case models.CardType.newCard:
        return l10n.browserNew;
      case models.CardType.learn:
        return l10n.browserLearning;
      case models.CardType.review || models.CardType.relearn:
        break;
    }
  }
  final intervals = cards
      .where(
        (c) =>
            c.ctype == models.CardType.review ||
            c.ctype == models.CardType.relearn,
      )
      .map((c) => c.interval)
      .toList();
  if (intervals.isEmpty) return '';
  final intervalSum = intervals.fold<int>(
    0,
    (sum, value) => (sum + value).toUnsigned(32),
  );
  final totalSeconds = (intervalSum * 86400).toUnsigned(32);
  final averageSeconds = totalSeconds ~/ intervals.length.toUnsigned(32);
  return _timeSpan(averageSeconds.toDouble(), l10n);
}

String _retrievability(models.Card card, SchedTimingToday timing) {
  final state = card.memoryState;
  if (state == null) return '';
  int elapsed;
  if (card.lastReviewTimeSecs != null) {
    elapsed = (timing.now - card.lastReviewTimeSecs!.toInt()).toUnsigned(32);
  } else if (_dueInDays(card)) {
    final due = card.originalDue == 0 ? card.due : card.originalDue;
    final dueTime = card.queue == models.CardQueue.learn
        ? due
        : timing.now + (due - timing.daysElapsed) * 86400;
    elapsed = math
        .max(0, timing.now - (dueTime - card.interval * 86400))
        .toUnsigned(32);
  } else {
    final due = card.originalDue == 0 ? card.due : card.originalDue;
    elapsed = (timing.now - due).toUnsigned(32);
  }
  final decay = card.decay ?? 0.5;
  final daysElapsed = _f32(_f32(elapsed.toDouble()) / 86400);
  final exponentForFactor = _f32(1 / _f32(-decay));
  final factor = _f32(math.pow(0.9, exponentForFactor).toDouble()) - 1;
  final elapsedOverStability = _f32(daysElapsed / state.stability);
  final base = _f32(_f32(elapsedOverStability * factor) + 1);
  final retention = _f32(math.pow(base, _f32(-decay)).toDouble());
  if (!retention.isFinite) return '';
  return '${_f32(retention * 100).round()}%';
}

String _date(int seconds) {
  final date = _localDateTime(seconds);
  if (date == null) return 'invalid date';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _dateTime(int seconds) {
  final date = _localDateTime(seconds);
  if (date == null) return 'invalid date @ invalid date';
  return '${_date(seconds)} @ ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

DateTime? _localDateTime(int seconds) {
  if (seconds < -8334601228800 || seconds > 8210266876799) return null;
  try {
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  } on RangeError {
    return null;
  }
}

String _timeSpan(double seconds, AppLocalizations l10n) {
  final sourceSeconds = _f32(seconds);
  const minute = 60.0;
  const hour = 3600.0;
  const day = 86400.0;
  final year = _f32(365.0 * day);
  final month = _f32(year / 12.0);
  final magnitude = sourceSeconds.abs();
  final (unit, divisor) = magnitude < minute
      ? ('seconds', 1.0)
      : magnitude < hour
      ? ('minutes', minute)
      : magnitude < day
      ? ('hours', hour)
      : magnitude < month
      ? ('days', day)
      : magnitude < year
      ? ('months', month)
      : ('years', year);
  var amount = _f32(sourceSeconds / divisor);
  if (unit == 'seconds' || unit == 'days') {
    amount = amount.roundToDouble();
  } else {
    amount = _f32((_f32(amount * 10)).roundToDouble() / 10);
  }
  final amountText = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1);
  final singular = amount == 1;
  return switch (unit) {
    'seconds' =>
      singular
          ? l10n.browserTimespanSecond
          : l10n.browserTimespanSeconds(amountText),
    'minutes' =>
      singular
          ? l10n.browserTimespanMinute
          : l10n.browserTimespanMinutes(amountText),
    'hours' =>
      singular
          ? l10n.browserTimespanHour
          : l10n.browserTimespanHours(amountText),
    'days' =>
      singular ? l10n.browserTimespanDay : l10n.browserTimespanDays(amountText),
    'months' =>
      singular
          ? l10n.browserTimespanMonth
          : l10n.browserTimespanMonths(amountText),
    _ =>
      singular
          ? l10n.browserTimespanYear
          : l10n.browserTimespanYears(amountText),
  };
}

double _f32(double value) {
  final singlePrecision = Float32List(1);
  singlePrecision[0] = value;
  return singlePrecision[0];
}
