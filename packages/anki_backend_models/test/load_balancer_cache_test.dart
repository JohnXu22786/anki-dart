// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('LoadBalancerCache.fromHistory', () {
    test('groups cards by config and day and projects every config', () {
      final configA = Int64(10);
      final configB = Int64(20);
      final history = _emptyHistory();
      history[2].addAll([
        (Int64(1), Int64(100), Int64(7)),
        (Int64(2), Int64(100), Int64(8)),
        (Int64(3), Int64(200), Int64(9)),
        (Int64(4), Int64(100), Int64(999)), // unmapped deck is skipped
      ]);
      history[98].add((Int64(5), Int64(300), Int64(7)));

      final cache = LoadBalancerCache.fromHistory(
        cardsByDay: history,
        deckConfigByDeck: {
          Int64(7): configA,
          Int64(8): configA,
          Int64(9): configB,
        },
        configs: {
          configA: DeckConfig.defaults(),
          configB: DeckConfig.defaults(),
          Int64(30): DeckConfig.defaults(),
        },
      );

      expect(cache.daysByPreset.keys, containsAll([configA, configB]));
      expect(cache.daysByPreset, isNot(contains(Int64(30))));
      expect(cache.daysByPreset[configA], hasLength(99));
      expect(cache.daysByPreset[configA]![2].cardCount, 2);
      expect(cache.daysByPreset[configA]![2].hasSibling(Int64(100)), isTrue);
      expect(cache.daysByPreset[configA]![98].cardCount, 1);
      expect(cache.daysByPreset[configB]![2].cardCount, 1);
      expect(
        cache.easyDaysByPreset.keys,
        containsAll([configA, configB, Int64(30)]),
      );
      expect(cache.easyDaysByPreset[configA], everyElement(EasyDay.normal));
    });

    test('keeps empty history while parsing configs', () {
      final cache = LoadBalancerCache.fromHistory(
        cardsByDay: _emptyHistory(),
        deckConfigByDeck: const {},
        configs: {Int64(1): DeckConfig.defaults()},
      );

      expect(cache.daysByPreset, isEmpty);
      expect(cache.easyDaysByPreset[Int64(1)], hasLength(7));
    });

    test('rejects a history window other than 99 days', () {
      expect(
        () => LoadBalancerCache.fromHistory(
          cardsByDay: _emptyHistory()..removeLast(),
          deckConfigByDeck: const {},
          configs: const {},
        ),
        throwsArgumentError,
      );
    });

    test('generated cache feeds interval decision unchanged', () {
      final preset = Int64(10);
      final history = _emptyHistory();
      history[0].add((Int64(1), Int64(2), Int64(7)));
      final cache = LoadBalancerCache.fromHistory(
        cardsByDay: history,
        deckConfigByDeck: {Int64(7): preset},
        configs: {preset: DeckConfig.defaults()},
      );

      expect(
        findLoadBalancedInterval(
          daysByPreset: cache.daysByPreset,
          easyDaysByPreset: cache.easyDaysByPreset,
          nextDayAt: Int64(0),
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        6,
      );
    });

    test('addCard updates only known presets and cached days', () {
      final preset = Int64(10);
      final cache = _cacheWithOneCard(preset);

      cache.addCard(Int64(2), Int64(20), preset, 98);
      cache.addCard(Int64(3), Int64(30), Int64(999), 2);
      cache.addCard(Int64(4), Int64(40), preset, 99);
      cache.addCard(Int64(5), Int64(50), preset, -1);

      expect(cache.daysByPreset[preset]![98].cardCount, 1);
      expect(cache.daysByPreset[preset]![98].hasSibling(Int64(20)), isTrue);
      expect(cache.daysByPreset.containsKey(Int64(999)), isFalse);
      expect(cache.daysByPreset[preset]![2].cardCount, 0);
    });

    test(
      'removeCard searches every preset and day and retains shared notes',
      () {
        final presetA = Int64(10);
        final presetB = Int64(20);
        final history = _emptyHistory();
        history[5].addAll([
          (Int64(1), Int64(100), Int64(7)),
          (Int64(2), Int64(100), Int64(7)),
        ]);
        history[6].add((Int64(1), Int64(200), Int64(7)));
        history[5].add((Int64(1), Int64(300), Int64(8)));
        final cache = LoadBalancerCache.fromHistory(
          cardsByDay: history,
          deckConfigByDeck: {Int64(7): presetA, Int64(8): presetB},
          configs: {
            presetA: DeckConfig.defaults(),
            presetB: DeckConfig.defaults(),
          },
        );

        cache.removeCard(Int64(1));

        expect(cache.daysByPreset[presetA]![5].cardCount, 1);
        expect(cache.daysByPreset[presetA]![5].hasSibling(Int64(100)), isTrue);
        expect(cache.daysByPreset[presetA]![6].cardCount, 0);
        expect(cache.daysByPreset[presetA]![6].hasSibling(Int64(200)), isFalse);
        expect(cache.daysByPreset[presetB]![5].cardCount, 0);
        expect(cache.daysByPreset[presetB]![5].hasSibling(Int64(300)), isFalse);
      },
    );

    test('removeCard removes only one match in each day bucket', () {
      final preset = Int64(10);
      final history = _emptyHistory();
      history[4].addAll([
        (Int64(1), Int64(100), Int64(7)),
        (Int64(1), Int64(200), Int64(7)),
      ]);
      final cache = LoadBalancerCache.fromHistory(
        cardsByDay: history,
        deckConfigByDeck: {Int64(7): preset},
        configs: {preset: DeckConfig.defaults()},
      );

      cache.removeCard(Int64(1));

      expect(cache.daysByPreset[preset]![4].cardCount, 1);
      expect(cache.daysByPreset[preset]![4].hasSibling(Int64(100)), isFalse);
      expect(cache.daysByPreset[preset]![4].hasSibling(Int64(200)), isTrue);
    });
  });
}

List<List<LoadBalancerHistoryCard>> _emptyHistory() =>
    List<List<LoadBalancerHistoryCard>>.generate(99, (_) => []);

LoadBalancerCache _cacheWithOneCard(DeckConfigId preset) {
  final history = _emptyHistory();
  history[1].add((Int64(1), Int64(10), Int64(7)));
  return LoadBalancerCache.fromHistory(
    cardsByDay: history,
    deckConfigByDeck: {Int64(7): preset},
    configs: {preset: DeckConfig.defaults()},
  );
}
