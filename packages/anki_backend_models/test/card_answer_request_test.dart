// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  group('cardAnswerFromSchedulingStates', () {
    test('selects each rating state and preserves request values and wrappers',
        () {
      final normal = proto.SchedulingState(
        normal: proto.SchedulingState_Normal(
          new_1: proto.SchedulingState_New(position: 11),
        ),
      );
      final filtered = proto.SchedulingState(
        filtered: proto.SchedulingState_Filtered(
          preview: proto.SchedulingState_Preview(scheduledSecs: 12),
        ),
      );
      final reschedulingFiltered = proto.SchedulingState(
        filtered: proto.SchedulingState_Filtered(
          rescheduling: proto.SchedulingState_ReschedulingFilter(
            originalState: proto.SchedulingState_Normal(
              review: proto.SchedulingState_Review(scheduledDays: 13),
            ),
          ),
        ),
      );
      final states = proto.SchedulingStates(
        current: reschedulingFiltered,
        again: filtered,
        hard: reschedulingFiltered,
        good: filtered,
        easy: normal,
      );
      final expected = <proto.CardAnswer_Rating, proto.SchedulingState>{
        proto.CardAnswer_Rating.AGAIN: filtered,
        proto.CardAnswer_Rating.HARD: reschedulingFiltered,
        proto.CardAnswer_Rating.GOOD: filtered,
        proto.CardAnswer_Rating.EASY: normal,
      };

      for (final entry in expected.entries) {
        final customData =
            entry.key == proto.CardAnswer_Rating.HARD ? '' : 'カード 🗂';
        final request = cardAnswerFromSchedulingStates(
          cardId: Int64.parseInt('9007199254740997'),
          states: states,
          rating: entry.key,
          customData: customData,
          answeredAtMillis: Int64.parseInt('-9007199254740997'),
          millisecondsTaken: 0xffffffff,
        );
        expect(request.cardId, Int64.parseInt('9007199254740997'));
        expect(request.currentState, reschedulingFiltered);
        final expectedNewState = entry.value.deepCopy()
          ..customData = customData;
        expect(request.newState, expectedNewState);
        expect(request.newState.hasCustomData(), isTrue);
        expect(request.newState.customData, customData);
        expect(request.currentState.hasCustomData(), isFalse);
        expect(request.rating, entry.key);
        expect(request.answeredAtMillis, Int64.parseInt('-9007199254740997'));
        expect(request.millisecondsTaken, 0xffffffff);
        expect(identical(request.currentState, states.current), isFalse);
        expect(identical(request.newState, entry.value), isFalse);
        expect(entry.value.hasCustomData(), isFalse);
        request.currentState.clearKind();
        request.newState.clearKind();
        expect(states.current.hasFiltered(), isTrue);
        expect(
            entry.value.whichKind(), isNot(proto.SchedulingState_Kind.notSet));
      }

      expect(normal.normal.new_1.position, 11);
      expect(filtered.filtered.preview.scheduledSecs, 12);
      expect(
        cardAnswerFromSchedulingStates(
          cardId: Int64.ONE,
          states: states,
          rating: proto.CardAnswer_Rating.AGAIN,
          customData: '',
          answeredAtMillis: Int64.ZERO,
          millisecondsTaken: 0,
        ).millisecondsTaken,
        0,
      );
    });

    test('rejects missing states and elapsed milliseconds outside uint32', () {
      final states = proto.SchedulingStates(
        current: proto.SchedulingState(),
        again: proto.SchedulingState(),
      );
      CardAnswerRequest() => cardAnswerFromSchedulingStates(
            cardId: Int64(1),
            states: states,
            rating: proto.CardAnswer_Rating.AGAIN,
            customData: '',
            answeredAtMillis: Int64(0),
            millisecondsTaken: 0,
          );

      expect(CardAnswerRequest, throwsArgumentError);
      expect(
        () => cardAnswerFromSchedulingStates(
          cardId: Int64(1),
          states: proto.SchedulingStates(
            current: proto.SchedulingState(
              normal: proto.SchedulingState_Normal(),
            ),
          ),
          rating: proto.CardAnswer_Rating.EASY,
          customData: '',
          answeredAtMillis: Int64(0),
          millisecondsTaken: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => cardAnswerFromSchedulingStates(
          cardId: Int64(1),
          states: proto.SchedulingStates(
            current: proto.SchedulingState(),
            again: proto.SchedulingState(),
          ),
          rating: proto.CardAnswer_Rating.AGAIN,
          customData: '',
          answeredAtMillis: Int64(0),
          millisecondsTaken: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => cardAnswerFromSchedulingStates(
          cardId: Int64(1),
          states: proto.SchedulingStates(
            current: proto.SchedulingState(),
            again: proto.SchedulingState(),
          ),
          rating: proto.CardAnswer_Rating.AGAIN,
          customData: '',
          answeredAtMillis: Int64(0),
          millisecondsTaken: 0x100000000,
        ),
        throwsArgumentError,
      );
    });
  });
}
