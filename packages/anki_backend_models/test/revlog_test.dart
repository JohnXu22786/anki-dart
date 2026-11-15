// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/stats.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('RevlogId', () {
    test('stores millisecond IDs and truncates seconds toward zero', () {
      expect(RevlogId(Int64(1234)).asSecs(), Int64(1));
      expect(RevlogId(Int64(-1234)).asSecs(), Int64(-1));
      expect(RevlogId.now(timestampMillis: () => Int64(123456)).asSecs(),
          Int64(123));
    });
  });

  group('RevlogEntry', () {
    test('converts every protobuf value and preserves round trips', () {
      final protoValue = proto.RevlogEntry(
        id: Int64(1250),
        cid: Int64(42),
        usn: -3,
        buttonChosen: 4,
        interval: -86400,
        lastInterval: 30,
        easeFactor: 2500,
        takenMillis: 1234,
        reviewKind: proto.RevlogEntry_ReviewKind.REVIEW,
      );
      final entry = RevlogEntry.fromProto(protoValue);
      expect(entry.id, RevlogId(Int64(1250)));
      expect(entry.cardId, Int64(42));
      expect(entry.usn, -3);
      expect(entry.buttonChosen, 4);
      expect(entry.interval, -86400);
      expect(entry.lastInterval, 30);
      expect(entry.easeFactor, 2500);
      expect(entry.takenMillis, 1234);
      expect(entry.reviewKind, RevlogReviewKind.review);
      expect(entry.toProto(), protoValue);
    });

    test('normalizes direct values to the source integer widths', () {
      final entry = RevlogEntry(
        usn: 0x80000001,
        buttonChosen: 0x104,
        interval: 0x80000001,
        lastInterval: 0x100000002,
        easeFactor: 0x100000001,
        takenMillis: 0x100000003,
      );
      expect(entry.usn, -0x7fffffff);
      expect(entry.buttonChosen, 4);
      expect(entry.interval, -0x7fffffff);
      expect(entry.lastInterval, 2);
      expect(entry.easeFactor, 1);
      expect(entry.takenMillis, 3);
      final proto = entry.toProto();
      expect(proto.usn, entry.usn);
      expect(proto.buttonChosen, entry.buttonChosen);
      expect(proto.interval, entry.interval);
      expect(proto.lastInterval, entry.lastInterval);
      expect(proto.easeFactor, entry.easeFactor);
      expect(proto.takenMillis, entry.takenMillis);
    });

    test('converts day and second intervals with i32 saturation', () {
      expect(RevlogEntry(interval: 2).intervalSecs, 172800);
      expect(RevlogEntry(interval: -90).intervalSecs, 90);
      expect(RevlogEntry(interval: 0x7fffffff).intervalSecs, 0x7fffffff);
      expect(RevlogEntry(interval: -0x80000000).intervalSecs, 0x7fffffff);
      expect(RevlogEntry(lastInterval: -45).lastIntervalSecs, 45);
    });

    test('identifies resets, cramming, ratings, and scheduling effects', () {
      expect(RevlogEntry(reviewKind: RevlogReviewKind.manual).isReset, true);
      expect(
        RevlogEntry(
          reviewKind: RevlogReviewKind.manual,
          easeFactor: 1000,
        ).isReset,
        false,
      );
      expect(
        RevlogEntry(reviewKind: RevlogReviewKind.filtered).isCramming,
        true,
      );
      expect(
        RevlogEntry(
          reviewKind: RevlogReviewKind.filtered,
          buttonChosen: 3,
        ).hasRatingAndAffectsScheduling,
        false,
      );
      expect(RevlogEntry(buttonChosen: 1).hasRatingAndAffectsScheduling, true);
      expect(RevlogEntry(buttonChosen: 0).hasRating, false);
    });
  });
}
