// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('an empty sibling set leaves every interval unmodified', () {
    expect(
      calculateSiblingDayModifiers(2, 3, []),
      [1.0, 1.0],
    );
  });

  test('one sibling applies the exact float32 five-day neighborhood', () {
    expect(
      calculateSiblingDayModifiers(0, 10, [5]),
      [
        1.0,
        0.800000011920929,
        0.6000000238418579,
        0.4000000059604645,
        0.20000000298023224,
        9.999999974752427e-7,
        0.20000000298023224,
        0.4000000059604645,
        0.6000000238418579,
        0.800000011920929,
        1.0,
      ],
    );
  });

  test('multiple sibling days multiply in sorted order and deduplicate repeats',
      () {
    expect(
      calculateSiblingDayModifiers(0, 10, [6, 5, 6]),
      [
        1.0,
        0.800000011920929,
        0.48000001907348633,
        0.24000000953674316,
        0.08000000566244125,
        2.0000000233721948e-7,
        2.0000000233721948e-7,
        0.08000000566244125,
        0.24000000953674316,
        0.48000001907348633,
        0.800000011920929,
      ],
    );
  });

  test('clips modifiers at both edges of the requested interval window', () {
    expect(
      calculateSiblingDayModifiers(0, 5, [0]),
      [
        9.999999974752427e-7,
        0.20000000298023224,
        0.4000000059604645,
        0.6000000238418579,
        0.800000011920929,
        1.0,
      ],
    );
    expect(
      calculateSiblingDayModifiers(0, 5, [5]),
      [
        1.0,
        0.800000011920929,
        0.6000000238418579,
        0.4000000059604645,
        0.20000000298023224,
        9.999999974752427e-7,
      ],
    );
  });

  test('accepts the last Core day and rejects out-of-range indices', () {
    expect(calculateSiblingDayModifiers(98, 98, [98]), [9.999999974752427e-7]);
    expect(() => calculateSiblingDayModifiers(98, 99, []), throwsArgumentError);
    expect(() => calculateSiblingDayModifiers(0, 2, [99]), throwsArgumentError);
  });

  test(
      'rejects negative or reversed interval windows and negative sibling days',
      () {
    expect(() => calculateSiblingDayModifiers(-1, 2, []), throwsArgumentError);
    expect(() => calculateSiblingDayModifiers(3, 2, []), throwsArgumentError);
    expect(() => calculateSiblingDayModifiers(0, 2, [-1]), throwsArgumentError);
  });
}
