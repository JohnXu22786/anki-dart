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
 * Behavioral reference: PreviewerViewModel.kt and NoteService.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// One ordered host operation in the Previewer mark-toggle plan.
sealed class PreviewerMarkEffect {
  const PreviewerMarkEffect();
}

/// Toggles the `marked` tag on the host-resolved current note.
final class PreviewerToggleMarkEffect extends PreviewerMarkEffect {
  const PreviewerToggleMarkEffect();
}

/// Reads the note's marked state only after the preceding toggle succeeds.
final class PreviewerReadMarkOnToggleSuccessEffect extends PreviewerMarkEffect {
  const PreviewerReadMarkOnToggleSuccessEffect();
}

/// Publishes the state returned by the preceding successful read.
final class PreviewerPublishMarkOnReadSuccessEffect
    extends PreviewerMarkEffect {
  const PreviewerPublishMarkOnReadSuccessEffect();
}

/// Projects `PreviewerViewModel.toggleMark()` into ordered host operations.
///
/// The host resolves the current card and note, then performs each effect in
/// order against that note. It must stop when an operation throws: a failed
/// toggle skips the marked-state read and publication, and a failed read skips
/// publication. Note lookup, tag mutation, undoable persistence, error
/// handling, and StateFlow delivery remain host-side.
List<PreviewerMarkEffect> previewerToggleMarkEffects() => List.unmodifiable([
  const PreviewerToggleMarkEffect(),
  const PreviewerReadMarkOnToggleSuccessEffect(),
  const PreviewerPublishMarkOnReadSuccessEffect(),
]);
