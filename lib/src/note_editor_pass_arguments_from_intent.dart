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
 * Source-derived from NoteEditorDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Projection of the source `NoteEditorDestination.PassArguments` values.
///
/// The host-owned Bundle is retained exactly as supplied; Android Intent and
/// Bundle behavior remain outside this Dart library.
final class NoteEditorPassArguments<TBundle> {
  const NoteEditorPassArguments({
    required this.arguments,
    required this.action,
  });

  /// The exact caller-supplied extras Bundle to forward to the Note Editor.
  final TBundle arguments;

  /// The nullable action read from the supplied Intent.
  final String? action;
}

/// Adapts `NoteEditorDestination.PassArguments.from(intent, extras)`.
///
/// Reads [intent]'s action once and retains [extras] by identity. The caller is
/// responsible for obtaining extras and performing any null check. Host getter
/// failures propagate unchanged.
NoteEditorPassArguments<TBundle>
noteEditorPassArgumentsFromIntent<TIntent, TBundle>({
  required TIntent intent,
  required TBundle extras,
  required String? Function(TIntent intent) actionOf,
}) {
  final action = actionOf(intent);
  return NoteEditorPassArguments(arguments: extras, action: action);
}
