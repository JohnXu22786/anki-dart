/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from CardTemplateFragment.restoreNotetypeToStock in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.restoreNotetypeToStock(kind)`.
///
/// The host retains model and collection access, generated note-type IDs,
/// undoable operations, Android context/resources, and themed toast display.
/// Callback failures propagate unchanged and prevent later source effects.
final class CardTemplateFragmentRestoreNotetypeToStockCallbacks<
  TModel,
  TModelId,
  TNotetypeId,
  TKind,
  TContext,
  TText
> {
  const CardTemplateFragmentRestoreNotetypeToStockCallbacks({
    required this.temporaryModel,
    required this.temporaryModelId,
    required this.notetypeId,
    required this.runUndoableOperation,
    required this.restoreNotetypeToStock,
    required this.onModelSaved,
    required this.requireContext,
    required this.restoredToDefaultToastText,
    required this.showThemedToast,
  });

  final TModel Function() temporaryModel;
  final TModelId Function(TModel model) temporaryModelId;
  final TNotetypeId Function(TModelId id) notetypeId;
  final Future<void> Function(Future<void> Function() operation)
  runUndoableOperation;
  final Future<void> Function(TNotetypeId nid, TKind? kind)
  restoreNotetypeToStock;
  final void Function() onModelSaved;
  final TContext Function() requireContext;
  final TText Function(TContext context) restoredToDefaultToastText;
  final void Function(TContext context, TText text, {required bool shortLength})
  showThemedToast;
}

/// Restores the temporary note type and reports success in source order.
///
/// The same nullable [kind] reaches the host restore operation unchanged. The
/// model-saved callback runs only after the undoable operation completes; the
/// context and localized text are resolved afterward, before a themed toast
/// with `shortLength: false` is shown. Upstream marks this
/// `@NeedsTest("Notetype is restored to stock kind")`; no direct pinned test
/// for this method was found in `CardTemplateEditorTest.kt`.
Future<void> cardTemplateFragmentRestoreNotetypeToStock<
  TModel,
  TModelId,
  TNotetypeId,
  TKind,
  TContext,
  TText
>({
  required TKind? kind,
  required CardTemplateFragmentRestoreNotetypeToStockCallbacks<
    TModel,
    TModelId,
    TNotetypeId,
    TKind,
    TContext,
    TText
  >
  callbacks,
}) async {
  final model = callbacks.temporaryModel();
  final modelId = callbacks.temporaryModelId(model);
  final nid = callbacks.notetypeId(modelId);
  await callbacks.runUndoableOperation(
    () => callbacks.restoreNotetypeToStock(nid, kind),
  );
  callbacks.onModelSaved();
  final context = callbacks.requireContext();
  final text = callbacks.restoredToDefaultToastText(context);
  callbacks.showThemedToast(context, text, shortLength: false);
}
