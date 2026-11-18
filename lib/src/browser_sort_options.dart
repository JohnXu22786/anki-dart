/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: SortOrderBottomSheetFragment.kt and
 * CardBrowserColumn.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'browser_column_collection.dart';
import 'browser_sort_type.dart';

enum BrowserSortOptionSection { active, other, unavailable }

enum BrowserSortExplanation {
  textAscending,
  textDescending,
  numericAscending,
  numericDescending,
  dateAscending,
  dateDescending,
}

/// A platform-neutral row for the Card Browser sort chooser.
final class BrowserSortOption {
  const BrowserSortOption({
    required this.column,
    required this.mode,
    required this.label,
    required this.section,
    required this.selected,
    this.selectedReverse,
  });

  final BrowserColumn column;
  final BrowserColumnMode mode;
  final String label;
  final BrowserSortOptionSection section;
  final bool selected;
  final bool? selectedReverse;

  BrowserColumnSortUnavailableReason? get unavailableReason =>
      column.unavailableReason;

  BrowserSortExplanation? get selectedExplanation {
    if (!selected || selectedReverse == null) return null;
    return switch ((column.typeFor(mode), selectedReverse!)) {
      (BrowserColumnType.text, false) => BrowserSortExplanation.textAscending,
      (BrowserColumnType.text, true) => BrowserSortExplanation.textDescending,
      (BrowserColumnType.numeric, false) =>
        BrowserSortExplanation.numericAscending,
      (BrowserColumnType.numeric, true) =>
        BrowserSortExplanation.numericDescending,
      (BrowserColumnType.date, false) => BrowserSortExplanation.dateAscending,
      (BrowserColumnType.date, true) => BrowserSortExplanation.dateDescending,
      _ => null,
    };
  }
}

/// Builds active, hidden-sortable and unavailable groups in source column order.
List<BrowserSortOption> buildBrowserSortOptions({
  required BrowserColumnMode mode,
  required Iterable<BrowserColumn> activeColumns,
  required Map<BrowserColumn, String> labels,
  required BrowserSortType selectedSort,
}) {
  final activeOrder = activeColumns.toList();
  final active = activeOrder.toSet();
  final selected = selectedSort is BrowserSortCollectionOrdering
      ? selectedSort
      : null;
  final columns = BrowserColumn.values;
  final groups = <BrowserSortOptionSection, List<BrowserColumn>>{
    BrowserSortOptionSection.active: [
      for (final column in activeOrder)
        if (column.canSort(mode)) column,
    ],
    BrowserSortOptionSection.other: [
      for (final column in columns)
        if (!active.contains(column) && column.canSort(mode)) column,
    ],
    BrowserSortOptionSection.unavailable: [
      for (final column in columns)
        if (!column.canSort(mode)) column,
    ],
  };
  return [
    for (final section in BrowserSortOptionSection.values)
      for (final column in groups[section]!)
        BrowserSortOption(
          column: column,
          mode: mode,
          label: labels[column] ?? column.key,
          section: section,
          selected: selected?.key == column.key,
          selectedReverse: selected?.key == column.key
              ? selected!.reverse
              : null,
        ),
  ];
}

/// Whether a key is supported by the source SQL compiler in [mode].
bool browserSortKeyAvailable(String key, BrowserColumnMode mode) {
  for (final column in BrowserColumn.values) {
    if (column.key == key) return column.canSort(mode);
  }
  return false;
}
