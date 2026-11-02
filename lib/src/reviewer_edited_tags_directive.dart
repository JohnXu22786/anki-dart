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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host update request containing the selected tags in AnkiDroid's tag string
/// form.
class ReviewerEditedTagsDirective {
  const ReviewerEditedTagsDirective({required this.tagsString});

  /// The exact `selectedTags.joinToString(" ")` result.
  final String tagsString;
}

/// Returns no request when the ordered lists are equal, otherwise requests a
/// host update with the selected tags joined by one literal ASCII space.
///
/// Current-card and note lookup, tag mutation, undoable persistence, logging,
/// and coroutine delivery remain the host's responsibility.
ReviewerEditedTagsDirective? reviewerEditedTagsDirective({
  required List<String> existingTags,
  required List<String> selectedTags,
}) {
  if (_orderedTagsEqual(existingTags, selectedTags)) return null;
  return ReviewerEditedTagsDirective(tagsString: selectedTags.join(' '));
}

bool _orderedTagsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
