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

/// Host operations needed to construct an EditSelection Intent.
///
/// The host supplies Android Context and Intent behavior, including the
/// `NoteEditorActivity` component and typed extra writes.
class NoteEditorEditSelectionIntentCallbacks<TContext, TIntent, TAnimation> {
  const NoteEditorEditSelectionIntentCallbacks({
    required this.createIntent,
    required this.putIntExtra,
    required this.putLongExtra,
    required this.putLongArrayExtra,
    required this.putParcelableExtra,
    required this.putBooleanExtra,
  });

  final TIntent Function(TContext context) createIntent;
  final void Function(TIntent intent, String key, int value) putIntExtra;
  final void Function(TIntent intent, String key, int value) putLongExtra;
  final void Function(TIntent intent, String key, List<int> value)
  putLongArrayExtra;
  final void Function(TIntent intent, String key, TAnimation value)
  putParcelableExtra;
  final void Function(TIntent intent, String key, bool value) putBooleanExtra;
}

/// Adapts `NoteEditorDestination.EditSelection.toIntent(context)`.
///
/// Creates one host Intent, writes the edit caller, then reads the first card
/// ID and writes it with a copied list of all card IDs. The required animation
/// and in-Card-Browser flag follow in source order. An empty [cardIds] list
/// therefore fails after the caller extra is written. The same Intent is
/// returned; callback failures propagate unchanged and stop later operations.
TIntent noteEditorEditSelectionToIntent<TContext, TIntent, TAnimation>({
  required TContext context,
  required List<int> cardIds,
  required TAnimation animation,
  required bool inCardBrowserActivity,
  required NoteEditorEditSelectionIntentCallbacks<TContext, TIntent, TAnimation>
  callbacks,
}) {
  final intent = callbacks.createIntent(context);
  callbacks.putIntExtra(intent, 'CALLER', NoteEditorCaller.EDIT.value);
  callbacks.putLongExtra(intent, 'CARD_ID', cardIds.first);
  callbacks.putLongArrayExtra(intent, 'CARD_IDS', List<int>.of(cardIds));
  callbacks.putParcelableExtra(intent, 'finishAnimation', animation);
  callbacks.putBooleanExtra(
    intent,
    'inCardBrowserActivity',
    inCardBrowserActivity,
  );
  return intent;
}
