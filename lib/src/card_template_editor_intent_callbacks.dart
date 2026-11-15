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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks used to construct a Card Template Editor Intent.
///
/// The host constructs the Android Intent with its Activity target, supplies
/// Android extra keys and generated ID values, performs typed writes, and logs.
/// No Android types, generated IDs, or logging dependencies enter Dart.
final class CardTemplateEditorIntentCallbacks<
  TIntent,
  TNoteTypeId,
  TNoteId,
  TOrdinal
> {
  const CardTemplateEditorIntentCallbacks({
    required this.createIntent,
    required this.putNoteTypeId,
    required this.putNoteId,
    required this.putOrd,
    required this.log,
  });

  final TIntent Function() createIntent;
  final void Function(TIntent intent, String key, TNoteTypeId noteTypeId)
  putNoteTypeId;
  final void Function(TIntent intent, String key, TNoteId noteId) putNoteId;
  final void Function(TIntent intent, String key, TOrdinal ord) putOrd;
  final void Function(TNoteTypeId noteTypeId, TNoteId? noteId, TOrdinal? ord)
  log;
}

/// Creates and fills a host Intent in the source order, then logs and returns it.
///
/// Optional extras are skipped when their values are null. Callback failures
/// propagate immediately, so no later write or log runs after a failed action.
TIntent
createCardTemplateEditorIntent<TIntent, TNoteTypeId, TNoteId, TOrdinal>({
  required TNoteTypeId noteTypeId,
  required TNoteId? noteId,
  required TOrdinal? ord,
  required String noteTypeIdKey,
  required String noteIdKey,
  required String ordKey,
  required CardTemplateEditorIntentCallbacks<
    TIntent,
    TNoteTypeId,
    TNoteId,
    TOrdinal
  >
  callbacks,
}) {
  final intent = callbacks.createIntent();
  callbacks.putNoteTypeId(intent, noteTypeIdKey, noteTypeId);
  if (noteId != null) {
    callbacks.putNoteId(intent, noteIdKey, noteId);
  }
  if (ord != null) {
    callbacks.putOrd(intent, ordKey, ord);
  }
  callbacks.log(noteTypeId, noteId, ord);
  return intent;
}
