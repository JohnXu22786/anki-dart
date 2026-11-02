/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AddEditReminderDialogViewModel.kt, ReviewReminder.kt,
 * and AddEditReminderDialog.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Time of day stored by the reminder form.
///
/// The host supplies current time values; this type does not read a clock.
final class ReviewReminderTime {
  ReviewReminderTime({required this.hour, required this.minute}) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Hour must be between 0 and 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(
        minute,
        'minute',
        'Minute must be between 0 and 59',
      );
    }
  }

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderTime &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ReviewReminderTime(hour=$hour, minute=$minute)';
}

/// The scope selected when adding a reminder.
sealed class ReviewReminderScope {
  const ReviewReminderScope();
}

final class GlobalReminderScope extends ReviewReminderScope {
  const GlobalReminderScope();

  @override
  bool operator ==(Object other) => other is GlobalReminderScope;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Global';
}

final class DeckSpecificReminderScope extends ReviewReminderScope {
  const DeckSpecificReminderScope(this.deckId);

  final int deckId;

  @override
  bool operator ==(Object other) =>
      other is DeckSpecificReminderScope && other.deckId == deckId;

  @override
  int get hashCode => Object.hash(DeckSpecificReminderScope, deckId);

  @override
  String toString() => 'DeckSpecific(did=$deckId)';
}

/// The fields consumed by the dialog when editing or emitting a reminder.
///
/// A host wraps this projection in its runtime reminder type, which owns IDs,
/// profile data, timestamps, persistence, and other backend behavior.
final class ReviewReminderProjection {
  const ReviewReminderProjection({
    required this.time,
    required this.cardTriggerThreshold,
    required this.scope,
    required this.enabled,
    required this.onlyNotifyIfNoReviews,
  });

  final ReviewReminderTime time;
  final int cardTriggerThreshold;
  final ReviewReminderScope scope;
  final bool enabled;
  final bool onlyNotifyIfNoReviews;
}

/// Portable form state from AnkiDroid's AddEditReminderDialogViewModel.
///
/// UI, lifecycle, logging, collection access, and reminder construction remain
/// in the host. The nullable fields model nullable LiveData values so output
/// fallbacks preserve the source behavior.
final class ReviewReminderFormState {
  ReviewReminderFormState._({
    required this.time,
    required this.deckSelected,
    required this.cardTriggerThreshold,
    required this.onlyNotifyIfNoReviews,
    required this.advancedSettingsOpen,
    required bool enabled,
  }) : _enabled = enabled;

  factory ReviewReminderFormState.add({
    required ReviewReminderTime currentTime,
    required ReviewReminderScope scope,
    required int allDecksId,
  }) => ReviewReminderFormState._(
    time: currentTime,
    deckSelected: switch (scope) {
      GlobalReminderScope() => allDecksId,
      DeckSpecificReminderScope(:final deckId) => deckId,
    },
    cardTriggerThreshold: 1,
    onlyNotifyIfNoReviews: false,
    advancedSettingsOpen: false,
    enabled: true,
  );

  factory ReviewReminderFormState.edit({
    required ReviewReminderProjection reminder,
    required int allDecksId,
  }) => ReviewReminderFormState._(
    time: reminder.time,
    deckSelected: switch (reminder.scope) {
      GlobalReminderScope() => allDecksId,
      DeckSpecificReminderScope(:final deckId) => deckId,
    },
    cardTriggerThreshold: reminder.cardTriggerThreshold,
    onlyNotifyIfNoReviews: reminder.onlyNotifyIfNoReviews,
    advancedSettingsOpen: false,
    enabled: reminder.enabled,
  );

  ReviewReminderTime? time;
  int? deckSelected;
  int? cardTriggerThreshold;
  bool? onlyNotifyIfNoReviews;
  bool? advancedSettingsOpen;
  final bool _enabled;

  void setTime(ReviewReminderTime value) {
    time = value;
  }

  void setDeckSelected(int deckId) {
    deckSelected = deckId;
  }

  void setCardTriggerThreshold(int threshold) {
    cardTriggerThreshold = threshold;
  }

  void toggleOnlyNotifyIfNoReviews() {
    onlyNotifyIfNoReviews = !(onlyNotifyIfNoReviews ?? false);
  }

  void toggleAdvancedSettingsOpen() {
    advancedSettingsOpen = !(advancedSettingsOpen ?? false);
  }

  /// Projects the form in source field order and applies source null defaults.
  ///
  /// [currentTime] is supplied again because the source asks the host clock for
  /// the current time when the form's time value is null at submission.
  ReviewReminderProjection outputStateAsReminder({
    required ReviewReminderTime currentTime,
    required int allDecksId,
    required int defaultDeckId,
  }) {
    final threshold = cardTriggerThreshold ?? 1;
    if (threshold < 0) {
      throw ArgumentError.value(
        threshold,
        'cardTriggerThreshold',
        'Card trigger threshold must be >= 0',
      );
    }

    final selectedDeckId = deckSelected;
    final scope = selectedDeckId == allDecksId
        ? const GlobalReminderScope()
        : DeckSpecificReminderScope(selectedDeckId ?? defaultDeckId);

    return ReviewReminderProjection(
      time: time ?? currentTime,
      cardTriggerThreshold: threshold,
      scope: scope,
      enabled: _enabled,
      onlyNotifyIfNoReviews: onlyNotifyIfNoReviews ?? false,
    );
  }
}
