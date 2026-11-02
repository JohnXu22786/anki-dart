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

/// Host operations needed to construct a PassArguments destination Intent.
///
/// The host supplies the Android Context, Intent, and Bundle behavior.
class NoteEditorPassArgumentsIntentCallbacks<TContext, TIntent, TBundle> {
  const NoteEditorPassArgumentsIntentCallbacks({
    required this.createIntent,
    required this.putExtras,
    required this.setAction,
  });

  final TIntent Function(TContext context) createIntent;
  final void Function(TIntent intent, TBundle arguments) putExtras;
  final void Function(TIntent intent, String? action) setAction;
}

/// Adapts `NoteEditorDestination.PassArguments.toIntent(context)`.
///
/// Creates one host Intent, forwards the exact [arguments] Bundle once, then
/// assigns [action] (including when it is null), and returns that same Intent.
/// Host callback failures propagate unchanged and stop later operations.
TIntent noteEditorPassArgumentsToIntent<TContext, TIntent, TBundle>({
  required TContext context,
  required TBundle arguments,
  required String? action,
  required NoteEditorPassArgumentsIntentCallbacks<TContext, TIntent, TBundle>
  callbacks,
}) {
  final intent = callbacks.createIntent(context);
  callbacks.putExtras(intent, arguments);
  callbacks.setAction(intent, action);
  return intent;
}
