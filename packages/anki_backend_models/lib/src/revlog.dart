// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/stats.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/stats.pbenum.dart' as enums;
import 'package:fixnum/fixnum.dart';

import 'card.dart' show InvalidModelValue;
import 'ids.dart';

/// An opaque review log identifier stored as milliseconds since the epoch.
class RevlogId {
  const RevlogId(this.value);

  final Int64 value;

  factory RevlogId.fromTimestampMillis(Int64 millis) => RevlogId(millis);

  /// Creates an ID from the current clock, or a caller supplied clock value.
  factory RevlogId.now({Int64 Function()? timestampMillis}) =>
      RevlogId((timestampMillis ?? _currentTimestampMillis)());

  TimestampSecs asSecs() => value ~/ Int64(1000);

  static Int64 _currentTimestampMillis() =>
      Int64(DateTime.now().millisecondsSinceEpoch);

  @override
  bool operator ==(Object other) => other is RevlogId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

enum RevlogReviewKind {
  learning(0),
  review(1),
  relearning(2),
  filtered(3),
  manual(4),
  rescheduled(5);

  const RevlogReviewKind(this.value);
  final int value;

  static RevlogReviewKind fromRaw(int raw) => switch (raw) {
        0 => RevlogReviewKind.learning,
        1 => RevlogReviewKind.review,
        2 => RevlogReviewKind.relearning,
        3 => RevlogReviewKind.filtered,
        4 => RevlogReviewKind.manual,
        5 => RevlogReviewKind.rescheduled,
        _ => RevlogReviewKind.learning,
      };
}

/// A persisted review history entry and its scheduling/statistics helpers.
class RevlogEntry {
  RevlogEntry({
    this.id = const RevlogId(Int64.ZERO),
    this.cardId = Int64.ZERO,
    int usn = 0,
    int buttonChosen = 0,
    int interval = 0,
    int lastInterval = 0,
    int easeFactor = 0,
    int takenMillis = 0,
    this.reviewKind = RevlogReviewKind.learning,
  })  : usn = usn.toSigned(32),
        buttonChosen = buttonChosen.toUnsigned(8),
        interval = interval.toSigned(32),
        lastInterval = lastInterval.toSigned(32),
        easeFactor = easeFactor.toUnsigned(32),
        takenMillis = takenMillis.toUnsigned(32);

  final RevlogId id;
  final CardId cardId;
  final int usn;
  final int buttonChosen;
  final int interval;
  final int lastInterval;
  final int easeFactor;
  final int takenMillis;
  final RevlogReviewKind reviewKind;

  factory RevlogEntry.fromProto(proto.RevlogEntry value) => RevlogEntry(
        id: RevlogId(value.id),
        cardId: value.cid,
        usn: value.usn.toSigned(32),
        buttonChosen: value.buttonChosen.toUnsigned(8),
        interval: value.interval.toSigned(32),
        lastInterval: value.lastInterval.toSigned(32),
        easeFactor: value.easeFactor.toUnsigned(32),
        takenMillis: value.takenMillis.toUnsigned(32),
        reviewKind: RevlogReviewKind.fromRaw(value.reviewKind.value),
      );

  proto.RevlogEntry toProto() => proto.RevlogEntry(
        id: id.value,
        cid: cardId,
        usn: usn,
        buttonChosen: buttonChosen,
        interval: interval,
        lastInterval: lastInterval,
        easeFactor: easeFactor,
        takenMillis: takenMillis,
        reviewKind: enums.RevlogEntry_ReviewKind.valueOf(reviewKind.value)!,
      );

  /// Positive intervals are days; negative intervals are seconds.
  int get intervalSecs => _intervalToSecs(interval);

  int get lastIntervalSecs => _intervalToSecs(lastInterval);

  bool get isReset => reviewKind == RevlogReviewKind.manual && easeFactor == 0;

  bool get isCramming =>
      reviewKind == RevlogReviewKind.filtered && easeFactor == 0;

  bool get hasRating => buttonChosen > 0;

  bool get hasRatingAndAffectsScheduling => hasRating && !isCramming;
}

int _intervalToSecs(int interval) {
  final scaled = interval > 0
      ? _saturatingMultiplyInt32(interval, 86400)
      : _saturatingMultiplyInt32(interval, -1);
  if (scaled < 0) {
    throw const InvalidModelValue('negative interval seconds');
  }
  return scaled;
}

int _saturatingMultiplyInt32(int value, int multiplier) {
  final result = value * multiplier;
  if (result > 0x7fffffff) return 0x7fffffff;
  if (result < -0x80000000) return -0x80000000;
  return result;
}
