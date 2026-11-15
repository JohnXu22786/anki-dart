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
 * Behavioral reference: CardBrowserFragment.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectBrowserChangeNoteTypePresentation', () {
    test('no selection produces no user-visible action', () {
      expect(
        projectBrowserChangeNoteTypePresentation(
          const BrowserChangeNoteTypeNoSelection(),
        ),
        isNull,
      );
    });

    test('mixed selection requests the source snackbar resource', () {
      final directive = projectBrowserChangeNoteTypePresentation(
        const BrowserChangeNoteTypeMixedSelection(),
      );

      expect(directive, isA<BrowserChangeNoteTypeSnackbar>());
      expect(
        (directive as BrowserChangeNoteTypeSnackbar).messageResource,
        BrowserChangeNoteTypeResourceId.differentNoteTypesSelected,
      );
    });

    test(
      'compatible selection passes its exact note ID list to the dialog',
      () {
        final response = BrowserChangeNoteTypeSelection.fromNoteIds(const [
          7,
          3,
        ]);
        final directive = projectBrowserChangeNoteTypePresentation(response);

        expect(directive, isA<BrowserChangeNoteTypeDialog>());
        final dialog = directive as BrowserChangeNoteTypeDialog;
        expect(dialog.noteIds, [7, 3]);
        expect(dialog.noteIds, same(response.noteIds));
      },
    );
  });
}
