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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'browser_row_collection.dart';
import 'browser_row_selection.dart';

/// Ordered host directives produced by tapping one Card Browser row.
enum BrowserRowActivationEffectKind {
  /// Apply [BrowserRowActivationEffect.selectionTransition].
  toggleSelection,

  /// Set the current pane row to [BrowserRowActivationEffect.rowId].
  setPaneRow,

  /// End multi-select with the source `OpenNoteEditorActivity` cause.
  endMultiSelectModeForEditor,

  /// Resolve the editor destination and load it in the pane if non-null.
  loadEditorInPaneIfAvailable,

  /// Resolve the editor destination and launch the activity if non-null.
  launchEditorActivityIfAvailable,
}

/// One directive in the source-ordered result of a row activation.
final class BrowserRowActivationEffect {
  const BrowserRowActivationEffect._({
    required this.kind,
    this.rowId,
    this.selectionTransition,
  });

  final BrowserRowActivationEffectKind kind;

  /// Row used by pane/editor directives; null for the mode-end directive.
  final BrowserRowId? rowId;

  /// Present only for the multi-select toggle directive.
  final BrowserRowSelectionTransition? selectionTransition;
}

/// The ordered, immutable plan for one source `CardBrowserViewModel.onTap`.
final class BrowserRowActivationPlan {
  BrowserRowActivationPlan._(Iterable<BrowserRowActivationEffect> effects)
      : effects = List.unmodifiable(effects);

  /// Effects in the order the host must apply them.
  final List<BrowserRowActivationEffect> effects;
}

/// Projects AnkiDroid's row-tap branch without performing editor/UI work.
///
/// A normal tap requests the editor route for the current device layout. A
/// multi-select tap composes [toggleBrowserRowSelection]; only tapping a row
/// that was already selected in fragmented mode also updates the pane and
/// requests a pane editor destination. The host resolves the collection-backed
/// destination and emits its editor command only when that destination exists.
BrowserRowActivationPlan planBrowserRowActivation({
  required Iterable<BrowserRowId> selectedRows,
  required BrowserRowSelection selection,
  required bool isInMultiSelectMode,
  required bool isFragmented,
}) {
  final selectedSnapshot = List<BrowserRowId>.of(selectedRows);
  final wasSelected = selectedSnapshot.contains(selection.rowId);
  final effects = <BrowserRowActivationEffect>[];

  if (isInMultiSelectMode) {
    effects.add(
      BrowserRowActivationEffect._(
        kind: BrowserRowActivationEffectKind.toggleSelection,
        selectionTransition: toggleBrowserRowSelection(
          selectedRows: selectedSnapshot,
          selection: selection,
          isInMultiSelectMode: isInMultiSelectMode,
        ),
      ),
    );

    if (wasSelected && isFragmented) {
      effects
        ..add(
          BrowserRowActivationEffect._(
            kind: BrowserRowActivationEffectKind.setPaneRow,
            rowId: selection.rowId,
          ),
        )
        ..add(
          BrowserRowActivationEffect._(
            kind: BrowserRowActivationEffectKind.loadEditorInPaneIfAvailable,
            rowId: selection.rowId,
          ),
        );
    }
  } else if (isFragmented) {
    effects
      ..add(
        BrowserRowActivationEffect._(
          kind: BrowserRowActivationEffectKind.setPaneRow,
          rowId: selection.rowId,
        ),
      )
      ..add(
        BrowserRowActivationEffect._(
          kind: BrowserRowActivationEffectKind.loadEditorInPaneIfAvailable,
          rowId: selection.rowId,
        ),
      );
  } else {
    effects
      ..add(
        const BrowserRowActivationEffect._(
          kind: BrowserRowActivationEffectKind.endMultiSelectModeForEditor,
        ),
      )
      ..add(
        BrowserRowActivationEffect._(
          kind: BrowserRowActivationEffectKind.launchEditorActivityIfAvailable,
          rowId: selection.rowId,
        ),
      );
  }

  return BrowserRowActivationPlan._(effects);
}
