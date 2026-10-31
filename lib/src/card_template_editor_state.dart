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
 * SPDX-FileCopyrightText: 2025 Snowiee <xenonnn4w@gmail.com>
 * SPDX-FileCopyrightText: 2025 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditorState.kt and
 * CardTemplateEditorViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// The template editor view shown by AnkiDroid's Card Template Editor.
enum EditorViewType { front, back, styling }

/// Messages emitted by AnkiDroid's Card Template Editor state.
enum CardTemplateEditorUserMessage {
  cantDeleteLastTemplate,
  cantAddTemplateToDynamic,
  saveSuccess,
  deletionWouldOrphanNote,
}

/// Opaque host exception data carried by the source's ReportableException.
///
/// [source] is preserved as supplied; this model does not convert or interpret
/// platform errors. [isReportable] matches the source default.
final class ReportableExceptionData {
  const ReportableExceptionData({
    required this.source,
    this.isReportable = true,
  });

  final Object source;
  final bool isReportable;

  @override
  bool operator ==(Object other) =>
      other is ReportableExceptionData &&
      other.source == source &&
      other.isReportable == isReportable;

  @override
  int get hashCode => Object.hash(source, isReportable);
}

/// State variants for Card Template Editor.
sealed class CardTemplateEditorState {
  const CardTemplateEditorState();
}

/// Initial state before loading, or after initialization fails.
final class CardTemplateEditorInitializing extends CardTemplateEditorState {
  const CardTemplateEditorInitializing([this.exception]);

  final ReportableExceptionData? exception;

  @override
  bool operator ==(Object other) =>
      other is CardTemplateEditorInitializing && other.exception == exception;

  @override
  int get hashCode => Object.hash(runtimeType, exception);
}

/// Loaded editor state with the source defaults.
final class CardTemplateEditorLoaded extends CardTemplateEditorState {
  const CardTemplateEditorLoaded({
    this.currentTemplateOrd = 0,
    this.currentEditorView = EditorViewType.front,
    this.message,
    this.error,
  });

  final int currentTemplateOrd;
  final EditorViewType currentEditorView;
  final CardTemplateEditorUserMessage? message;
  final ReportableExceptionData? error;

  CardTemplateEditorLoaded withCurrentTemplateOrd(int value) =>
      CardTemplateEditorLoaded(
        currentTemplateOrd: value,
        currentEditorView: currentEditorView,
        message: message,
        error: error,
      );

  CardTemplateEditorLoaded withCurrentEditorView(EditorViewType value) =>
      CardTemplateEditorLoaded(
        currentTemplateOrd: currentTemplateOrd,
        currentEditorView: value,
        message: message,
        error: error,
      );

  CardTemplateEditorLoaded withoutMessage() => CardTemplateEditorLoaded(
    currentTemplateOrd: currentTemplateOrd,
    currentEditorView: currentEditorView,
    error: error,
  );

  CardTemplateEditorLoaded withoutError() => CardTemplateEditorLoaded(
    currentTemplateOrd: currentTemplateOrd,
    currentEditorView: currentEditorView,
    message: message,
  );

  @override
  bool operator ==(Object other) =>
      other is CardTemplateEditorLoaded &&
      other.currentTemplateOrd == currentTemplateOrd &&
      other.currentEditorView == currentEditorView &&
      other.message == message &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(currentTemplateOrd, currentEditorView, message, error);
}

/// Singleton state indicating that the editor should close.
final class CardTemplateEditorFinished extends CardTemplateEditorState {
  const CardTemplateEditorFinished._();

  static const instance = CardTemplateEditorFinished._();

  @override
  bool operator ==(Object other) => other is CardTemplateEditorFinished;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Portable state transitions from `CardTemplateEditorViewModel`.
///
/// The initial state is Initializing. The host retains StateFlow, Android
/// lifecycle, loading and persistence, rendering, and UI. State updates outside
/// Loaded return without replacing the current state.
final class CardTemplateEditorStateMachine {
  CardTemplateEditorStateMachine({
    CardTemplateEditorState initialState =
        const CardTemplateEditorInitializing(),
  }) : _state = initialState;

  CardTemplateEditorState _state;

  CardTemplateEditorState get state => _state;

  /// Replaces the current state with a fresh default Loaded value.
  void onLoadComplete() {
    _state = const CardTemplateEditorLoaded();
  }

  /// Replaces the current state with Initializing carrying the opaque failure.
  void onError(ReportableExceptionData exception) {
    _state = CardTemplateEditorInitializing(exception);
  }

  /// Replaces the current state with the Finished singleton.
  void onFinish() {
    _state = CardTemplateEditorFinished.instance;
  }

  void setCurrentTemplateOrd(int ord) =>
      _updateLoaded((loaded) => loaded.withCurrentTemplateOrd(ord));

  void setCurrentEditorView(EditorViewType viewType) =>
      _updateLoaded((loaded) => loaded.withCurrentEditorView(viewType));

  void clearMessage() => _updateLoaded((loaded) => loaded.withoutMessage());

  void clearError() => _updateLoaded((loaded) => loaded.withoutError());

  void _updateLoaded(
    CardTemplateEditorLoaded Function(CardTemplateEditorLoaded loaded) update,
  ) {
    final current = _state;
    if (current is CardTemplateEditorLoaded) {
      _state = update(current);
    }
  }
}
