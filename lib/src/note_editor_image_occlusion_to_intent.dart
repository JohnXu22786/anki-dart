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

/// Host operations needed to construct an ImageOcclusion destination Intent.
///
/// The host supplies Android Context and Intent behavior, including the
/// `NoteEditorActivity` component and Parcelable extra writes.
class NoteEditorImageOcclusionIntentCallbacks<TContext, TIntent, TUri> {
  const NoteEditorImageOcclusionIntentCallbacks({
    required this.createIntent,
    required this.putIntExtra,
    required this.putParcelableExtra,
  });

  final TIntent Function(TContext context) createIntent;
  final void Function(TIntent intent, String key, int value) putIntExtra;
  final void Function(TIntent intent, String key, TUri? value)
  putParcelableExtra;
}

/// Adapts `NoteEditorDestination.ImageOcclusion.toIntent(context)`.
///
/// Creates one host Intent, sets `CALLER` to the image-occlusion caller code,
/// then always writes [imageUri] as the nullable `image_uri` Parcelable extra.
/// It returns the same Intent; host callback failures propagate unchanged and
/// stop later operations.
TIntent noteEditorImageOcclusionToIntent<TContext, TIntent, TUri>({
  required TContext context,
  required TUri? imageUri,
  required NoteEditorImageOcclusionIntentCallbacks<TContext, TIntent, TUri>
  callbacks,
}) {
  final intent = callbacks.createIntent(context);
  callbacks.putIntExtra(intent, 'CALLER', NoteEditorCaller.IMG_OCCLUSION.value);
  callbacks.putParcelableExtra(intent, 'image_uri', imageUri);
  return intent;
}
