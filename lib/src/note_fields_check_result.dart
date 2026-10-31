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
 * Behavioral reference: `NoteFieldsCheckResult.kt` in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Semantic outcomes the host adapts from its note-field validation response.
///
/// The host maps generated response enums to these values after performing
/// collection/backend validation. Generated protocol types stay host-side.
enum NoteFieldsCheckStatus {
  normal,
  duplicate,
  empty,
  missingCloze,
  noteTypeNotCloze,
  fieldNotCloze,
  unrecognized,
}

/// Exact localized text supplied by the host for note-field failures.
final class NoteFieldsCheckMessages {
  const NoteFieldsCheckMessages({
    required this.imageOcclusionEmpty,
    required this.firstFieldEmpty,
    required this.missingCloze,
    required this.noteTypeNotCloze,
    required this.fieldNotCloze,
  });

  final String imageOcclusionEmpty;
  final String firstFieldEmpty;
  final String missingCloze;
  final String noteTypeNotCloze;
  final String fieldNotCloze;
}

/// Result of the host's note-field validation decision.
sealed class NoteFieldsCheckResult {
  const NoteFieldsCheckResult();
}

/// Note fields passed validation.
final class NoteFieldsCheckSuccess extends NoteFieldsCheckResult {
  const NoteFieldsCheckSuccess();
}

/// Note fields failed validation with an optional host-localized message.
final class NoteFieldsCheckFailure extends NoteFieldsCheckResult {
  const NoteFieldsCheckFailure(this.localizedMessage);

  final String? localizedMessage;
}

/// Projects a validated semantic status to AnkiDroid's note-fields result.
///
/// The host performs collection/backend validation and maps its generated
/// response state to [status]. It also supplies whether the note is Image
/// Occlusion and the exact localized strings in [messages]; this function does
/// not access collection, generated protocol, note, or localization APIs.
NoteFieldsCheckResult projectNoteFieldsCheckResult({
  required NoteFieldsCheckStatus status,
  required bool isImageOcclusion,
  required NoteFieldsCheckMessages messages,
}) => switch (status) {
  NoteFieldsCheckStatus.normal ||
  NoteFieldsCheckStatus.duplicate => const NoteFieldsCheckSuccess(),
  NoteFieldsCheckStatus.empty => NoteFieldsCheckFailure(
    isImageOcclusion ? messages.imageOcclusionEmpty : messages.firstFieldEmpty,
  ),
  NoteFieldsCheckStatus.missingCloze => NoteFieldsCheckFailure(
    messages.missingCloze,
  ),
  NoteFieldsCheckStatus.noteTypeNotCloze => NoteFieldsCheckFailure(
    messages.noteTypeNotCloze,
  ),
  NoteFieldsCheckStatus.fieldNotCloze => NoteFieldsCheckFailure(
    messages.fieldNotCloze,
  ),
  NoteFieldsCheckStatus.unrecognized => const NoteFieldsCheckFailure(null),
};
