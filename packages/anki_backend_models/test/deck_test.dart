// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:anki_backend_protocol/anki/decks.pb.dart' as deck_proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('Deck', () {
    test('normal deck defaults match Anki Core', () {
      final deck = Deck.newNormal();
      expect(deck.id, Int64.ZERO);
      expect(deck.name, '');
      expect(deck.common.studyCollapsed, isTrue);
      expect(deck.common.browserCollapsed, isTrue);
      expect(deck.configId, Int64.ONE);
      expect(
          (deck.kind as NormalDeckKind).value.hasDesiredRetention(), isFalse);
    });

    test('USN constructors use signed 32-bit storage width', () {
      expect(
        Deck(usn: 0x100000001, kind: NormalDeckKind(deck_proto.Deck_Normal()))
            .usn,
        1,
      );
      expect(
        DeckConfig(
          usn: 0x100000001,
          inner: config_proto.DeckConfig_Config(),
        ).usn,
        1,
      );
    });

    test(
        'normal deck round trip preserves signed IDs, common values and presence',
        () {
      final source = deck_proto.Deck(
        id: Int64(-2),
        name: 'Parent::Child',
        mtimeSecs: Int64(-3),
        usn: -4,
        common: deck_proto.Deck_Common(
          studyCollapsed: true,
          newStudied: -7,
          other: [0, 1, 255],
        ),
        normal: deck_proto.Deck_Normal(
          configId: Int64(-8),
          reviewLimit: 0,
          desiredRetention: 0.0,
        ),
      );

      final model = Deck.fromProto(source);
      final result = model.toProto();
      expect(result.writeToBuffer(), source.writeToBuffer());
      expect(model.configId, Int64(-8));
      expect((model.kind as NormalDeckKind).value.hasReviewLimit(), isTrue);
      expect(
          (model.kind as NormalDeckKind).value.hasDesiredRetention(), isTrue);
    });

    test('filtered deck payload round trips without normal-deck assumptions',
        () {
      final source = deck_proto.Deck(
        id: Int64(1),
        name: 'filtered',
        mtimeSecs: Int64(2),
        usn: 3,
        common: deck_proto.Deck_Common(studyCollapsed: true),
        filtered: deck_proto.Deck_Filtered(
          reschedule: true,
          searchTerms: [
            deck_proto.Deck_Filtered_SearchTerm(
              search: 'deck:one',
              limit: 20,
              order: deck_proto.Deck_Filtered_SearchTerm_Order.RANDOM,
            ),
          ],
          previewAgainSecs: 15,
        ),
      );
      final model = Deck.fromProto(source);
      expect(model.configId, isNull);
      expect(model.toProto().writeToBuffer(), source.writeToBuffer());
    });

    test('missing kind uses the source error message', () {
      expect(
        () => Deck.fromProto(deck_proto.Deck()),
        throwsA(isA<InvalidModelValue>()
            .having((e) => e.message, 'message', 'missing kind')),
      );
    });

    test('deck names normalize NFC components, controls and blank components',
        () {
      final value = deck_proto.Deck(
        name: '  Cafe\u0301  ::\u0000:: :::',
        normal: deck_proto.Deck_Normal(),
      );
      expect(Deck.fromProto(value).name, 'Café::blank::blank::blank');
    });

    test('effective desired retention falls back only when unset', () {
      final config = config_proto.DeckConfig_Config(desiredRetention: 0.91);
      final unset = Deck.newNormal();
      final overridden = Deck(
        kind: NormalDeckKind(
          deck_proto.Deck_Normal(desiredRetention: 0.88),
        ),
      );
      final filtered = Deck(
        kind: FilteredDeckKind(deck_proto.Deck_Filtered()),
      );
      expect(unset.effectiveDesiredRetention(config), 0.91);
      expect(overridden.effectiveDesiredRetention(config), 0.88);
      expect(filtered.effectiveDesiredRetention(config), 0.91);
    });
  });

  group('DeckConfig', () {
    test('defaults match Anki Core values', () {
      final value = DeckConfig.defaults();
      final config = value.inner;
      expect(value.id, Int64.ZERO);
      expect(config.learnSteps, [1, 10]);
      expect(config.relearnSteps, [10]);
      expect(config.easyDaysPercentages, List<double>.filled(7, 1));
      expect(config.newPerDay, 20);
      expect(config.reviewsPerDay, 200);
      expect(config.initialEase, 2.5);
      expect(config.maximumReviewInterval, 36500);
      expect(config.leechAction.value, 1);
      expect(config.leechThreshold, 8);
      expect(config.waitForAudio, isTrue);
      expect(config.desiredRetention, 0.9);
      expect(config.historicalRetention, 0.9);
    });

    test('round trip preserves all config fields and FSRS parameter precedence',
        () {
      final source = config_proto.DeckConfig(
        id: Int64(-1),
        name: 'custom',
        mtimeSecs: Int64(-2),
        usn: -3,
        config: config_proto.DeckConfig_Config(
          newPerDay: 42,
          fsrsParams4: [4],
          fsrsParams5: [5],
          fsrsParams6: [6, 60],
          other: [0, 128, 255],
        ),
      );
      final model = DeckConfig.fromProto(source);
      expect(model.toProto().writeToBuffer(), source.writeToBuffer());
      expect(model.fsrsParams, [6, 60]);
    });

    test('uses generated protobuf defaults when config is absent', () {
      final source = config_proto.DeckConfig(id: Int64(10));
      final model = DeckConfig.fromProto(source);
      expect(model.inner.newPerDay, 0);
      expect(model.inner.learnSteps, isEmpty);
      expect(model.toProto().hasConfig(), isTrue);
    });

    test('FSRS fallback selects the newest non-empty parameter set', () {
      final config = DeckConfig(
        inner:
            config_proto.DeckConfig_Config(fsrsParams4: [4], fsrsParams5: [5]),
      );
      expect(config.fsrsParams, [5]);
      final legacy = DeckConfig(
        inner: config_proto.DeckConfig_Config(fsrsParams4: [4]),
      );
      expect(legacy.fsrsParams, [4]);
      expect(DeckConfig.defaults().fsrsParams, isEmpty);
    });
  });
}
