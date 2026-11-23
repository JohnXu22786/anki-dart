// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('findLoadBalancedInterval', () {
    test('matches the pinned Core inclusive interval fixture', () {
      // Source: Anki Core e64c6b1a, load_balancer.rs::find_interval;
      // fuzz.rs::constrained_fuzz_bounds yields 4..=6 for interval 5. The
      // three zero-review candidates each receive weight 1.0 in Core, and the
      // pinned rand 0.9.4 seed-zero fixture selects the third input candidate.
      final preset = Int64(1);
      final result = findLoadBalancedInterval(
        daysByPreset: {preset: _emptyDays()},
        easyDaysByPreset: {preset: _normalEasyDays()},
        nextDayAt: Int64(0),
        deckConfigId: preset,
        noteId: null,
        interval: 5,
        minimum: 1,
        maximum: 20,
        fuzzSeed: BigInt.zero,
      );

      expect(result, 6);
    });

    test('applies selected preset easy days and cross-preset sibling load', () {
      final selectedPreset = Int64(1);
      final otherPreset = Int64(2);
      final selectedDays = _emptyDays();
      for (var day = 4; day <= 6; day++) {
        for (var card = 0; card < 10; card++) {
          selectedDays[day]
              .add(Int64(day * 100 + card), Int64(day * 100 + card));
        }
      }
      final siblingDays = _emptyDays();
      siblingDays[4].add(Int64(4), Int64(42));
      final normalEasyDays = _normalEasyDays();
      final minimumEasyDays = List<EasyDay>.of(normalEasyDays)
        ..[intervalToWeekday(5, Int64(0))] = EasyDay.minimum;

      expect(
        findLoadBalancedInterval(
          daysByPreset: {selectedPreset: selectedDays},
          easyDaysByPreset: {selectedPreset: normalEasyDays},
          nextDayAt: Int64(0),
          deckConfigId: selectedPreset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        5,
      );
      expect(
        findLoadBalancedInterval(
          daysByPreset: {selectedPreset: selectedDays},
          easyDaysByPreset: {selectedPreset: minimumEasyDays},
          nextDayAt: Int64(0),
          deckConfigId: selectedPreset,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        6,
      );
      expect(
        findLoadBalancedInterval(
          daysByPreset: {
            selectedPreset: selectedDays,
            otherPreset: siblingDays,
          },
          easyDaysByPreset: {selectedPreset: normalEasyDays},
          nextDayAt: Int64(0),
          deckConfigId: selectedPreset,
          noteId: Int64(42),
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        6,
      );
    });

    test('returns null for missing inputs, absent seed, and long intervals',
        () {
      final preset = Int64(1);
      final days = _emptyDays();
      final easyDays = _normalEasyDays();

      int? find({
        Map<DeckConfigId, List<LoadBalancerDay>>? daysByPreset,
        Map<DeckConfigId, List<EasyDay>>? easyDaysByPreset,
        double interval = 5,
        int minimum = 1,
        required BigInt? fuzzSeed,
      }) =>
          findLoadBalancedInterval(
            daysByPreset: daysByPreset ?? {preset: days},
            easyDaysByPreset: easyDaysByPreset ?? {preset: easyDays},
            nextDayAt: Int64(0),
            deckConfigId: preset,
            noteId: null,
            interval: interval,
            minimum: minimum,
            maximum: 20,
            fuzzSeed: fuzzSeed,
          );

      expect(find(daysByPreset: {}, fuzzSeed: BigInt.zero), isNull);
      expect(find(easyDaysByPreset: {}, fuzzSeed: BigInt.zero), isNull);
      expect(find(fuzzSeed: null), isNull);
      expect(find(interval: 91, fuzzSeed: BigInt.zero), isNull);
      expect(find(minimum: 91, fuzzSeed: BigInt.zero), isNull);
    });

    test('validates the selected day cache and all easy-day configs', () {
      final selected = Int64(1);
      final other = Int64(2);

      expect(
        () => findLoadBalancedInterval(
          daysByPreset: {selected: _emptyDays()..removeLast()},
          easyDaysByPreset: {selected: _normalEasyDays()},
          nextDayAt: Int64(0),
          deckConfigId: selected,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => findLoadBalancedInterval(
          daysByPreset: {
            selected: _emptyDays(),
            other: _emptyDays()..removeLast()
          },
          easyDaysByPreset: {selected: _normalEasyDays()},
          nextDayAt: Int64(0),
          deckConfigId: selected,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => findLoadBalancedInterval(
          daysByPreset: {selected: _emptyDays()},
          easyDaysByPreset: {
            selected: [EasyDay.normal]
          },
          nextDayAt: Int64(0),
          deckConfigId: selected,
          noteId: null,
          interval: 5,
          minimum: 1,
          maximum: 20,
          fuzzSeed: BigInt.zero,
        ),
        throwsArgumentError,
      );
    });

    test('null note leaves sibling modifiers disabled and bounds are inclusive',
        () {
      final preset = Int64(1);
      final days = _emptyDays();
      days[4].add(Int64(4), Int64(42));
      final normal = _normalEasyDays();

      expect(
        findLoadBalancedInterval(
          daysByPreset: {preset: days},
          easyDaysByPreset: {preset: normal},
          nextDayAt: Int64(0),
          deckConfigId: preset,
          noteId: null,
          interval: 5,
          minimum: 4,
          maximum: 4,
          fuzzSeed: BigInt.zero,
        ),
        4,
      );
    });
  });
}

List<LoadBalancerDay> _emptyDays() =>
    List<LoadBalancerDay>.generate(99, (_) => LoadBalancerDay());

List<EasyDay> _normalEasyDays() => List<EasyDay>.filled(7, EasyDay.normal);
