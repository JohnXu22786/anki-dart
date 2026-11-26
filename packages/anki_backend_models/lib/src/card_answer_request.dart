// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/scheduler.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

import 'ids.dart';

/// Builds a generated Core answer request from the states shown to the caller.
///
/// This only constructs the request; it does not apply the answer or persist
/// any scheduling changes. State messages are copied so the request and the
/// caller's state snapshot can be mutated independently. [customData] comes
/// from the caller's Card snapshot because the scheduler does not populate it.
proto.CardAnswer cardAnswerFromSchedulingStates({
  required CardId cardId,
  required proto.SchedulingStates states,
  required proto.CardAnswer_Rating rating,
  required String customData,
  required Int64 answeredAtMillis,
  required int millisecondsTaken,
}) {
  if (!states.hasCurrent()) {
    throw ArgumentError.value(states, 'states', 'current state is required');
  }
  _requireWrappedState(states.current, 'current');

  final proto.SchedulingState selectedState = switch (rating) {
    proto.CardAnswer_Rating.AGAIN => _requireOutcome(
        states.hasAgain(),
        states.again,
        'again',
      ),
    proto.CardAnswer_Rating.HARD => _requireOutcome(
        states.hasHard(),
        states.hard,
        'hard',
      ),
    proto.CardAnswer_Rating.GOOD => _requireOutcome(
        states.hasGood(),
        states.good,
        'good',
      ),
    proto.CardAnswer_Rating.EASY => _requireOutcome(
        states.hasEasy(),
        states.easy,
        'easy',
      ),
    _ => throw ArgumentError.value(rating, 'rating', 'unsupported rating'),
  };

  if (millisecondsTaken < 0 || millisecondsTaken > 0xffffffff) {
    throw ArgumentError.value(
      millisecondsTaken,
      'millisecondsTaken',
      'expected a uint32',
    );
  }

  return proto.CardAnswer(
    cardId: cardId,
    currentState: states.current.deepCopy(),
    newState: selectedState.deepCopy()..customData = customData,
    rating: rating,
    answeredAtMillis: answeredAtMillis,
    millisecondsTaken: millisecondsTaken,
  );
}

proto.SchedulingState _requireOutcome(
  bool present,
  proto.SchedulingState state,
  String name,
) {
  if (!present) {
    throw ArgumentError.value(
      name,
      'states',
      'state for selected rating is required',
    );
  }
  _requireWrappedState(state, name);
  return state;
}

void _requireWrappedState(proto.SchedulingState state, String name) {
  if (state.whichKind() == proto.SchedulingState_Kind.notSet) {
    throw ArgumentError.value(
      name,
      'states',
      'state must contain a normal or filtered wrapper',
    );
  }
}
