// SPDX-License-Identifier: AGPL-3.0-or-later
import 'deck_config.dart';
import 'ids.dart';
import 'load_balancer_day.dart';
import 'sibling_day_modifiers.dart';

const _loadBalanceDays = 99;

/// Finds a note's sibling days across all [daysByPreset] buckets and applies
/// Core's five-day sibling modifiers to the inclusive interval window.
///
/// Each preset must provide exactly Core's 99 cached days (`0..98`). A day is
/// included once if any preset has [noteId] on that day. A null [noteId] or a
/// note with no matching days leaves every interval unmodified. This helper
/// does not derive dates or perform scheduler orchestration.
List<double> calculateSiblingModifiers(
  Map<DeckConfigId, List<LoadBalancerDay>> daysByPreset, {
  required int beforeDays,
  required int afterDays,
  required NoteId? noteId,
}) {
  final unmodified =
      calculateSiblingDayModifiers(beforeDays, afterDays, const <int>[]);

  for (final entry in daysByPreset.entries) {
    if (entry.value.length != _loadBalanceDays) {
      throw ArgumentError.value(
        entry.value.length,
        'daysByPreset[${entry.key}] length',
        'expected exactly $_loadBalanceDays day buckets',
      );
    }
  }

  if (noteId == null || daysByPreset.isEmpty) {
    return unmodified;
  }

  final siblingDays = <int>{};
  for (final days in daysByPreset.values) {
    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      if (days[dayIndex].hasSibling(noteId)) {
        siblingDays.add(dayIndex);
      }
    }
  }

  if (siblingDays.isEmpty) {
    return unmodified;
  }

  final sortedSiblingDays = siblingDays.toList()..sort();
  return calculateSiblingDayModifiers(
    beforeDays,
    afterDays,
    sortedSiblingDays,
  );
}
