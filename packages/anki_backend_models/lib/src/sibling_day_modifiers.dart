// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

const _siblingModifierSteps = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5];
const _siblingModifierValues = [
  1.0,
  0.8,
  0.6,
  0.4,
  0.2,
  0.000001,
  0.2,
  0.4,
  0.6,
  0.8,
  1.0
];
// Core's load-balancer cache contains day indices 0 through 98.
const _loadBalanceDays = 99;

/// Computes Core's sibling-day modifiers for an inclusive interval window.
///
/// Day indices are absolute indices in Core's 99-day load-balancer cache
/// (`0..98`). [beforeDays] and
/// [afterDays] delimit the output window; a sibling at [beforeDays] affects
/// output index 0. Repeated sibling indices are deduplicated and processed in
/// ascending order, so results do not depend on the input collection's order.
/// All constants and each multiplication are rounded to float32, matching
/// Core's `calculate_sibling_modifiers()` behavior. This helper only applies
/// supplied sibling days; it does not discover siblings or derive dates.
List<double> calculateSiblingDayModifiers(
  int beforeDays,
  int afterDays,
  Iterable<int> siblingDays,
) {
  if (beforeDays < 0 ||
      afterDays < beforeDays ||
      afterDays >= _loadBalanceDays) {
    throw ArgumentError(
      'expected 0 <= beforeDays <= afterDays < $_loadBalanceDays',
    );
  }

  final uniqueSiblingDays = siblingDays.toSet();
  if (uniqueSiblingDays.any((day) => day < 0 || day >= _loadBalanceDays)) {
    throw ArgumentError.value(
      siblingDays,
      'siblingDays',
      'indices must be in 0..${_loadBalanceDays - 1}',
    );
  }

  final modifiers = List<double>.filled(afterDays - beforeDays + 1, 1.0);
  final float32Values = Float32List.fromList(_siblingModifierValues);
  final sortedSiblingDays = uniqueSiblingDays.toList()..sort();

  for (final siblingDay in sortedSiblingDays) {
    for (var index = 0; index < _siblingModifierSteps.length; index++) {
      final targetDay = siblingDay + _siblingModifierSteps[index] - beforeDays;
      if (targetDay >= 0 && targetDay < modifiers.length) {
        modifiers[targetDay] = _float32(
          modifiers[targetDay] * float32Values[index],
        );
      }
    }
  }

  return modifiers;
}

double _float32(double value) {
  final narrowed = Float32List(1)..[0] = value;
  return narrowed[0];
}
