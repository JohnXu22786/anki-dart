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
 * Source-derived from CardTemplateFragment.addNewTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.addNewTemplate`.
///
/// Android arguments, templates, note-type mutation, logging, adapter, pager,
/// and UI remain host-side. Opaque values retain their identity across calls.
final class CardTemplateFragmentAddNewTemplateCallbacks<
  TTemplate,
  TNewTemplate,
  TNoteType,
  TTemplates,
  TPagerAdapter,
  TPager,
  TTemporaryNoteType
> {
  const CardTemplateFragmentAddNewTemplateCallbacks({
    required this.readCardIndex,
    required this.readTemplates,
    required this.templateAt,
    required this.newCardName,
    required this.createTemplate,
    required this.question,
    required this.setQuestion,
    required this.answer,
    required this.setAnswer,
    required this.templatesLength,
    required this.flipQA,
    required this.lastTemplate,
    required this.templateOrdinal,
    required this.logLastOrdinal,
    required this.setOrdinal,
    required this.appendTemplate,
    required this.readTemporaryNoteType,
    required this.addTemporaryTemplate,
    required this.resolvePagerAdapter,
    required this.notifyDataSetChanged,
    required this.resolvePager,
    required this.animationDisabled,
    required this.setCurrentItem,
  });

  final int Function() readCardIndex;
  final TTemplates Function(TNoteType noteType) readTemplates;
  final TTemplate Function(TTemplates templates, int index) templateAt;
  final String Function(TTemplates templates) newCardName;
  final TNewTemplate Function(String name) createTemplate;
  final String Function(TTemplate template) question;
  final void Function(TNewTemplate template, String value) setQuestion;
  final String Function(TTemplate template) answer;
  final void Function(TNewTemplate template, String value) setAnswer;
  final int Function(TTemplates templates) templatesLength;
  final void Function(TNewTemplate template) flipQA;
  final TTemplate Function(TTemplates templates) lastTemplate;
  final int Function(TTemplate template) templateOrdinal;
  final void Function(int ordinal) logLastOrdinal;
  final void Function(TNewTemplate template, int ordinal) setOrdinal;
  final void Function(TTemplates templates, TNewTemplate template)
  appendTemplate;
  final TTemporaryNoteType Function() readTemporaryNoteType;
  final void Function(TTemporaryNoteType noteType, TNewTemplate template)
  addTemporaryTemplate;
  final TPagerAdapter Function() resolvePagerAdapter;
  final void Function(TPagerAdapter adapter) notifyDataSetChanged;
  final TPager Function() resolvePager;
  final bool Function() animationDisabled;
  final void Function(TPager pager, int index, bool animationDisabled)
  setCurrentItem;
}

/// Runs the source-ordered callbacks for `CardTemplateFragment.addNewTemplate`.
///
/// The existing templates collection is read once and passed to both the
/// selected-template and new-name callbacks. Callback failures propagate
/// unchanged and stop all later effects; ordinal addition uses JVM Int32 wrap.
void cardTemplateFragmentAddNewTemplate<
  TTemplate,
  TNewTemplate,
  TNoteType,
  TTemplates,
  TPagerAdapter,
  TPager,
  TTemporaryNoteType
>({
  required TNoteType noteType,
  required CardTemplateFragmentAddNewTemplateCallbacks<
    TTemplate,
    TNewTemplate,
    TNoteType,
    TTemplates,
    TPagerAdapter,
    TPager,
    TTemporaryNoteType
  >
  callbacks,
}) {
  final oldCardIndex = callbacks.readCardIndex();
  final templates = callbacks.readTemplates(noteType);
  final oldTemplate = callbacks.templateAt(templates, oldCardIndex);
  final newTemplate = callbacks.createTemplate(
    callbacks.newCardName(templates),
  );

  callbacks.setQuestion(newTemplate, callbacks.question(oldTemplate));
  callbacks.setAnswer(newTemplate, callbacks.answer(oldTemplate));
  if (callbacks.templatesLength(templates) == 1) {
    callbacks.flipQA(newTemplate);
  }

  final lastExistingOrdinal = callbacks.templateOrdinal(
    callbacks.lastTemplate(templates),
  );
  callbacks.logLastOrdinal(lastExistingOrdinal);
  callbacks.setOrdinal(newTemplate, _toInt32(lastExistingOrdinal + 1));
  callbacks.appendTemplate(templates, newTemplate);
  callbacks.addTemporaryTemplate(
    callbacks.readTemporaryNoteType(),
    newTemplate,
  );
  callbacks.notifyDataSetChanged(callbacks.resolvePagerAdapter());
  callbacks.setCurrentItem(
    callbacks.resolvePager(),
    callbacks.templatesLength(templates) - 1,
    callbacks.animationDisabled(),
  );
}

int _toInt32(int value) {
  final wrapped = value & 0xffffffff;
  return wrapped >= 0x80000000 ? wrapped - 0x100000000 : wrapped;
}
