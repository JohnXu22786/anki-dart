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
 * Source-derived from CardTemplateEditor.onCollectionLoaded in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host operations used by `CardTemplateEditor.onCollectionLoaded`.
///
/// Collection and note-type model operations, Android views/adapters, tab
/// mediation, ActionBar/resources, logging, and editor lifecycle stay on the
/// host. This class only exposes their source-order boundaries.
final class CardTemplateEditorOnCollectionLoadedCallbacks<
  TCollection,
  TNoteTypeId,
  TNoteType,
  TOriginalNoteType,
  TFieldNames,
  TEditor,
  TPager,
  TTabs,
  TMediator,
  TTab,
  TActionBar
> {
  const CardTemplateEditorOnCollectionLoadedCallbacks({
    required this.superOnCollectionLoaded,
    required this.clearNotetypeCache,
    required this.readTemporaryNoteType,
    required this.lookupNoteType,
    required this.requireNoteType,
    required this.deepCloneNoteType,
    required this.assignTemporaryNoteType,
    required this.readFieldNames,
    required this.assignFieldNames,
    required this.readPager,
    required this.createPagerAdapter,
    required this.assignPagerAdapter,
    required this.setOffscreenPageLimit,
    required this.readTabs,
    required this.createTabMediator,
    required this.attachTabMediator,
    required this.readTemplate,
    required this.readTemplateName,
    required this.configureTabText,
    required this.readSupportActionBar,
    required this.setActionBarTitle,
    required this.readNoteTypeName,
    required this.setActionBarSubtitle,
    required this.logInfo,
    required this.logDebug,
    required this.animationDisabled,
    required this.setCurrentPage,
    required this.updateDiscardChangesCallback,
  });

  final void Function(TCollection collection) superOnCollectionLoaded;
  final void Function(TCollection collection) clearNotetypeCache;
  final TNoteType? Function() readTemporaryNoteType;
  final TOriginalNoteType? Function(
    TCollection collection,
    TNoteTypeId noteTypeId,
  )
  lookupNoteType;
  final TOriginalNoteType Function(TOriginalNoteType? noteType) requireNoteType;
  final TNoteType Function(TOriginalNoteType noteType) deepCloneNoteType;
  final void Function(TNoteType noteType) assignTemporaryNoteType;
  final TFieldNames Function(TNoteType noteType) readFieldNames;
  final void Function(TFieldNames fieldNames) assignFieldNames;
  final TPager Function() readPager;
  final Object Function(TEditor editor) createPagerAdapter;
  final void Function(TPager pager, Object adapter) assignPagerAdapter;
  final void Function(TPager pager, int limit) setOffscreenPageLimit;
  final TTabs Function() readTabs;
  final TMediator Function(
    TTabs tabs,
    TPager pager,
    void Function(TTab tab, int position) configureTab,
  )
  createTabMediator;
  final void Function(TMediator mediator) attachTabMediator;
  final Object Function(TNoteType noteType, int position) readTemplate;
  final String Function(Object template) readTemplateName;
  final void Function(TTab tab, String name) configureTabText;
  final TActionBar? Function() readSupportActionBar;
  final void Function(TActionBar actionBar) setActionBarTitle;
  final String Function(TNoteType noteType) readNoteTypeName;
  final void Function(TActionBar actionBar, String name) setActionBarSubtitle;
  final void Function(String message, TNoteTypeId noteTypeId) logInfo;
  final void Function(String message, int startingOrdinal) logDebug;
  final bool Function() animationDisabled;
  final void Function(TPager pager, int ordinal, bool animated) setCurrentPage;
  final void Function() updateDiscardChangesCallback;
}

/// Runs the host callbacks for `CardTemplateEditor.onCollectionLoaded` in source
/// order. Host failures propagate immediately and stop later operations.
void cardTemplateEditorOnCollectionLoaded<
  TCollection,
  TNoteTypeId,
  TNoteType,
  TOriginalNoteType,
  TFieldNames,
  TEditor,
  TPager,
  TTabs,
  TMediator,
  TTab,
  TActionBar
>({
  required TCollection collection,
  required TNoteTypeId originalNoteTypeId,
  required int startingOrdinal,
  required TEditor editor,
  required CardTemplateEditorOnCollectionLoadedCallbacks<
    TCollection,
    TNoteTypeId,
    TNoteType,
    TOriginalNoteType,
    TFieldNames,
    TEditor,
    TPager,
    TTabs,
    TMediator,
    TTab,
    TActionBar
  >
  callbacks,
}) {
  callbacks.superOnCollectionLoaded(collection);
  callbacks.clearNotetypeCache(collection);

  if (callbacks.readTemporaryNoteType() == null) {
    final originalNoteType = callbacks.lookupNoteType(
      collection,
      originalNoteTypeId,
    );
    final requiredNoteType = callbacks.requireNoteType(originalNoteType);
    final clonedNoteType = callbacks.deepCloneNoteType(requiredNoteType);
    callbacks.assignTemporaryNoteType(clonedNoteType);
  }

  final temporaryNoteType = callbacks.readTemporaryNoteType()!;
  callbacks.assignFieldNames(callbacks.readFieldNames(temporaryNoteType));

  final pagerForAdapter = callbacks.readPager();
  final adapter = callbacks.createPagerAdapter(editor);
  callbacks.assignPagerAdapter(pagerForAdapter, adapter);

  final pagerForLimit = callbacks.readPager();
  callbacks.setOffscreenPageLimit(pagerForLimit, 7);

  final tabs = callbacks.readTabs();
  final pagerForMediator = callbacks.readPager();
  final mediator = callbacks.createTabMediator(tabs, pagerForMediator, (
    tab,
    position,
  ) {
    final currentNoteType = callbacks.readTemporaryNoteType()!;
    final template = callbacks.readTemplate(currentNoteType, position);
    final templateName = callbacks.readTemplateName(template);
    callbacks.configureTabText(tab, templateName);
  });
  callbacks.attachTabMediator(mediator);

  final actionBar = callbacks.readSupportActionBar();
  if (actionBar != null) {
    callbacks.setActionBarTitle(actionBar);
    final currentNoteType = callbacks.readTemporaryNoteType()!;
    final noteTypeName = callbacks.readNoteTypeName(currentNoteType);
    callbacks.setActionBarSubtitle(actionBar, noteTypeName);
  }

  callbacks.logInfo(
    'CardTemplateEditor:: Card template editor successfully started for note type id %d',
    originalNoteTypeId,
  );
  callbacks.logDebug('Setting starting tab to %d', startingOrdinal);
  if (startingOrdinal != -1) {
    final pager = callbacks.readPager();
    final animated = callbacks.animationDisabled();
    callbacks.setCurrentPage(pager, startingOrdinal, animated);
  }
  callbacks.updateDiscardChangesCallback();
}
