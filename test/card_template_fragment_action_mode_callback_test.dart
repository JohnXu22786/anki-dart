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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardTemplateFragment ActionMode.Callback', () {
    test('prepare returns before size and editor reads when item exists', () {
      final events = <String>[];

      final changed = cardTemplateFragmentActionModeOnPrepare(
        insertFieldId: 1,
        stylingEditId: 10,
        menuFirst: -1,
        findItem: (id) {
          events.add('find:$id');
          return Object();
        },
        readMenuSize: () {
          events.add('size');
          return 0;
        },
        readCurrentEditorViewId: () {
          events.add('view');
          return 0;
        },
        readInsertFieldTitle: () {
          events.add('title');
          return 'Insert field';
        },
        addMenuItem: (groupId, itemId, order, title) => events.add('add'),
      );

      expect(changed, isFalse);
      expect(events, ['find:1']);
    });

    test('prepare adds the localized item and compares final menu size', () {
      final events = <String>[];
      var sizeReads = 0;

      final changed = cardTemplateFragmentActionModeOnPrepare(
        insertFieldId: 1,
        stylingEditId: 10,
        menuFirst: -1,
        findItem: (id) {
          events.add('find:$id');
          return null;
        },
        readMenuSize: () {
          events.add('size:${++sizeReads}');
          return sizeReads == 1 ? 2 : 3;
        },
        readCurrentEditorViewId: () {
          events.add('view');
          return 11;
        },
        readInsertFieldTitle: () {
          events.add('title');
          return 'Insert field';
        },
        addMenuItem: (groupId, itemId, order, title) {
          events.add('add:$groupId:$itemId:$order:$title');
        },
      );

      expect(changed, isTrue);
      expect(events, [
        'find:1',
        'size:1',
        'view',
        'title',
        'add:-1:1:0:Insert field',
        'size:2',
      ]);
    });

    test('styling editor skips title and add but still compares menu size', () {
      final events = <String>[];
      var sizeReads = 0;

      final changed = cardTemplateFragmentActionModeOnPrepare(
        insertFieldId: 1,
        stylingEditId: 10,
        menuFirst: -1,
        findItem: (id) {
          events.add('find:$id');
          return null;
        },
        readMenuSize: () {
          events.add('size:${++sizeReads}');
          return 4;
        },
        readCurrentEditorViewId: () {
          events.add('view');
          return 10;
        },
        readInsertFieldTitle: () {
          events.add('title');
          return 'Insert field';
        },
        addMenuItem: (groupId, itemId, order, title) => events.add('add'),
      );

      expect(changed, isFalse);
      expect(events, ['find:1', 'size:1', 'view', 'size:2']);
    });

    test('prepare returns false when add does not change menu size', () {
      final events = <String>[];

      final changed = cardTemplateFragmentActionModeOnPrepare(
        insertFieldId: 1,
        stylingEditId: 10,
        menuFirst: -1,
        findItem: (id) => null,
        readMenuSize: () => 2,
        readCurrentEditorViewId: () => 11,
        readInsertFieldTitle: () => 'Insert field',
        addMenuItem: (groupId, itemId, order, title) => events.add('add'),
      );

      expect(changed, isFalse);
      expect(events, ['add']);
    });

    test('item click reads id once, opens dialog, then finishes', () {
      final events = <String>[];
      var itemIdReads = 0;

      final handled = cardTemplateFragmentActionModeOnActionItemClicked(
        insertFieldId: 1,
        readItemId: () {
          itemIdReads++;
          events.add('item-id');
          return 1;
        },
        showInsertFieldDialog: () => events.add('dialog'),
        finishActionMode: () => events.add('finish'),
      );

      expect(handled, isTrue);
      expect(itemIdReads, 1);
      expect(events, ['item-id', 'dialog', 'finish']);
    });

    test('unmatched item does not show dialog or finish', () {
      final events = <String>[];

      final handled = cardTemplateFragmentActionModeOnActionItemClicked(
        insertFieldId: 1,
        readItemId: () {
          events.add('item-id');
          return 2;
        },
        showInsertFieldDialog: () => events.add('dialog'),
        finishActionMode: () => events.add('finish'),
      );

      expect(handled, isFalse);
      expect(events, ['item-id']);
    });

    test('dialog failure prevents action mode finish', () {
      final events = <String>[];
      final failure = StateError('dialog failed');

      expect(
        () => cardTemplateFragmentActionModeOnActionItemClicked(
          insertFieldId: 1,
          readItemId: () => 1,
          showInsertFieldDialog: () {
            events.add('dialog');
            throw failure;
          },
          finishActionMode: () => events.add('finish'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['dialog']);
    });
  });
}
