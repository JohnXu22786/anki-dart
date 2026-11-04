import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Card equality and hash code', () {
    test('compares distinct Card objects by their IDs', () {
      final first = _HostCard(42);
      final sameId = _HostCard(42);
      final differentId = _HostCard(43);
      final reads = <Object>[];

      bool isCard(Object? value) => value is _HostCard;
      int cardId(Object value) {
        reads.add(value);
        return (value as _HostCard).id;
      }

      expect(
        libankiCardEquals(first, sameId, isCard: isCard, cardId: cardId),
        isTrue,
      );
      expect(
        libankiCardEquals(first, differentId, isCard: isCard, cardId: cardId),
        isFalse,
      );
      expect(reads, [first, sameId, first, differentId]);
    });

    test('uses reference identity for non-Cards without reading IDs', () {
      final first = Object();
      final other = Object();
      var idReads = 0;

      bool isCard(Object? value) => value is _HostCard;
      int cardId(Object value) {
        idReads++;
        return (value as _HostCard).id;
      }

      expect(
        libankiCardEquals(first, first, isCard: isCard, cardId: cardId),
        isTrue,
      );
      expect(
        libankiCardEquals(first, other, isCard: isCard, cardId: cardId),
        isFalse,
      );
      expect(
        libankiCardEquals(first, null, isCard: isCard, cardId: cardId),
        isFalse,
      );
      expect(idReads, 0);
    });

    test('folds signed Long IDs to the JVM signed 32-bit hash', () {
      for (final (id, expected) in <(int, int)>[
        (0, 0),
        (0x7fffffff, 0x7fffffff),
        (0x100000001, 0),
        (0x7fffffff00000001, 0x7ffffffe),
        (-1, 0),
        (-0x100000001, 1),
        (-0x8000000000000000, -0x80000000),
      ]) {
        expect(libankiCardHashCode(id), expected, reason: 'ID $id');
      }
    });
  });
}

final class _HostCard {
  const _HostCard(this.id);

  final int id;
}
