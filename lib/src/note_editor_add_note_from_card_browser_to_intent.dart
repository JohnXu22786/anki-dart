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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
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

/// Host operations needed to construct an AddNoteFromCardBrowser Intent.
///
/// The host supplies Android Context and Intent behavior, including the
/// `NoteEditorActivity` component and typed extra writes.
class NoteEditorAddNoteFromCardBrowserIntentCallbacks<TContext, TIntent> {
  const NoteEditorAddNoteFromCardBrowserIntentCallbacks({
    required this.createIntent,
    required this.putIntExtra,
    required this.putStringExtra,
    required this.putBooleanExtra,
    required this.putLongExtra,
  });

  final TIntent Function(TContext context) createIntent;
  final void Function(TIntent intent, String key, int value) putIntExtra;
  final void Function(TIntent intent, String key, String value) putStringExtra;
  final void Function(TIntent intent, String key, bool value) putBooleanExtra;
  final void Function(TIntent intent, String key, int value) putLongExtra;
}

/// Adapts `NoteEditorDestination.AddNoteFromCardBrowser.toIntent(context)`.
///
/// Creates one host Intent, writes `CALLER` with the Card Browser add-note
/// caller code, writes [searchTerms] under `SEARCH`, and writes
/// `inCardBrowserActivity: false`. A `DECK_ID` Long extra is written only when
/// [deckId] is positive. It returns the same Intent; host callback failures
/// propagate unchanged and stop later operations.
TIntent noteEditorAddNoteFromCardBrowserToIntent<TContext, TIntent>({
  required TContext context,
  required String searchTerms,
  required int? deckId,
  required NoteEditorAddNoteFromCardBrowserIntentCallbacks<TContext, TIntent>
  callbacks,
}) {
  final intent = callbacks.createIntent(context);
  callbacks.putIntExtra(
    intent,
    'CALLER',
    NoteEditorCaller.CARDBROWSER_ADD.value,
  );
  callbacks.putStringExtra(intent, 'SEARCH', searchTerms);
  callbacks.putBooleanExtra(intent, 'inCardBrowserActivity', false);
  if (deckId != null && deckId > 0) {
    callbacks.putLongExtra(intent, 'DECK_ID', deckId);
  }
  return intent;
}
