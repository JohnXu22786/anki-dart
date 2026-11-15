import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/cards.pb.dart' as proto_cards;
import 'package:anki_backend_protocol/anki/notes.pb.dart' as proto_notes;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('Card', () {
    test('defaults and new constructor match upstream defaults', () {
      final card = Card();
      expect(card.id, Int64.ZERO);
      expect(card.noteId, Int64.ZERO);
      expect(card.deckId, Int64.ZERO);
      expect(card.mtimeSecs, Int64.ZERO);
      expect(card.usn, 0);
      expect(card.due, 0);
      expect(card.interval, 0);
      expect(card.easeFactorRaw, 0);
      expect(card.reps, 0);
      expect(card.lapses, 0);
      expect(card.remainingStepsRaw, 0);
      expect(card.originalDue, 0);
      expect(card.originalDeckId, Int64.ZERO);
      expect(card.flags, 0);
      expect(card.desiredRetention, isNull);
      expect(card.decay, isNull);
      expect(card.lastReviewTimeSecs, isNull);
      expect(card.templateIdx, 0);
      expect(card.ctype, CardType.newCard);
      expect(card.queue, CardQueue.newCard);
      expect(card.originalPosition, isNull);
      expect(card.memoryState, isNull);
      expect(card.customData, '');
      expect(CardId(1999).asSecs(), Int64(1));
      expect(CardId(-1999).asSecs(), Int64(-1));

      final created = Card.newCard(
        noteId: Int64(12),
        templateIdx: 4,
        deckId: Int64(32),
        due: -9,
      );
      expect(created.noteId, Int64(12));
      expect(created.templateIdx, 4);
      expect(created.deckId, Int64(32));
      expect(created.due, -9);
      expect(created.ctype, CardType.newCard);
    });

    test('converts every field to and from protobuf', () {
      final proto = proto_cards.Card(
        id: Int64.parseInt('-9223372036854775000'),
        noteId: Int64(2),
        deckId: Int64(3),
        templateIdx: 4,
        mtimeSecs: Int64.parseInt('9223372036854775000'),
        usn: -6,
        ctype: 3,
        queue: -3,
        due: -8,
        interval: 10,
        easeFactor: 3500,
        reps: 12,
        lapses: 13,
        remainingSteps: 2007,
        originalDue: -14,
        originalDeckId: Int64(15),
        flags: 7,
        originalPosition: 16,
        customData: '{"a":1}',
        memoryState:
            proto_cards.FsrsMemoryState(stability: 1.25, difficulty: 8.5),
        desiredRetention: 0.9,
        decay: 0.15,
        lastReviewTimeSecs: Int64.parseInt('-9223372036854775000'),
      );
      final card = Card.fromProto(proto);
      expect(card.id, proto.id);
      expect(card.noteId, proto.noteId);
      expect(card.deckId, proto.deckId);
      expect(card.templateIdx, 4);
      expect(card.mtimeSecs, proto.mtimeSecs);
      expect(card.usn, -6);
      expect(card.ctype, CardType.relearn);
      expect(card.queue, CardQueue.userBuried);
      expect(card.due, -8);
      expect(card.interval, 10);
      expect(card.easeFactorRaw, 3500);
      expect(card.reps, 12);
      expect(card.lapses, 13);
      expect(card.remainingStepsRaw, 2007);
      expect(card.originalDue, -14);
      expect(card.originalDeckId, Int64(15));
      expect(card.flags, 7);
      expect(card.originalPosition, 16);
      expect(card.customData, '{"a":1}');
      expect(card.memoryState?.stability, proto.memoryState.stability);
      final expectedF32 = Float32List(1);
      expectedF32[0] = proto.desiredRetention;
      expect(card.desiredRetention, expectedF32[0]);
      expectedF32[0] = proto.decay;
      expect(card.decay, expectedF32[0]);
      expect(card.lastReviewTimeSecs, proto.lastReviewTimeSecs);

      final converted = card.toProto();
      expect(converted.writeToBuffer(), proto.writeToBuffer());
    });

    test('maps every upstream raw queue and type value', () {
      for (final (raw, expected) in [
        (0, CardType.newCard),
        (1, CardType.learn),
        (2, CardType.review),
        (3, CardType.relearn),
      ]) {
        expect(Card.fromProto(proto_cards.Card(ctype: raw)).ctype, expected);
      }
      for (final (raw, expected) in [
        (0, CardQueue.newCard),
        (1, CardQueue.learn),
        (2, CardQueue.review),
        (3, CardQueue.dayLearn),
        (4, CardQueue.previewRepeat),
        (-1, CardQueue.suspended),
        (-2, CardQueue.schedBuried),
        (-3, CardQueue.userBuried),
      ]) {
        expect(Card.fromProto(proto_cards.Card(queue: raw)).queue, expected);
      }
    });

    test('narrows unsigned fields and enum values like Rust casts', () {
      final card = Card.fromProto(proto_cards.Card(
        templateIdx: 65537,
        ctype: 256,
        easeFactor: 65538,
        flags: 257,
      ));
      expect(card.templateIdx, 1);
      expect(card.ctype, CardType.newCard);
      expect(card.easeFactorRaw, 2);
      expect(card.flags, 1);
      expect(Card.fromProto(proto_cards.Card(queue: 255)).queue,
          CardQueue.suspended);

      final directlyConstructed = Card(
        templateIdx: 65536,
        easeFactorRaw: 65537,
        flags: 256,
      );
      expect(directlyConstructed.templateIdx, 0);
      expect(directlyConstructed.easeFactorRaw, 1);
      expect(directlyConstructed.flags, 0);
      expect(directlyConstructed.toProto().templateIdx, 0);
      expect(directlyConstructed.toProto().easeFactor, 1);
    });

    test('rejects invalid narrowed enum values with source error messages', () {
      expect(
        () => Card.fromProto(proto_cards.Card(ctype: 4)),
        throwsA(isA<InvalidModelValue>()
            .having((e) => e.message, 'message', 'invalid card type')),
      );
      expect(
        () => Card.fromProto(proto_cards.Card(queue: 5)),
        throwsA(isA<InvalidModelValue>()
            .having((e) => e.message, 'message', 'invalid card queue')),
      );
    });

    test('preserves optional protobuf field presence', () {
      final card = Card.fromProto(proto_cards.Card());
      final proto = card.toProto();
      expect(proto.hasMemoryState(), isFalse);
      expect(proto.hasDesiredRetention(), isFalse);
      expect(proto.hasDecay(), isFalse);
      expect(proto.hasLastReviewTimeSecs(), isFalse);
      expect(proto.hasOriginalPosition(), isFalse);
      final present = Card(
        memoryState: FsrsMemoryState(stability: 1, difficulty: 2),
        desiredRetention: 0,
        decay: 0,
        lastReviewTimeSecs: Int64.ZERO,
        originalPosition: 0,
      ).toProto();
      expect(present.hasMemoryState(), isTrue);
      expect(present.hasDesiredRetention(), isTrue);
      expect(present.hasDecay(), isTrue);
      expect(present.hasLastReviewTimeSecs(), isTrue);
      expect(present.hasOriginalPosition(), isTrue);
    });

    test('maps queue categories and scheduling helpers', () {
      expect(CardQueue.newCard.number, CardQueueNumber.newCard);
      expect(CardQueue.learn.number, CardQueueNumber.learning);
      expect(CardQueue.previewRepeat.number, CardQueueNumber.learning);
      expect(CardQueue.dayLearn.number, CardQueueNumber.review);
      expect(CardQueue.review.number, CardQueueNumber.review);
      for (final queue in [
        CardQueue.suspended,
        CardQueue.schedBuried,
        CardQueue.userBuried,
      ]) {
        expect(queue.number, CardQueueNumber.invalid);
      }
      expect(Card(remainingStepsRaw: 2007).remainingSteps, 7);
      expect(Card(easeFactorRaw: 2500).easeFactor, 2.5);
      final f32 = Float32List(1);
      f32[0] = 2501 / 1000.0;
      expect(Card(easeFactorRaw: 2501).easeFactor, f32[0]);
      f32[0] = 1.23456789;
      final f32State =
          FsrsMemoryState(stability: 1.23456789, difficulty: 1.23456789);
      expect(f32State.stability, f32[0]);
      expect(f32State.difficulty, f32[0]);
      expect(
          Card(desiredRetention: 1.23456789, decay: 1.23456789)
              .desiredRetention,
          f32[0]);
      expect(
          Card(desiredRetention: 1.23456789, decay: 1.23456789).decay, f32[0]);
      expect(Card(queue: CardQueue.learn).isIntradayLearning, isTrue);
      expect(Card(queue: CardQueue.previewRepeat).isIntradayLearning, isTrue);
      expect(Card(queue: CardQueue.dayLearn).isIntradayLearning, isFalse);
      expect(Card(queue: CardQueue.review).isIntradayLearning, isFalse);
    });
  });

  group('Note', () {
    test('preserves protobuf tags, signed IDs and upstream mtime casts', () {
      final note = Note.fromProto(proto_notes.Note(
        id: Int64.parseInt('-9223372036854775000'),
        guid: 'guid',
        notetypeId: Int64.parseInt('9223372036854775000'),
        mtimeSecs: 4294967295,
        usn: -3,
        tags: ['one', 'two'],
        fields: ['front', 'back'],
      ));
      expect(note.id, Int64.parseInt('-9223372036854775000'));
      expect(note.notetypeId, Int64.parseInt('9223372036854775000'));
      expect(note.mtimeSecs, Int64(4294967295));
      expect(note.usn, -3);
      expect(note.tags, ['one', 'two']);
      expect(note.fields, ['front', 'back']);
      final proto = note.toProto();
      expect(proto.mtimeSecs, 4294967295);
      expect(Note(mtimeSecs: Int64(-1)).toProto().mtimeSecs, 4294967295);
      expect(proto.info_.byIndex.map((field) => field.tagNumber),
          [1, 2, 3, 4, 5, 6, 7]);
    });

    test('clears cached sort field and checksum on protobuf conversion', () {
      final note = Note(sortField: 'cached sort', checksum: 42);
      final fromProto = Note.fromProto(note.toProto());
      expect(fromProto.sortField, isNull);
      expect(fromProto.checksum, isNull);

      final mutable = Note(fields: ['front'], sortField: 'front', checksum: -1);
      expect(mutable.checksum, 4294967295);
      expect(() => mutable.fields.add('back'), throwsUnsupportedError);
      mutable.setField(0, 'changed');
      expect(mutable.fields, ['changed']);
      expect(mutable.sortField, isNull);
      expect(mutable.checksum, isNull);
      expect(
          () => mutable.setField(2, 'out of range'),
          throwsA(isA<RangeError>()
              .having((e) => e.message, 'message', 'field idx out of range')));

      final mutableList = Note(fields: ['a'], sortField: 'a', checksum: 1);
      mutableList.fieldsMut().add('b');
      expect(mutableList.fields, ['a', 'b']);
      expect(mutableList.sortField, isNull);
      expect(mutableList.checksum, isNull);
    });
  });
}
