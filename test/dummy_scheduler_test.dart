import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('DummyScheduler', () {
    test('retains the exact collection reference in col', () {
      final collection = <String, Object>{'marker': Object()};
      final scheduler = DummyScheduler<Object, Object, Object>(collection);

      expect(identical(scheduler.col, collection), isTrue);
    });

    test('card is always null', () {
      final scheduler = DummyScheduler<Object, Object, Object>(Object());

      expect(scheduler.card, isNull);
    });

    test('answerCard always throws the source Exception and message', () {
      final scheduler = DummyScheduler<Object, Object, Object>(Object());
      final expectedType = Exception(
        'v1/v2 scheduler not supported',
      ).runtimeType;

      for (final (card, rating) in <(Object, Object)>[
        (Object(), Object()),
        ('opaque card', 17),
        (const <int>[1, 2], const <String>{'rating'}),
      ]) {
        expect(
          () => scheduler.answerCard(card, rating),
          throwsA(
            predicate(
              (error) =>
                  error.runtimeType == expectedType &&
                  error.toString() ==
                      'Exception: v1/v2 scheduler not supported',
            ),
          ),
        );
      }
    });
  });
}
