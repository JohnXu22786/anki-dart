// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('resolveCurrentLearningStepDelaySecs', () {
    test('indexes the current step from remaining steps', () {
      const steps = [1.0, 10.0, 20.0];

      expect(
        resolveCurrentLearningStepDelaySecs(steps: steps, remainingSteps: 1),
        1200,
      );
      expect(
        resolveCurrentLearningStepDelaySecs(steps: steps, remainingSteps: 2),
        600,
      );
      expect(
        resolveCurrentLearningStepDelaySecs(steps: steps, remainingSteps: 3),
        60,
      );
      expect(
        resolveCurrentLearningStepDelaySecs(steps: steps, remainingSteps: 4),
        60,
      );
    });

    test('wraps remaining step counts modulo 1000', () {
      expect(
        resolveCurrentLearningStepDelaySecs(
          steps: [1.0, 10.0, 20.0],
          remainingSteps: 1002,
        ),
        600,
      );
    });

    test('uses Core f32 multiplication before casting to seconds', () {
      // The f32 minute value becomes 1.000000119...; multiplying in f32
      // rounds to 60.0000076..., which Core truncates to 60 seconds.
      expect(
        resolveCurrentLearningStepDelaySecs(
          steps: [1.0000001],
          remainingSteps: 0,
        ),
        60,
      );
      expect(
        resolveCurrentLearningStepDelaySecs(
          steps: [0.016666668],
          remainingSteps: 0,
        ),
        1,
      );
    });

    test('returns zero when there are no configured steps', () {
      expect(
        resolveCurrentLearningStepDelaySecs(steps: const [], remainingSteps: 1),
        0,
      );
    });
  });
}
