// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('FsrsCosineAnnealingLr', () {
    test('matches the pinned FSRS 5.2.0 eleven-step fixture', () {
      final scheduler = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      );
      const expected = [
        0.04,
        0.03618033988749895,
        0.026180339887498946,
        0.013819660112501051,
        0.0038196601125010526,
        0.0,
        0.003819660112501051,
        0.013819660112501048,
        0.026180339887498943,
        0.03618033988749895,
        0.039999999999999994,
      ];

      for (final expectedRate in expected) {
        expect(scheduler.step(), closeTo(expectedRate, 1e-15));
      }
    });

    test('starts at step minus one and returns the initial rate first', () {
      final scheduler = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      );

      expect(scheduler.stepCount, -1);
      expect(scheduler.currentLearningRate, 0.04);
      expect(scheduler.step(), 0.04);
      expect(scheduler.stepCount, 0);
    });

    test('uses the cosine restart branch at the period boundary', () {
      final scheduler = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      );
      for (var i = 0; i < 7; i++) {
        scheduler.step();
      }

      expect(scheduler.stepCount, 6);
      expect(
          scheduler.currentLearningRate, closeTo(0.003819660112501051, 1e-15));
    });

    test('serializes a nonnegative record and loads only the step count', () {
      final scheduler = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      );
      expect(scheduler.toRecord(), 0);
      scheduler.step();
      expect(scheduler.toRecord(), 0);
      scheduler.step();
      expect(scheduler.toRecord(), 1);

      final restored = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      )..loadRecord(5);
      expect(restored.stepCount, 5);
      expect(restored.currentLearningRate, 0.04);
      expect(restored.step(), closeTo(0.0038196601125010526, 1e-15));
      expect(restored.toRecord(), 6);
    });

    test('rejects invalid schedule scalars', () {
      for (final tMax in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => FsrsCosineAnnealingLr(
            tMax: tMax,
            initialLearningRate: 0.04,
          ),
          throwsArgumentError,
        );
      }
      for (final learningRate in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => FsrsCosineAnnealingLr(
            tMax: 5,
            initialLearningRate: learningRate,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects negative or non-integer records', () {
      final scheduler = FsrsCosineAnnealingLr(
        tMax: 5,
        initialLearningRate: 0.04,
      );
      for (final record in [-1, 1.5, double.nan, double.infinity, '1']) {
        expect(() => scheduler.loadRecord(record), throwsArgumentError);
      }
    });
  });
}
