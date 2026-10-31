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
 * Source-derived from CardTemplateFragment.deleteTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.deleteTemplate`.
///
/// Android JSON/model, logging, ordinal updates, pager, and UI behavior stay
/// host-side. Templates and adapters are opaque and retain their identity.
final class CardTemplateFragmentDeleteTemplateCallbacks<
  TTemplate,
  TTargetTemplate,
  TNotetype,
  TTemplates,
  TPagerAdapter,
  TPager,
  TTemporaryNoteType
> {
  const CardTemplateFragmentDeleteTemplateCallbacks({
    required this.readTemplates,
    required this.createEmptyTemplates,
    required this.templateOrdinal,
    required this.targetOrdinal,
    required this.appendTemplate,
    required this.logMatch,
    required this.readTemporaryNoteType,
    required this.removeTemplate,
    required this.assignTemplates,
    required this.updateTemplateOrdinals,
    required this.resolvePagerAdapterForOrdinalShift,
    required this.ordinalShift,
    required this.resolvePagerAdapterForNotification,
    required this.notifyDataSetChanged,
    required this.resolvePager,
    required this.templatesLength,
    required this.animationDisabled,
    required this.setCurrentItem,
  });

  final Iterable<TTemplate> Function(TNotetype notetype) readTemplates;
  final TTemplates Function() createEmptyTemplates;
  final int Function(TTemplate template) templateOrdinal;
  final int Function(TTargetTemplate template) targetOrdinal;
  final void Function(TTemplates templates, TTemplate template) appendTemplate;
  final void Function(int ordinal) logMatch;
  final TTemporaryNoteType Function() readTemporaryNoteType;
  final void Function(TTemporaryNoteType notetype, int ordinal) removeTemplate;
  final void Function(TNotetype notetype, TTemplates templates) assignTemplates;
  final void Function(TNotetype notetype) updateTemplateOrdinals;
  final TPagerAdapter Function() resolvePagerAdapterForOrdinalShift;
  final void Function(TPagerAdapter adapter) ordinalShift;
  final TPagerAdapter Function() resolvePagerAdapterForNotification;
  final void Function(TPagerAdapter adapter) notifyDataSetChanged;
  final TPager Function() resolvePager;
  final int Function(TTemplates templates) templatesLength;
  final bool Function() animationDisabled;
  final void Function(TPager pager, int index, bool animationDisabled)
  setCurrentItem;
}

/// Runs the host callback sequence for `CardTemplateFragment.deleteTemplate`.
///
/// Matching templates are logged and removed one at a time while all other
/// template objects are appended unchanged. The source's callback order,
/// repeated ordinal reads, empty/missing-match behavior, and failure boundaries
/// are preserved; callback failures propagate immediately.
void cardTemplateFragmentDeleteTemplate<
  TTemplate,
  TTargetTemplate,
  TNotetype,
  TTemplates,
  TPagerAdapter,
  TPager,
  TTemporaryNoteType
>({
  required TTargetTemplate tmpl,
  required TNotetype notetype,
  required CardTemplateFragmentDeleteTemplateCallbacks<
    TTemplate,
    TTargetTemplate,
    TNotetype,
    TTemplates,
    TPagerAdapter,
    TPager,
    TTemporaryNoteType
  >
  callbacks,
}) {
  final oldTemplates = callbacks.readTemplates(notetype);
  final newTemplates = callbacks.createEmptyTemplates();
  for (final possibleMatch in oldTemplates) {
    if (callbacks.templateOrdinal(possibleMatch) !=
        callbacks.targetOrdinal(tmpl)) {
      callbacks.appendTemplate(newTemplates, possibleMatch);
    } else {
      callbacks.logMatch(callbacks.templateOrdinal(possibleMatch));
      callbacks.removeTemplate(
        callbacks.readTemporaryNoteType(),
        callbacks.templateOrdinal(possibleMatch),
      );
    }
  }

  callbacks.assignTemplates(notetype, newTemplates);
  callbacks.updateTemplateOrdinals(notetype);
  callbacks.ordinalShift(callbacks.resolvePagerAdapterForOrdinalShift());
  callbacks.notifyDataSetChanged(
    callbacks.resolvePagerAdapterForNotification(),
  );
  callbacks.setCurrentItem(
    callbacks.resolvePager(),
    callbacks.templatesLength(newTemplates) - 1,
    callbacks.animationDisabled(),
  );
}
