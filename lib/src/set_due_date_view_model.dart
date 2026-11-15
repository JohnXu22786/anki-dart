/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: SetDueDateViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// The due-date mode selected by the host's Set Due Date dialog.
enum SetDueDateTab { singleDay, dateRange }

/// A nullable future-day range, where day 0 means today.
class SetDueDateRange {
  SetDueDateRange({this.start, this.end});

  int? start;
  int? end;

  bool isValid() {
    final start = this.start;
    final end = this.end;
    if (start == null || end == null) return false;
    if (start < 0) return false;
    return start <= end;
  }

  /// Returns the scheduler parameter, collapsing a range with equal endpoints.
  String? toDaysParameter() {
    if (!isValid()) return null;
    if (start == end) return '$start';
    return '$start-$end';
  }

  @override
  String toString() => '$start – $end';
}

/// Portable Set Due Date state and parameter decisions from AnkiDroid.
///
/// The host supplies scheduler initialization and card metadata. Collection
/// access, current-card lookup, dialog state delivery, and scheduler mutation
/// remain host responsibilities.
class SetDueDateViewModel {
  late List<int> cardIds;

  bool? _fsrsEnabled;
  bool? get fsrsEnabled => _fsrsEnabled;

  SetDueDateTab _currentTab = SetDueDateTab.singleDay;
  SetDueDateTab get currentTab => _currentTab;
  set currentTab(SetDueDateTab value) {
    _currentTab = value;
    _refreshIsValid();
  }

  bool _isValid = false;
  bool get isValid => _isValid;

  int? _nextSingleDayDueDate;
  int? get nextSingleDayDueDate => _nextSingleDayDueDate;
  set nextSingleDayDueDate(int? value) {
    _nextSingleDayDueDate = value != null && value >= 0 ? value : null;
    _refreshIsValid();
  }

  final SetDueDateRange dateRange = SetDueDateRange();

  bool _updateIntervalToMatchDueDate = false;

  /// FSRS always matches interval to due date, as in the source ViewModel.
  bool get updateIntervalToMatchDueDate =>
      _fsrsEnabled == true ? true : _updateIntervalToMatchDueDate;
  set updateIntervalToMatchDueDate(bool value) {
    if (_fsrsEnabled == true && !value) {
      throw UnsupportedError('due date must match interval if using FSRS');
    }
    _updateIntervalToMatchDueDate = value;
  }

  /// This option can be changed only when the scheduler is known to use SM-2.
  bool get canSetUpdateIntervalToMatchDueDate => _fsrsEnabled == false;

  int get cardCount => cardIds.length;

  /// Supplies the card IDs and scheduler setting resolved by the host.
  void init({required List<int> cardIds, required bool fsrsEnabled}) {
    this.cardIds = cardIds;
    if (fsrsEnabled) {
      updateIntervalToMatchDueDate = true;
    }
    _fsrsEnabled = fsrsEnabled;
    _refreshIsValid();
  }

  void setNextDateRangeStart(int? value) {
    dateRange.start = value;
    _refreshIsValid();
  }

  void setNextDateRangeEnd(int? value) {
    dateRange.end = value;
    _refreshIsValid();
  }

  /// Returns null until the scheduler setting is known or the chosen value valid.
  ///
  /// The host wraps the returned string in its scheduler-specific parameter
  /// type and performs the undoable scheduler operation.
  String? calculateDaysParameter() {
    if (_fsrsEnabled == null) return null;
    final days = switch (_currentTab) {
      SetDueDateTab.singleDay => _nextSingleDayDueDate?.toString(),
      SetDueDateTab.dateRange => dateRange.toDaysParameter(),
    };
    if (days == null) return null;
    return updateIntervalToMatchDueDate ? '$days!' : days;
  }

  void _refreshIsValid() {
    final inputIsValid = switch (_currentTab) {
      SetDueDateTab.singleDay =>
        _nextSingleDayDueDate != null && _nextSingleDayDueDate! >= 0,
      SetDueDateTab.dateRange => dateRange.isValid(),
    };
    _isValid = inputIsValid && _fsrsEnabled != null;
  }
}

/// Projects current-interval visibility after the host resolves card metadata.
///
/// The source hides the interval for multi-card selections and for every card
/// type except review cards. A review interval of zero is preserved.
int? projectSetDueDateCurrentInterval({
  required int cardCount,
  required bool isReviewCard,
  required int intervalDays,
}) {
  if (cardCount != 1 || !isReviewCard) return null;
  return intervalDays;
}
