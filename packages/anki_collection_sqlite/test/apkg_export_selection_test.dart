// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  const large = '9007199254740997';
  final noteA = Int64.parseInt(large);
  final noteB = Int64.parseInt('9007199254741011');
  final cardA = Int64.parseInt('9007199254741033');
  final cardB = Int64.parseInt('9007199254741051');
  final cardC = Int64.parseInt('9007199254741069');
  final cardD = Int64.parseInt('9007199254741087');
  final cards = [
    ApkgCardReference(id: cardA, noteId: noteA, deckId: Int64.ONE),
    ApkgCardReference(id: cardB, noteId: noteA, deckId: Int64.ONE),
    ApkgCardReference(id: cardC, noteId: noteB, deckId: Int64.ONE),
    ApkgCardReference(id: cardD, noteId: noteB, deckId: Int64.ONE),
  ];

  test('card limit gathers all cards of the selected notes with exact IDs', () {
    final selection = resolveApkgSelection(
      notes: [noteA, noteB],
      cards: cards,
      limit: ApkgExportLimit(cardIds: [cardA]),
    );

    expect(selection.noteIds, [noteA]);
    expect(selection.cardIds, [cardA, cardB]);
    expect(selection.noteIds.single, Int64.parseInt(large));
  });

  test('note limit includes only its note and every associated card', () {
    final selection = resolveApkgSelection(
      notes: [noteA, noteB],
      cards: cards,
      limit: ApkgExportLimit(noteIds: [noteB]),
    );

    expect(selection.noteIds, [noteB]);
    expect(selection.cardIds, [cardC, cardD]);
  });

  test('deck ID limit includes every card belonging to notes in that deck', () {
    final selection = resolveApkgSelection(
      notes: [noteA, noteB],
      cards: [
        cards[0],
        cards[1],
        ApkgCardReference(id: cardC, noteId: noteB, deckId: Int64(2)),
        ApkgCardReference(id: cardD, noteId: noteB, deckId: Int64(2)),
        ApkgCardReference(
          id: Int64.parseInt('9007199254741099'),
          noteId: noteA,
          deckId: Int64(2),
        ),
      ],
      limit: ApkgExportLimit(deckId: Int64.ONE),
    );

    expect(selection.noteIds, [noteA]);
    expect(selection.cardIds, [
      cardA,
      cardB,
      Int64.parseInt('9007199254741099'),
    ]);
  });

  test('invalid or ambiguous limits fail closed', () {
    expect(
      () => resolveApkgSelection(
        notes: [noteA, noteB],
        cards: cards,
        limit: ApkgExportLimit(noteIds: [Int64.parseInt('9007199254741999')]),
      ),
      throwsArgumentError,
    );
    expect(
      () => resolveApkgSelection(
        notes: [noteA, noteB],
        cards: cards,
        limit: ApkgExportLimit(noteIds: [noteA], cardIds: [cardA]),
      ),
      throwsArgumentError,
    );
  });
}
