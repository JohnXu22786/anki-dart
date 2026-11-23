// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as proto;
import 'package:test/test.dart';

void main() {
  test('projects normalized review and learning settings from deck config', () {
    final deckConfig = DeckConfig(
      inner: proto.DeckConfig_Config(
        hardMultiplier: 1.17,
        easyMultiplier: 1.61,
        intervalMultiplier: 1.22,
        maximumReviewInterval: 24000,
        leechThreshold: 11,
        lapseMultiplier: 0.35,
        minimumLapseInterval: 3,
        learnSteps: [1.25, 8.5],
        relearnSteps: [4.75],
        graduatingIntervalGood: 2,
        graduatingIntervalEasy: 6,
      ),
    );

    final context = const ReviewSchedulingContext().withDeckConfig(deckConfig);

    expect(context.hardMultiplier, deckConfig.inner.hardMultiplier);
    expect(context.easyMultiplier, deckConfig.inner.easyMultiplier);
    expect(context.intervalMultiplier, deckConfig.inner.intervalMultiplier);
    expect(
      context.maximumReviewInterval,
      deckConfig.inner.maximumReviewInterval,
    );
    expect(context.leechThreshold, deckConfig.inner.leechThreshold);
    expect(context.lapseMultiplier, deckConfig.inner.lapseMultiplier);
    expect(context.minimumLapseInterval, deckConfig.inner.minimumLapseInterval);
    expect(context.learningStepsMinutes, [1.25, 8.5]);
    expect(context.relearningStepsMinutes, [4.75]);
    expect(context.relearningStepsEmpty, isFalse);
    expect(context.graduatingIntervalGood, 2);
    expect(context.graduatingIntervalEasy, 6);
  });

  test('preserves normalized protobuf values and detaches step lists', () {
    final deckConfig = DeckConfig(
      inner: proto.DeckConfig_Config(
        maximumReviewInterval: 36500,
        minimumLapseInterval: 1,
        leechThreshold: 9999,
        learnSteps: [1.23456789],
        relearnSteps: [],
      ),
    );
    final config = deckConfig.inner;
    final normalizedStep = config.learnSteps.first;

    final context = const ReviewSchedulingContext().withDeckConfig(deckConfig);
    config.learnSteps[0] = 99;
    config.relearnSteps.add(2);

    expect(context.maximumReviewInterval, 36500);
    expect(context.minimumLapseInterval, 1);
    expect(context.leechThreshold, 9999);
    expect(context.learningStepsMinutes, [normalizedStep]);
    expect(context.relearningStepsMinutes, isEmpty);
    expect(context.relearningStepsEmpty, isTrue);
  });

  test('preserves caller-owned dynamic and non-config context inputs', () {
    final resolver = (double interval, int minimum, int maximum) => maximum;
    final memory = FsrsMemoryState(stability: 3, difficulty: 5);
    final fsrs = FsrsReviewNextStates(
      again: FsrsReviewNextState(interval: 1, memoryState: memory),
      hard: FsrsReviewNextState(interval: 2, memoryState: memory),
      good: FsrsReviewNextState(interval: 3, memoryState: memory),
      easy: FsrsReviewNextState(interval: 4, memoryState: memory),
    );
    final params = List<double>.filled(21, 0.25);
    final base = ReviewSchedulingContext(
      fuzzFactor: 0.42,
      loadBalancedIntervalResolver: resolver,
      fsrsNextStates: fsrs,
      fsrsParams: params,
      fsrsDesiredRetention: 0.87,
      relearningAgainDelaySecs: 77,
      relearningRemainingSteps: 2,
      fsrsAllowShortTerm: true,
      fsrsShortTermWithStepsEnabled: true,
    );
    final deckConfig = DeckConfig(
      inner: proto.DeckConfig_Config(
        hardMultiplier: 1.1,
        easyMultiplier: 1.2,
        intervalMultiplier: 1.3,
      ),
    );

    final context = base.withDeckConfig(deckConfig);

    expect(context.fuzzFactor, base.fuzzFactor);
    expect(context.loadBalancedIntervalResolver, same(resolver));
    expect(context.fsrsNextStates, same(fsrs));
    expect(context.fsrsParams, same(params));
    expect(context.fsrsDesiredRetention, base.fsrsDesiredRetention);
    expect(context.relearningAgainDelaySecs, base.relearningAgainDelaySecs);
    expect(context.relearningRemainingSteps, base.relearningRemainingSteps);
    expect(context.fsrsAllowShortTerm, base.fsrsAllowShortTerm);
    expect(
      context.fsrsShortTermWithStepsEnabled,
      base.fsrsShortTermWithStepsEnabled,
    );
  });
}
