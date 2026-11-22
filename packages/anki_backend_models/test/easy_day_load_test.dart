// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('EasyDay', () {
    test('classifies exact float32 percentages and parses Core defaults', () {
      expect(EasyDay.fromPercentage(1.0), EasyDay.normal);
      expect(EasyDay.fromPercentage(0.0), EasyDay.minimum);
      expect(EasyDay.fromPercentage(-0.0), EasyDay.minimum);
      expect(EasyDay.fromPercentage(0.99999999), EasyDay.normal);
      expect(EasyDay.fromPercentage(0.25), EasyDay.reduced);
      expect(EasyDay.fromPercentage(double.nan), EasyDay.reduced);
      expect(EasyDay.normal.loadModifier, 1.0);
      expect(EasyDay.reduced.loadModifier, 0.5);
      expect(EasyDay.minimum.loadModifier, 0.00009999999747378752);

      expect(parseEasyDaysPercentages([]), List.filled(7, EasyDay.normal));
      expect(
        parseEasyDaysPercentages([1.0, 0.0, 0.25, 1.0, 0.0, 0.25, 1.0]),
        [
          EasyDay.normal,
          EasyDay.minimum,
          EasyDay.reduced,
          EasyDay.normal,
          EasyDay.minimum,
          EasyDay.reduced,
          EasyDay.normal,
        ],
      );
      expect(
        () => parseEasyDaysPercentages([1.0]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'expected 7 days',
          ),
        ),
      );
    });
  });

  test('normalizes reduced days and pairs weekdays with review counts', () {
    const easyDays = [
      EasyDay.reduced,
      EasyDay.normal,
      EasyDay.minimum,
      EasyDay.reduced,
      EasyDay.normal,
      EasyDay.normal,
      EasyDay.normal,
    ];

    // Day 0 stays available: 2 reviews are below the 3-review other-day
    // average; day 3 is reduced to minimum because its doubled load is high.
    expect(
      calculateEasyDaysModifiers(
        easyDays,
        [0, 1, 2, 3],
        [2, 3, 7, 4],
      ),
      [1.0, 1.0, 0.00009999999747378752, 0.00009999999747378752],
    );

    // Core totals use the full count input while output uses zip length: the
    // trailing count makes day 0 remain normal even though it has high load.
    expect(
      calculateEasyDaysModifiers(easyDays, [0, 1], [3, 1, 10]),
      [1.0, 1.0],
    );
  });
}
