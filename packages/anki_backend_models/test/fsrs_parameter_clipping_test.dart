// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('clipFsrsParameters', () {
    test('applies every source clamp and preserves zip slice behavior', () {
      final lows = Float32List.fromList([
        0.001,
        0.001,
        0.001,
        0.001,
        1,
        0.001,
        0.001,
        0.001,
        0,
        0,
        0.001,
        0.001,
        0.001,
        0.001,
        0,
        0,
        1,
        0,
        0,
        0.01,
        0.1,
      ]);
      final highs = Float32List.fromList([
        100,
        100,
        100,
        100,
        10,
        4,
        4,
        0.75,
        4.5,
        0.8,
        3.5,
        5,
        0.25,
        0.9,
        4,
        1,
        6,
        2,
        2,
        0.8,
        0.8,
      ]);

      expect(
        clipFsrsParameters(List.filled(21, -100),
            numRelearningSteps: 1, enableShortTerm: true),
        lows,
      );
      expect(
        clipFsrsParameters(List.filled(21, 100),
            numRelearningSteps: 1, enableShortTerm: false),
        highs,
      );
      expect(
        clipFsrsParameters([0, -1000, 1000, 0, 1000, -1000, 1, 0.25, -0.1],
            numRelearningSteps: 1, enableShortTerm: true),
        Float32List.fromList([0.001, 0.001, 100, 0.001, 10, 0.001, 1, 0.25, 0]),
      );
      final overlong = clipFsrsParameters(
        [...List.filled(21, 0.5), 123.456789],
        numRelearningSteps: 1,
        enableShortTerm: true,
      );
      expect(overlong, hasLength(22));
      expect(overlong.last, Float32List.fromList([123.456789]).single);
    });

    test('uses source relearning ceiling and short-term floor branches', () {
      final defaults = <double>[
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
      final twoSteps = clipFsrsParameters(
        defaults,
        numRelearningSteps: 2,
        enableShortTerm: true,
      );
      expect(
        twoSteps.sublist(17, 20),
        Float32List.fromList([0.5425, 0.0912, 0.0658]),
      );
      expect(
        clipFsrsParameters([0.1],
            numRelearningSteps: 1, enableShortTerm: false),
        Float32List.fromList([0.1]),
      );
      expect(
        clipFsrsParameters([0.1],
            numRelearningSteps: 0, enableShortTerm: false),
        Float32List.fromList([0.1]),
      );

      final enabled = clipFsrsParameters(
        List.filled(20, 0),
        numRelearningSteps: 1,
        enableShortTerm: true,
      );
      final disabled = clipFsrsParameters(
        List.filled(20, 0),
        numRelearningSteps: 1,
        enableShortTerm: false,
      );
      expect(enabled[19], Float32List.fromList([0.01]).single);
      expect(disabled[19], 0.0);
    });

    test('rounds each dynamic-ceiling operation to Float32', () {
      final parameters = List<double>.filled(21, 0);
      parameters[11] = 1.4835;
      parameters[13] = 0.023017;
      parameters[14] = 1.6483;
      parameters[17] = 2;
      parameters[18] = 2;

      final clipped = clipFsrsParameters(
        parameters,
        numRelearningSteps: 2,
        enableShortTerm: true,
      );

      // The expected value locks this Dart Float32 path. Rust f32::powf has
      // unspecified, platform-dependent precision, so it is not a Rust-wide
      // bit-exact golden.
      final dartFloat32Ceiling = Float32List.fromList([1.273018]).single;
      expect(clipped[17], dartFloat32Ceiling);
      expect(clipped[18], dartFloat32Ceiling);
    });

    test('rejects invalid relearning step counts and formula inputs', () {
      expect(
        () => clipFsrsParameters([],
            numRelearningSteps: -1, enableShortTerm: false),
        throwsArgumentError,
      );
      expect(
        () => clipFsrsParameters(List.filled(14, 0.5),
            numRelearningSteps: 2, enableShortTerm: false),
        throwsArgumentError,
      );
    });

    test('returns an immutable Float32 snapshot without mutating input', () {
      final input = [0.1, ...List.filled(19, 0.5)];
      final original = List<double>.of(input);
      final clipped = clipFsrsParameters(
        input,
        numRelearningSteps: 1,
        enableShortTerm: false,
      );

      expect(input, original);
      expect(clipped.first, Float32List.fromList([0.1]).single);
      expect(() => clipped[0] = 2, throwsUnsupportedError);
    });
  });
}
