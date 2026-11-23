// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('add records a card and reports its note as a sibling', () {
    final day = LoadBalancerDay();
    final noteId = NoteId(42);

    day.add(CardId(1), noteId);

    expect(day.hasSibling(noteId), isTrue);
    expect(day.hasSibling(NoteId(43)), isFalse);
  });

  test('multiple cards for one note retain membership after one is removed',
      () {
    final day = LoadBalancerDay();
    final noteId = NoteId(42);
    day.add(CardId(1), noteId);
    day.add(CardId(2), noteId);

    day.remove(CardId(1));

    expect(day.hasSibling(noteId), isTrue);
  });

  test('removing the last card for a note removes its membership', () {
    final day = LoadBalancerDay();
    final noteId = NoteId(42);
    day.add(CardId(1), noteId);

    day.remove(CardId(1));

    expect(day.hasSibling(noteId), isFalse);
  });

  test('removing an absent card leaves all sibling memberships unchanged', () {
    final day = LoadBalancerDay();
    final noteId = NoteId(42);
    day.add(CardId(1), noteId);

    day.remove(CardId(2));

    expect(day.hasSibling(noteId), isTrue);
  });

  test('distinct notes retain independent membership and signed 64-bit IDs',
      () {
    final day = LoadBalancerDay();
    final firstNote = NoteId.parseInt('9007199254740992');
    final secondNote = NoteId.parseInt('9007199254740993');
    final firstCard = CardId.parseInt('9223372036854775807');
    final secondCard = CardId.parseInt('-9223372036854775808');
    day.add(firstCard, firstNote);
    day.add(secondCard, secondNote);

    day.remove(firstCard);

    expect(day.hasSibling(firstNote), isFalse);
    expect(day.hasSibling(secondNote), isTrue);
  });
}
