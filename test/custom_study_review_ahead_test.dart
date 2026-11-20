/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CustomStudyDialogTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  test('Review Ahead search scopes due-within-days to an exact deck name', () {
    expect(
      buildReviewAheadSearch(deckName: 'A_B', days: 3),
      r'deck:A\_B prop:due<=3',
    );
  });

  test('availability excludes ineligible cards before enabling Create', () {
    expect(
      buildReviewAheadAvailabilitySearch(deckName: 'A_B', days: 3),
      r'deck:A\_B prop:due<=3 -is:suspended -is:buried -deck:filtered',
    );
  });

  test('Review Ahead accepts only positive five digit day counts', () {
    expect(() => validateReviewAheadDays(0), throwsArgumentError);
    expect(() => validateReviewAheadDays(100000), throwsRangeError);
    expect(() => validateReviewAheadDays(1), returnsNormally);
    expect(() => validateReviewAheadDays(99999), returnsNormally);
  });

  test('filtered session search uses the Core Review Ahead term order', () {
    expect(
      buildReviewAheadFilteredSearch(deckName: 'A_B', days: 3),
      r'prop:due<=3 deck:A\_B',
    );
  });
}
