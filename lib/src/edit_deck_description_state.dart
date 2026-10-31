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
 * Behavioral reference: EditDeckDescriptionDialogViewModel.kt in AnkiDroid
 * 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// The dismissal variants emitted by AnkiDroid's source ViewModel.
enum EditDeckDescriptionDismissal { saved, closedWithoutSaving }

/// The two outcomes of a back request, before the host applies the outcome.
enum EditDeckDescriptionBackAction {
  closeWithoutSaving,
  showDiscardConfirmation,
}

/// A host action returned by [EditDeckDescriptionDialogState.saveAndExitActions].
sealed class EditDeckDescriptionAction {
  const EditDeckDescriptionAction();
}

/// Ask the host to persist the current dialog values.
final class EditDeckDescriptionPersistAction extends EditDeckDescriptionAction {
  const EditDeckDescriptionPersistAction({
    required this.description,
    required this.formatAsMarkdown,
  });

  final String description;
  final bool formatAsMarkdown;
}

/// Ask the host to dismiss the dialog using a source dismissal variant.
final class EditDeckDescriptionDismissAction extends EditDeckDescriptionAction {
  const EditDeckDescriptionDismissAction(this.dismissal);

  final EditDeckDescriptionDismissal dismissal;
}

/// Portable state and action decisions for the Edit Deck Description dialog.
///
/// The host supplies the persisted values at [initialize] and applies actions
/// returned by this class. Collection access, saved-state persistence, flow
/// delivery, lifecycle, and dialog UI remain host-side.
final class EditDeckDescriptionDialogState {
  EditDeckDescriptionDialogState({
    String? restoredDescription,
    bool? restoredFormatAsMarkdown,
    bool restoredUserHasMadeChanges = false,
  }) : _description = restoredDescription ?? '',
       _formatAsMarkdown = restoredFormatAsMarkdown ?? false,
       _userHasMadeChanges = restoredUserHasMadeChanges;

  String _description;
  bool _formatAsMarkdown;
  bool _userHasMadeChanges;
  String? _initialDescription;
  bool? _initialFormatAsMarkdown;

  String get description => _description;

  set description(String value) {
    _userHasMadeChanges = true;
    _description = value;
  }

  bool get formatAsMarkdown => _formatAsMarkdown;

  set formatAsMarkdown(bool value) {
    _userHasMadeChanges = true;
    _formatAsMarkdown = value;
  }

  bool get userHasMadeChanges => _userHasMadeChanges;

  bool get isInitialStateComplete => _initialDescription != null;

  /// Compares both current values with the persisted state after initialization.
  bool get hasChanges =>
      isInitialStateComplete &&
      (_description != _initialDescription ||
          _formatAsMarkdown != _initialFormatAsMarkdown);

  /// Applies source initialization, retaining restored edits when marked dirty.
  void initialize({
    required String persistedDescription,
    required bool persistedFormatAsMarkdown,
  }) {
    _initialDescription = persistedDescription;
    _initialFormatAsMarkdown = persistedFormatAsMarkdown;
    if (!_userHasMadeChanges) {
      description = persistedDescription;
      formatAsMarkdown = persistedFormatAsMarkdown;
      _userHasMadeChanges = false;
    }
  }

  /// Resolves back to immediate close when unchanged, otherwise confirmation.
  EditDeckDescriptionBackAction onBackRequested() => hasChanges
      ? EditDeckDescriptionBackAction.showDiscardConfirmation
      : EditDeckDescriptionBackAction.closeWithoutSaving;

  /// Explicit close always dismisses without saving.
  EditDeckDescriptionDismissal closeWithoutSaving() =>
      EditDeckDescriptionDismissal.closedWithoutSaving;

  /// Returns host actions in source order: persist current values, then dismiss.
  List<EditDeckDescriptionAction> saveAndExitActions() =>
      List<EditDeckDescriptionAction>.unmodifiable([
        EditDeckDescriptionPersistAction(
          description: _description,
          formatAsMarkdown: _formatAsMarkdown,
        ),
        const EditDeckDescriptionDismissAction(
          EditDeckDescriptionDismissal.saved,
        ),
      ]);
}
