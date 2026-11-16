// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:anki_collection_sqlite/src/deck_tree.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('buildCoreDeckTree', () {
    test('builds nested hierarchy with Core source traversal ordering', () {
      final tree = buildCoreDeckTree(
        decksInNameOrder: [
          _deck(1, 'Default'),
          _deck(2, 'Languages'),
          _deck(3, 'Languages::Spanish'),
          _deck(4, 'Languages::Spanish::Verbs'),
          _deck(5, 'Missing::Parent::Child'),
        ],
        dueCountsByDeck: const {},
        deckConfigs: const {},
        today: 10,
      );

      expect(tree.children.map((node) => node.name), ['Languages']);
      expect(tree.children.single.children.single.name, 'Spanish');
      final spanish = tree.children.single.children.single;
      expect(spanish.children.map((node) => node.name), ['Verbs', 'Child']);
    });

    test('hides an empty default deck except when it is the only deck', () {
      final hidden = buildCoreDeckTree(
        decksInNameOrder: [_deck(1, 'Default'), _deck(2, 'Other')],
        dueCountsByDeck: const {},
        deckConfigs: const {},
        today: 0,
      );
      expect(hidden.children.map((node) => node.name), ['Other']);

      final sole = buildCoreDeckTree(
        decksInNameOrder: [_deck(1, 'Default')],
        dueCountsByDeck: const {},
        deckConfigs: const {},
        today: 0,
      );
      expect(sole.children.single.name, 'Default');
    });

    test(
      'uses browser collapse, filtered flags, due counts, and daily limits',
      () {
        final parent = _deck(
          2,
          'Parent',
          common: deck_proto.Deck_Common(
            studyCollapsed: false,
            browserCollapsed: true,
          ),
        );
        final child = _deck(
          3,
          'Parent::Filtered',
          kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
        );
        final tree = buildCoreDeckTree(
          decksInNameOrder: [_deck(1, 'Default'), parent, child],
          dueCountsByDeck: {
            Int64(3): deck_proto.DeckTreeNode(
              deckId: Int64(3),
              newCount: 7,
              reviewCount: 8,
              newUncapped: 7,
              reviewUncapped: 8,
              intradayLearning: 2,
              interdayLearningUncapped: 3,
              totalInDeck: 20,
            ),
          },
          deckConfigs: {
            Int64.ONE: DeckConfig(
              id: Int64.ONE,
              inner: config_proto.DeckConfig_Config(
                newPerDay: 5,
                reviewsPerDay: 6,
              ),
            ),
          },
          today: 10,
          browser: true,
          newCardsIgnoreReviewLimit: true,
        );

        final parentNode = tree.children.firstWhere((node) => node.deckId == 2);
        final filteredNode = parentNode.children.single;
        expect(filteredNode.deckId, Int64(3));
        expect(parentNode.collapsed, isTrue);
        expect(filteredNode.filtered, isTrue);
        expect(filteredNode.newUncapped, 7);
        expect(filteredNode.reviewUncapped, 8);
        expect(filteredNode.newCount, 7);
        expect(filteredNode.reviewCount, 8);
        expect(filteredNode.learnCount, 5);
        expect(filteredNode.totalIncludingChildren, 20);
        expect(parentNode.newCount, 5);
        expect(parentNode.reviewCount, 3);
      },
    );
  });
}

Deck _deck(
  int id,
  String name, {
  deck_proto.Deck_Common? common,
  DeckKind? kind,
}) => Deck(
  id: Int64(id),
  name: name,
  common: common,
  kind: kind ?? NormalDeckKind(deck_proto.Deck_Normal(configId: Int64.ONE)),
);
