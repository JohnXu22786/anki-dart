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
 * Behavioral reference: ReviewerFragment.kt and ReviewerViewModel.kt in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Whether the host should change an icon's current visibility.
enum ReviewerIconVisibilityUpdate { noUpdate, hide, show }

/// Presentation update for the Reviewer's separate flag icon.
///
/// [iconFlag] is present only when [visibilityUpdate] is [ReviewerIconVisibilityUpdate.show].
/// The host maps that value to its platform drawable resource.
final class ReviewerFlagIconPresentation<TFlag> {
  const ReviewerFlagIconPresentation({
    required this.visibilityUpdate,
    this.iconFlag,
  });

  final ReviewerIconVisibilityUpdate visibilityUpdate;
  final TFlag? iconFlag;
}

/// Projects the mark-icon collector update from `ReviewerFragment`.
///
/// When the mark action is in the toolbar, the separate icon collector does
/// not change visibility. Otherwise its visibility follows [isMarked].
ReviewerIconVisibilityUpdate reviewerMarkIconVisibilityUpdate({
  required bool isMarkShownInToolbar,
  required bool isMarked,
}) {
  if (isMarkShownInToolbar) return ReviewerIconVisibilityUpdate.noUpdate;
  return isMarked
      ? ReviewerIconVisibilityUpdate.show
      : ReviewerIconVisibilityUpdate.hide;
}

/// Projects the flag-icon collector update from `ReviewerFragment`.
///
/// When the flag action is in the toolbar, the separate icon collector does
/// not change the icon. Otherwise NONE hides it; any other [flag] is passed
/// through for the host to select its drawable before showing the icon.
ReviewerFlagIconPresentation<TFlag> reviewerFlagIconPresentation<TFlag>({
  required bool isFlagShownInToolbar,
  required TFlag flag,
  required TFlag noneFlag,
}) {
  if (isFlagShownInToolbar) {
    return const ReviewerFlagIconPresentation(
      visibilityUpdate: ReviewerIconVisibilityUpdate.noUpdate,
    );
  }
  if (flag == noneFlag) {
    return const ReviewerFlagIconPresentation(
      visibilityUpdate: ReviewerIconVisibilityUpdate.hide,
    );
  }
  return ReviewerFlagIconPresentation(
    visibilityUpdate: ReviewerIconVisibilityUpdate.show,
    iconFlag: flag,
  );
}
