/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/custom_study_forgotten_cards_request.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forgotten request creates a non-rescheduling random study session', () {
    final id = Int64.parseInt('9007199254740995');
    final request = forgottenCardsFilteredDeckRequest(
      existingSessionId: id,
      deckName: 'Biology',
      days: 3,
    );

    expect(request.id, id);
    expect(request.name, 'Custom Study Session');
    expect(request.allowEmpty, isFalse);
    expect(request.config.reschedule, isFalse);
    expect(request.config.searchTerms.single.search, 'rated:3:1 deck:Biology');
    expect(request.config.searchTerms.single.limit, 99999);
    expect(
      request.config.searchTerms.single.order,
      deck_proto.Deck_Filtered_SearchTerm_Order.RANDOM,
    );
  });
}
