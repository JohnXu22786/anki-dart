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
        initialEase: 2.35,
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
    expect(context.initialEaseFactor, deckConfig.inner.initialEase);
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

  test('defaults initial ease for contexts without a deck config', () {
    expect(const ReviewSchedulingContext().initialEaseFactor, 2.5);
    expect(
      const ReviewSchedulingContext(initialEaseFactor: 2.6)
          .withFuzzFactor(0.25)
          .initialEaseFactor,
      2.6,
    );
  });

  test('copies only precomputed FSRS next states', () {
    final resolver = (double interval, int minimum, int maximum) => maximum;
    final memory = FsrsMemoryState(stability: 3, difficulty: 5);
    final originalStates = FsrsReviewNextStates(
      again: FsrsReviewNextState(interval: 1, memoryState: memory),
      hard: FsrsReviewNextState(interval: 2, memoryState: memory),
      good: FsrsReviewNextState(interval: 3, memoryState: memory),
      easy: FsrsReviewNextState(interval: 4, memoryState: memory),
    );
    final replacementStates = FsrsReviewNextStates(
      again: FsrsReviewNextState(interval: 5, memoryState: memory),
      hard: FsrsReviewNextState(interval: 6, memoryState: memory),
      good: FsrsReviewNextState(interval: 7, memoryState: memory),
      easy: FsrsReviewNextState(interval: 8, memoryState: memory),
    );
    final params = List<double>.filled(21, 0.25);
    final context = ReviewSchedulingContext(
      hardMultiplier: 1.1,
      easyMultiplier: 1.7,
      intervalMultiplier: 1.3,
      maximumReviewInterval: 900,
      leechThreshold: 9,
      lapseMultiplier: 0.4,
      minimumLapseInterval: 3,
      fuzzFactor: 0.42,
      loadBalancedIntervalResolver: resolver,
      fsrsNextStates: originalStates,
      fsrsParams: params,
      fsrsDesiredRetention: 0.87,
      relearningAgainDelaySecs: 77,
      relearningRemainingSteps: 2,
      fsrsAllowShortTerm: true,
      fsrsShortTermWithStepsEnabled: true,
      relearningStepsEmpty: false,
      learningStepsMinutes: [1, 2],
      relearningStepsMinutes: [3],
      graduatingIntervalGood: 4,
      graduatingIntervalEasy: 5,
    );

    final copy = context.withFsrsNextStates(replacementStates);

    expect(copy.fsrsNextStates, same(replacementStates));
    expect(context.fsrsNextStates, same(originalStates));
    expect(copy.hardMultiplier, context.hardMultiplier);
    expect(copy.easyMultiplier, context.easyMultiplier);
    expect(copy.intervalMultiplier, context.intervalMultiplier);
    expect(copy.maximumReviewInterval, context.maximumReviewInterval);
    expect(copy.leechThreshold, context.leechThreshold);
    expect(copy.lapseMultiplier, context.lapseMultiplier);
    expect(copy.minimumLapseInterval, context.minimumLapseInterval);
    expect(copy.fuzzFactor, context.fuzzFactor);
    expect(copy.loadBalancedIntervalResolver, same(resolver));
    expect(copy.fsrsParams, same(params));
    expect(copy.fsrsDesiredRetention, context.fsrsDesiredRetention);
    expect(copy.relearningAgainDelaySecs, context.relearningAgainDelaySecs);
    expect(copy.relearningRemainingSteps, context.relearningRemainingSteps);
    expect(copy.fsrsAllowShortTerm, context.fsrsAllowShortTerm);
    expect(
      copy.fsrsShortTermWithStepsEnabled,
      context.fsrsShortTermWithStepsEnabled,
    );
    expect(copy.relearningStepsEmpty, context.relearningStepsEmpty);
    expect(copy.learningStepsMinutes, same(context.learningStepsMinutes));
    expect(copy.relearningStepsMinutes, same(context.relearningStepsMinutes));
    expect(copy.graduatingIntervalGood, context.graduatingIntervalGood);
    expect(copy.graduatingIntervalEasy, context.graduatingIntervalEasy);
  });

  test('copies only FSRS short-term scheduler settings', () {
    final resolver = (double interval, int minimum, int maximum) => maximum;
    final memory = FsrsMemoryState(stability: 3, difficulty: 5);
    final fsrs = FsrsReviewNextStates(
      again: FsrsReviewNextState(interval: 0.1, memoryState: memory),
      hard: FsrsReviewNextState(interval: 2, memoryState: memory),
      good: FsrsReviewNextState(interval: 3, memoryState: memory),
      easy: FsrsReviewNextState(interval: 4, memoryState: memory),
    );
    final params = List<double>.filled(21, 0.25);
    final context = ReviewSchedulingContext(
      hardMultiplier: 1.1,
      easyMultiplier: 1.7,
      intervalMultiplier: 1.3,
      maximumReviewInterval: 900,
      leechThreshold: 9,
      lapseMultiplier: 0.4,
      minimumLapseInterval: 3,
      fuzzFactor: 0.42,
      loadBalancedIntervalResolver: resolver,
      fsrsNextStates: fsrs,
      fsrsParams: params,
      fsrsDesiredRetention: 0.87,
      relearningAgainDelaySecs: 77,
      relearningRemainingSteps: 2,
      fsrsAllowShortTerm: false,
      fsrsShortTermWithStepsEnabled: false,
      relearningStepsEmpty: false,
      learningStepsMinutes: [1, 2],
      relearningStepsMinutes: [3],
      graduatingIntervalGood: 4,
      graduatingIntervalEasy: 5,
    );

    final copy = context.withFsrsShortTermSettings(
      allowShortTerm: true,
      shortTermWithStepsEnabled: true,
    );

    expect(copy.fsrsAllowShortTerm, isTrue);
    expect(copy.fsrsShortTermWithStepsEnabled, isTrue);
    expect(context.fsrsAllowShortTerm, isFalse);
    expect(context.fsrsShortTermWithStepsEnabled, isFalse);
    expect(copy.hardMultiplier, context.hardMultiplier);
    expect(copy.easyMultiplier, context.easyMultiplier);
    expect(copy.intervalMultiplier, context.intervalMultiplier);
    expect(copy.maximumReviewInterval, context.maximumReviewInterval);
    expect(copy.leechThreshold, context.leechThreshold);
    expect(copy.lapseMultiplier, context.lapseMultiplier);
    expect(copy.minimumLapseInterval, context.minimumLapseInterval);
    expect(copy.fuzzFactor, context.fuzzFactor);
    expect(copy.loadBalancedIntervalResolver, same(resolver));
    expect(copy.fsrsNextStates, same(fsrs));
    expect(copy.fsrsParams, same(params));
    expect(copy.fsrsDesiredRetention, context.fsrsDesiredRetention);
    expect(copy.relearningAgainDelaySecs, context.relearningAgainDelaySecs);
    expect(copy.relearningRemainingSteps, context.relearningRemainingSteps);
    expect(copy.relearningStepsEmpty, context.relearningStepsEmpty);
    expect(copy.learningStepsMinutes, same(context.learningStepsMinutes));
    expect(copy.relearningStepsMinutes, same(context.relearningStepsMinutes));
    expect(copy.graduatingIntervalGood, context.graduatingIntervalGood);
    expect(copy.graduatingIntervalEasy, context.graduatingIntervalEasy);
  });
}
