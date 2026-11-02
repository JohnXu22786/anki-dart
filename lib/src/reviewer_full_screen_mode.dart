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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FullScreenMode.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. Preference reads and writes remain host effects.
 */

/// A Reviewer display mode and its exact serialized preference value.
enum ReviewerFullScreenMode {
  /// Display both navigation and buttons (the default).
  buttonsAndMenu('0'),

  /// Remove the menu bar while keeping the answer button.
  buttonsOnly('1'),

  /// Remove both the menu bar and buttons; the host owns gesture gating.
  fullscreenAllGone('2');

  const ReviewerFullScreenMode(this._preferenceValue);

  static const preferenceKey = 'fullscreenMode';
  static const legacyPreferenceKey = 'fullscreenReview';
  static const defaultMode = ReviewerFullScreenMode.buttonsAndMenu;

  final String _preferenceValue;

  String getPreferenceValue() => _preferenceValue;

  bool isFullScreenReview() => this != defaultMode;

  /// Resolves the source preference, using the default for missing/null or
  /// unknown values. The host performs the preference read and passes its
  /// nullable string value here.
  static ReviewerFullScreenMode fromPreference(String? value) =>
      values.where((mode) => mode._preferenceValue == value).firstOrNull ??
      defaultMode;
}

/// The source's preference-level full-screen predicate without reading storage.
bool isFullScreenReview(String? value) =>
    ReviewerFullScreenMode.fromPreference(value).isFullScreenReview();

/// One ordered host preference action; hosts apply actions in list order.
sealed class ReviewerFullScreenPreferenceAction {
  const ReviewerFullScreenPreferenceAction();
}

/// Store a string value under a preference key.
final class ReviewerFullScreenPreferenceWrite
    extends ReviewerFullScreenPreferenceAction {
  const ReviewerFullScreenPreferenceWrite({
    required this.key,
    required this.value,
  });

  final String key;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is ReviewerFullScreenPreferenceWrite &&
      other.key == key &&
      other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}

/// Remove a legacy preference key.
final class ReviewerFullScreenPreferenceRemoval
    extends ReviewerFullScreenPreferenceAction {
  const ReviewerFullScreenPreferenceRemoval({required this.key});

  final String key;

  @override
  bool operator ==(Object other) =>
      other is ReviewerFullScreenPreferenceRemoval && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A source-ordered preference update for a selected mode.
final class ReviewerFullScreenPreferencePlan {
  ReviewerFullScreenPreferencePlan(ReviewerFullScreenMode mode)
    : writes = List.unmodifiable([
        ReviewerFullScreenPreferenceWrite(
          key: ReviewerFullScreenMode.preferenceKey,
          value: mode.getPreferenceValue(),
        ),
      ]);

  final List<ReviewerFullScreenPreferenceAction> writes;
}

/// A source-ordered legacy migration plan, when the old key is present.
///
/// The host checks key presence and reads its boolean value, then applies the
/// returned string write followed by removal in one platform edit transaction.
final class ReviewerFullScreenLegacyUpgradePlan {
  ReviewerFullScreenLegacyUpgradePlan(ReviewerFullScreenMode mode)
    : writes = List.unmodifiable([
        ReviewerFullScreenPreferenceWrite(
          key: ReviewerFullScreenMode.preferenceKey,
          value: mode.getPreferenceValue(),
        ),
        const ReviewerFullScreenPreferenceRemoval(
          key: ReviewerFullScreenMode.legacyPreferenceKey,
        ),
      ]);

  final List<ReviewerFullScreenPreferenceAction> writes;
}

/// Builds the preference write for the source's `setPreference` operation.
ReviewerFullScreenPreferencePlan planReviewerFullScreenPreference(
  ReviewerFullScreenMode mode,
) => ReviewerFullScreenPreferencePlan(mode);

/// Plans the legacy upgrade only when the host found the legacy key.
///
/// The pinned source maps legacy `true` to BUTTONS_ONLY and `false` to
/// BUTTONS_AND_MENU. It does not infer a value from the current mode.
ReviewerFullScreenLegacyUpgradePlan? planReviewerFullScreenLegacyUpgrade({
  required bool containsLegacyPreference,
  required bool legacyValue,
}) {
  if (!containsLegacyPreference) return null;

  final mode = legacyValue
      ? ReviewerFullScreenMode.buttonsOnly
      : ReviewerFullScreenMode.buttonsAndMenu;
  return ReviewerFullScreenLegacyUpgradePlan(mode);
}
