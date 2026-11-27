// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

const _defaults = <double>[
  0.212,
  1.2931,
  2.3065,
  8.2956,
  6.4133,
  0.8334,
  3.0194,
  0.001,
  1.8722,
  0.1666,
  0.796,
  1.4835,
  0.0614,
  0.2629,
  1.6483,
  0.6014,
  1.8729,
  0.5425,
  0.0912,
  0.0658,
  0.1542,
];

void main() {
  group('initializeFsrsTrainingModelParameters', () {
    test('returns the pinned 21 default parameters including decay', () {
      final result = initializeFsrsTrainingModelParameters(
        freezeShortTermStability: false,
      );

      expect(result, Float32List.fromList(_defaults));
      expect(result, hasLength(21));
      expect(result[20], Float32List.fromList([0.1542]).first);
    });

    test('replaces only the first four defaults from an override', () {
      const initialStability = [0.5, 1.5, 2.5, 3.5];
      final result = initializeFsrsTrainingModelParameters(
        initialStability: initialStability,
        freezeShortTermStability: false,
      );

      expect(result.take(4), initialStability);
      expect(result.skip(4), Float32List.fromList(_defaults).skip(4));
    });

    test('freezes only indexes 17 through 19 with and without override', () {
      for (final initialStability in <List<double>?>[
        null,
        [0.5, 1.5, 2.5, 3.5],
      ]) {
        final result = initializeFsrsTrainingModelParameters(
          initialStability: initialStability,
          freezeShortTermStability: true,
        );
        final expected = Float32List.fromList(_defaults);
        if (initialStability != null) {
          for (var index = 0; index < 4; index++) {
            expected[index] = initialStability[index];
          }
        }
        expected[17] = 0;
        expected[18] = 0;
        expected[19] = 0;

        expect(result, expected);
        expect(result[16], expected[16]);
        expect(result[20], expected[20]);
      }
    });

    test('returns an immutable Float32 snapshot without changing the input',
        () {
      final input = [1.00000006, 2.00000006, 3.00000006, 4.00000006];
      final before = List<double>.of(input);
      final result = initializeFsrsTrainingModelParameters(
        initialStability: input,
        freezeShortTermStability: false,
      );

      expect(result.take(4), Float32List.fromList(input));
      expect(input, before);
      expect(result, isNot(same(input)));
      expect(() => result[0] = 42, throwsUnsupportedError);
    });

    test('rejects overrides whose length is not four', () {
      for (final length in [0, 3, 5]) {
        expect(
          () => initializeFsrsTrainingModelParameters(
            initialStability: List<double>.filled(length, 1),
            freezeShortTermStability: false,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
