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

/// Host callbacks used by [cardTemplateFragmentPerformPreview].
///
/// Android context, `NotetypeFile`, `Note`, collection access, preview
/// arguments, Intent, Activity, and task/error handling remain host-side. The
/// opaque values let Dart preserve the synchronous callback order without
/// copying or normalizing any host model data.
final class CardTemplateFragmentPerformPreviewCallbacks<
  TContext,
  TNotetype,
  TCollection,
  TNotetypeFile,
  TNote,
  TNoteId,
  TOrdinal,
  TFields,
  TTags,
  TArguments,
  TIntent
> {
  const CardTemplateFragmentPerformPreviewCallbacks({
    required this.launchCatchingTask,
    required this.notetype,
    required this.requireContext,
    required this.createNotetypeFile,
    required this.withCol,
    required this.getNote,
    required this.createNoteFromNotetypeId,
    required this.noteId,
    required this.ordinal,
    required this.fields,
    required this.tags,
    required this.createArguments,
    required this.getIntent,
    required this.startActivity,
  });

  final void Function(void Function() action) launchCatchingTask;
  final TNotetype Function() notetype;
  final TContext Function() requireContext;
  final TNotetypeFile Function(TContext context, TNotetype notetype)
  createNotetypeFile;
  final TResult Function<TResult>(
    TResult Function(TCollection collection) action,
  )
  withCol;
  final TNote? Function(TCollection collection) getNote;
  final TNote Function(TCollection collection, TNotetype notetype)
  createNoteFromNotetypeId;
  final TNoteId Function(TNote note) noteId;
  final TOrdinal Function() ordinal;
  final TFields Function(TNote note) fields;
  final TTags Function(TNote note) tags;
  final TArguments Function(
    TNotetypeFile notetypeFile,
    TNoteId id,
    TOrdinal ordinal,
    TFields fields,
    TTags tags, {
    required bool fillEmpty,
  })
  createArguments;
  final TIntent Function(TContext context, TArguments arguments) getIntent;
  final void Function(TIntent intent) startActivity;
}

/// Runs the host orchestration for `CardTemplateFragment.performPreview()`.
///
/// The host's [launchCatchingTask] owns scheduling and error handling. Inside
/// that callback this preserves source order, including fallback note creation
/// only when collection lookup returns null. Every callback failure propagates
/// immediately and prevents later callbacks.
void cardTemplateFragmentPerformPreview<
  TContext,
  TNotetype,
  TCollection,
  TNotetypeFile,
  TNote,
  TNoteId,
  TOrdinal,
  TFields,
  TTags,
  TArguments,
  TIntent
>({
  required CardTemplateFragmentPerformPreviewCallbacks<
    TContext,
    TNotetype,
    TCollection,
    TNotetypeFile,
    TNote,
    TNoteId,
    TOrdinal,
    TFields,
    TTags,
    TArguments,
    TIntent
  >
  callbacks,
}) {
  callbacks.launchCatchingTask(() {
    final notetype = callbacks.notetype();
    final notetypeFile = callbacks.createNotetypeFile(
      callbacks.requireContext(),
      notetype,
    );
    final note = callbacks.withCol(
      (collection) =>
          callbacks.getNote(collection) ??
          callbacks.createNoteFromNotetypeId(collection, notetype),
    );
    final arguments = callbacks.createArguments(
      notetypeFile,
      callbacks.noteId(note),
      callbacks.ordinal(),
      callbacks.fields(note),
      callbacks.tags(note),
      fillEmpty: true,
    );
    final intent = callbacks.getIntent(callbacks.requireContext(), arguments);
    callbacks.startActivity(intent);
  });
}
