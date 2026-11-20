/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/custom_study_review_ahead_request.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Review Ahead request matches Core filtered session settings', () {
    final id = Int64.parseInt('9007199254740995');
    final request = reviewAheadFilteredDeckRequest(
      existingSessionId: id,
      deckName: 'Biology',
      days: 7,
    );

    expect(request.id, id);
    expect(request.name, 'Custom Study Session');
    expect(request.allowEmpty, isFalse);
    expect(request.config.reschedule, isTrue);
    expect(
      request.config.searchTerms.single.search,
      'prop:due<=7 deck:Biology',
    );
    expect(request.config.searchTerms.single.limit, 99999);
    expect(
      request.config.searchTerms.single.order,
      deck_proto.Deck_Filtered_SearchTerm_Order.DUE,
    );
  });
}
