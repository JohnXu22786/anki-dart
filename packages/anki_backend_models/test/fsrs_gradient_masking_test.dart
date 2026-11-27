// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('maskFsrsParameterGradients', () {
    final gradients = List<double>.generate(21, (index) => index + 1.0);

    test('freezes the initial-stability slice only', () {
      final result = maskFsrsParameterGradients(
        gradients,
        freezeInitialStability: true,
        freezeShortTermStability: false,
      );
      expect(result.take(4), everyElement(0.0));
      expect(result.skip(4), gradients.skip(4));
    });

    test('freezes the short-term stability slice only', () {
      final result = maskFsrsParameterGradients(
        gradients,
        freezeInitialStability: false,
        freezeShortTermStability: true,
      );
      expect(result.take(17), gradients.take(17));
      expect(result.skip(17).take(3), everyElement(0.0));
      expect(result.skip(20), gradients.skip(20));
    });

    test('applies both source masks together', () {
      final result = maskFsrsParameterGradients(
        gradients,
        freezeInitialStability: true,
        freezeShortTermStability: true,
      );
      expect(result.take(4), everyElement(0.0));
      expect(result.skip(4).take(13), gradients.skip(4).take(13));
      expect(result.skip(17).take(3), everyElement(0.0));
      expect(result.skip(20), gradients.skip(20));
    });

    test('preserves all values when neither freeze is enabled', () {
      final result = maskFsrsParameterGradients(
        gradients,
        freezeInitialStability: false,
        freezeShortTermStability: false,
      );
      expect(result, gradients);
    });

    test('keeps the slice boundaries at 3/4 and 16/17/19/20', () {
      final result = maskFsrsParameterGradients(
        gradients,
        freezeInitialStability: true,
        freezeShortTermStability: true,
      );
      expect(result[3], 0.0);
      expect(result[4], gradients[4]);
      expect(result[16], gradients[16]);
      expect(result[17], 0.0);
      expect(result[19], 0.0);
      expect(result[20], gradients[20]);
    });

    test('converts vector values with Float32 precision', () {
      const nonFloat32 = 1.00000006;
      final input = List<double>.filled(21, nonFloat32);
      final expectedValue = Float32List.fromList(input).first;
      final result = maskFsrsParameterGradients(
        input,
        freezeInitialStability: false,
        freezeShortTermStability: false,
      );
      expect(result, everyElement(expectedValue));
      expect(expectedValue, isNot(nonFloat32));
    });

    test('returns a new vector without mutating caller input', () {
      final input = List<double>.of(gradients);
      final before = List<double>.of(input);
      final result = maskFsrsParameterGradients(
        input,
        freezeInitialStability: true,
        freezeShortTermStability: true,
      );
      expect(input, before);
      expect(identical(result, input), isFalse);
    });

    test('rejects vectors whose length is not 21', () {
      for (final length in [0, 20, 22]) {
        expect(
          () => maskFsrsParameterGradients(
            List<double>.filled(length, 1.0),
            freezeInitialStability: false,
            freezeShortTermStability: false,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
