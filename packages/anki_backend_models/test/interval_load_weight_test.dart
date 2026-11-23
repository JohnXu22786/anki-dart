// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('zero reviews receive full weight regardless of candidate inputs', () {
    expect(
      calculateIntervalLoadWeight(
        const IntervalLoadCandidate(
          targetInterval: 365,
          reviewCount: 0,
          siblingModifier: 0.0,
          easyDaysModifier: 0.0001,
        ),
      ),
      1.0,
    );
  });

  // These are the float32-rounded results of the pinned Core expression.
  test('ordinary weights match Core interval weighting', () {
    expect(
      calculateIntervalLoadWeight(
        const IntervalLoadCandidate(targetInterval: 10, reviewCount: 5),
      ),
      0.000031420597224496305,
    );
    expect(
      calculateIntervalLoadWeight(
        const IntervalLoadCandidate(targetInterval: 30, reviewCount: 12),
      ),
      0.00000017717259481742076,
    );
  });

  test('sibling and easy-day modifiers multiply into the weight', () {
    expect(
      calculateIntervalLoadWeight(
        const IntervalLoadCandidate(
          targetInterval: 7,
          reviewCount: 3,
          siblingModifier: 0.5,
          easyDaysModifier: 0.25,
        ),
      ),
      0.000034340388083364815,
    );
  });

  test('integer inputs are narrowed to float32 before weighting', () {
    final exactFloat32Integer = calculateIntervalLoadWeight(
      const IntervalLoadCandidate(targetInterval: 16777216, reviewCount: 1),
    );
    final roundedFloat32Integer = calculateIntervalLoadWeight(
      const IntervalLoadCandidate(targetInterval: 16777217, reviewCount: 1),
    );
    final lastSafeReviewCount = calculateIntervalLoadWeight(
      const IntervalLoadCandidate(
          targetInterval: 1, reviewCount: 9007199254740991),
    );
    final firstBeyondSafeReviewCount = calculateIntervalLoadWeight(
      const IntervalLoadCandidate(
          targetInterval: 1, reviewCount: 9007199254740992),
    );

    expect(roundedFloat32Integer, exactFloat32Integer);
    expect(firstBeyondSafeReviewCount, lastSafeReviewCount);
  });

  test('rejects values outside Core and cross-platform integer ranges', () {
    expect(
      () => calculateIntervalLoadWeight(
        const IntervalLoadCandidate(targetInterval: 4294967296, reviewCount: 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateIntervalLoadWeight(
        const IntervalLoadCandidate(targetInterval: 1, reviewCount: -1),
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateIntervalLoadWeight(
        const IntervalLoadCandidate(
            targetInterval: 1, reviewCount: 18014398509481984),
      ),
      throwsArgumentError,
    );
  });
}
