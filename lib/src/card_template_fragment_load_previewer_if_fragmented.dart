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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

/// Host callbacks used by [cardTemplateFragmentLoadPreviewerIfFragmented].
///
/// Android, collection, model, fragment, resource, and layout types remain with
/// the host. [launchCatchingTask] and [withCol] retain the host's scheduling,
/// collection, and failure boundaries; [post] retains deferred view work.
final class CardTemplateFragmentLoadPreviewerIfFragmentedCallbacks<
  TContext,
  TNotetype,
  TCollection,
  TFragment,
  TNote,
  TNotetypeFile,
  TOrdinal,
  TNoteId,
  TFields,
  TTags,
  TArguments,
  TView,
  TButton,
  TButtonContext,
  TLayoutParams,
  TMarginLayoutParams,
  TContainer
> {
  const CardTemplateFragmentLoadPreviewerIfFragmentedCallbacks({
    required this.pagerCurrentItem,
    required this.fragmented,
    required this.launchCatchingTask,
    required this.notetype,
    required this.activityContext,
    required this.createNotetypeFile,
    required this.withCol,
    required this.currentFragment,
    required this.getNote,
    required this.notetypeId,
    required this.createNoteFromNotetypeId,
    required this.noteId,
    required this.fields,
    required this.tags,
    required this.createArguments,
    required this.createFragment,
    required this.fragmentContainerId,
    required this.commitNow,
    required this.fragmentView,
    required this.post,
    required this.showAnswerButton,
    required this.buttonLayoutParams,
    required this.buttonContext,
    required this.toPx,
    required this.setButtonHeight,
    required this.requestButtonLayout,
    required this.webViewContainer,
    required this.containerLayoutParams,
    required this.asMarginLayoutParams,
    required this.reviewerSideMarginPx,
    required this.setTopMargin,
    required this.assignContainerLayoutParams,
  });

  /// Resolves the pager's current item. Called only when [ordinal] is omitted,
  /// before reading [fragmented].
  final TOrdinal Function() pagerCurrentItem;
  final bool Function() fragmented;

  /// The host owns asynchronous task scheduling and error handling.
  final void Function(Future<void> Function() action) launchCatchingTask;
  final TNotetype Function() notetype;
  final TContext Function() activityContext;
  final TNotetypeFile Function(TContext context, TNotetype notetype)
  createNotetypeFile;
  final Future<TResult> Function<TResult>(
    TResult Function(TCollection collection) action,
  )
  withCol;
  final TFragment? Function() currentFragment;
  final TNote? Function(TFragment fragment, TCollection collection) getNote;
  final TNoteId Function(TNotetype notetype) notetypeId;
  final TNote Function(TCollection collection, TNoteId notetypeId)
  createNoteFromNotetypeId;
  final TNoteId Function(TNote note) noteId;
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
  final TFragment Function(TArguments arguments) createFragment;
  final Object Function() fragmentContainerId;
  final void Function(Object containerId, TFragment fragment) commitNow;
  final TView? Function(TFragment fragment) fragmentView;

  /// Schedules [callback] to run when the host's view post queue executes it.
  final void Function(TView view, void Function() callback) post;
  final TButton Function(TFragment fragment) showAnswerButton;
  final TLayoutParams Function(TButton button) buttonLayoutParams;
  final TButtonContext Function(TButton button) buttonContext;
  final int Function(int dp, TButtonContext context) toPx;
  final void Function(TLayoutParams params, int height) setButtonHeight;
  final void Function(TButton button) requestButtonLayout;
  final TContainer Function(TFragment fragment) webViewContainer;
  final Object Function(TContainer container) containerLayoutParams;

  /// Performs the host's runtime cast; cast failures must propagate.
  final TMarginLayoutParams Function(Object params) asMarginLayoutParams;
  final int Function() reviewerSideMarginPx;
  final void Function(TMarginLayoutParams params, int topMargin) setTopMargin;
  final void Function(TContainer container, Object params)
  assignContainerLayoutParams;
}

/// Loads or reloads the host preview fragment only in fragmented mode.
///
/// Omission of [ordinal] reads the pager before the fragmented guard, matching
/// Kotlin's default-argument evaluation. The task body remains inside the
/// host's [CardTemplateFragmentLoadPreviewerIfFragmentedCallbacks.launchCatchingTask]
/// boundary, and layout work remains deferred to the posted view callback.
void cardTemplateFragmentLoadPreviewerIfFragmented<
  TContext,
  TNotetype,
  TCollection,
  TFragment,
  TNote,
  TNotetypeFile,
  TOrdinal,
  TNoteId,
  TFields,
  TTags,
  TArguments,
  TView,
  TButton,
  TButtonContext,
  TLayoutParams,
  TMarginLayoutParams,
  TContainer
>({
  required CardTemplateFragmentLoadPreviewerIfFragmentedCallbacks<
    TContext,
    TNotetype,
    TCollection,
    TFragment,
    TNote,
    TNotetypeFile,
    TOrdinal,
    TNoteId,
    TFields,
    TTags,
    TArguments,
    TView,
    TButton,
    TButtonContext,
    TLayoutParams,
    TMarginLayoutParams,
    TContainer
  >
  callbacks,
  TOrdinal? ordinal,
}) {
  final selectedOrdinal = ordinal ?? callbacks.pagerCurrentItem();
  if (!callbacks.fragmented()) {
    return;
  }

  callbacks.launchCatchingTask(() async {
    final notetype = callbacks.notetype();
    final notetypeFile = callbacks.createNotetypeFile(
      callbacks.activityContext(),
      notetype,
    );
    final note = await callbacks.withCol((collection) {
      final fragment = callbacks.currentFragment();
      final currentNote = fragment == null
          ? null
          : callbacks.getNote(fragment, collection);
      return currentNote ??
          callbacks.createNoteFromNotetypeId(
            collection,
            callbacks.notetypeId(notetype),
          );
    });
    final arguments = callbacks.createArguments(
      notetypeFile,
      callbacks.noteId(note),
      selectedOrdinal,
      callbacks.fields(note),
      callbacks.tags(note),
      fillEmpty: true,
    );
    final fragment = callbacks.createFragment(arguments);
    callbacks.commitNow(callbacks.fragmentContainerId(), fragment);

    final view = callbacks.fragmentView(fragment);
    if (view == null) {
      return;
    }
    callbacks.post(view, () {
      final button = callbacks.showAnswerButton(fragment);
      final buttonLayoutParams = callbacks.buttonLayoutParams(button);
      callbacks.setButtonHeight(
        buttonLayoutParams,
        callbacks.toPx(80, callbacks.buttonContext(button)),
      );
      callbacks.requestButtonLayout(button);

      final webViewContainer = callbacks.webViewContainer(fragment);
      final layoutParams = callbacks.containerLayoutParams(webViewContainer);
      final marginLayoutParams = callbacks.asMarginLayoutParams(layoutParams);
      callbacks.setTopMargin(
        marginLayoutParams,
        callbacks.reviewerSideMarginPx(),
      );
      callbacks.assignContainerLayoutParams(webViewContainer, layoutParams);
    });
  });
}
