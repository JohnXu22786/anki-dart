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

import 'note_editor_caller.dart';

/// Host operations needed to construct an AddInstantNote destination Intent.
///
/// The host supplies Android Context and Intent behavior, including the
/// `NoteEditorActivity` component and typed extra writes.
class NoteEditorAddInstantNoteIntentCallbacks<TContext, TIntent> {
  const NoteEditorAddInstantNoteIntentCallbacks({
    required this.createIntent,
    required this.putIntExtra,
    required this.putStringExtra,
  });

  final TIntent Function(TContext context) createIntent;
  final void Function(TIntent intent, String key, int value) putIntExtra;
  final void Function(TIntent intent, String key, String value) putStringExtra;
}

/// Adapts `NoteEditorDestination.AddInstantNote.toIntent(context)`.
///
/// Creates one host Intent, sets `CALLER` to the instant-note caller code, then
/// always writes [sharedText] under Android's `Intent.EXTRA_TEXT` key. It
/// returns the same Intent; host callback failures propagate unchanged and stop
/// later operations.
TIntent noteEditorAddInstantNoteToIntent<TContext, TIntent>({
  required TContext context,
  required String sharedText,
  required NoteEditorAddInstantNoteIntentCallbacks<TContext, TIntent> callbacks,
}) {
  final intent = callbacks.createIntent(context);
  callbacks.putIntExtra(
    intent,
    'CALLER',
    NoteEditorCaller.INSTANT_NOTE_EDITOR.value,
  );
  callbacks.putStringExtra(intent, 'android.intent.extra.TEXT', sharedText);
  return intent;
}
