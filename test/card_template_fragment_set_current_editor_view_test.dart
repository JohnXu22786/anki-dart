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
  group('cardTemplateFragmentSetCurrentEditorView', () {
    test('missing cursor maps skip selection read and default to zero', () {
      final events = <String>[];
      final mapLookups = <int>[];
      cardTemplateFragmentSetCurrentEditorView(
        cardId: 7,
        viewId: 12,
        editorContent: 'Back content',
        readCursorPositionMap: (cardId) {
          events.add('map');
          mapLookups.add(cardId);
          return null;
        },
        readSelectionStart: () {
          events.add('selectionStart');
          return 5;
        },
        saveSelectionForCurrentView: (map, start) => events.add('save'),
        setCurrentEditorViewId: (id) => events.add('viewId:$id'),
        setText: (text) => events.add('text:$text'),
        isCurrentPage: () {
          events.add('isCurrentPage');
          return false;
        },
        requestFocus: () => events.add('focus'),
        readCursorPosition: (map, id) {
          events.add('cursor:$id');
          return 90;
        },
        setSelection: (offset) => events.add('setSelection:$offset'),
      );

      expect(mapLookups, [7, 7]);
      expect(events, [
        'map',
        'viewId:12',
        'text:Back content',
        'isCurrentPage',
        'map',
        'setSelection:0',
      ]);
    });

    test(
      'saves old-view selection before changing id and reads a fresh map',
      () {
        final events = <String>[];
        final firstMap = Object();
        final secondMap = Object();
        var lookups = 0;
        cardTemplateFragmentSetCurrentEditorView(
          cardId: 4,
          viewId: 21,
          editorContent: 'exact <b>Front</b>',
          readCursorPositionMap: (cardId) {
            events.add('map:${++lookups}');
            return lookups == 1 ? firstMap : secondMap;
          },
          readSelectionStart: () {
            events.add('selectionStart');
            return 6;
          },
          saveSelectionForCurrentView: (map, start) {
            events.add('saveOld:$start:${identical(map, firstMap)}');
          },
          setCurrentEditorViewId: (id) => events.add('viewId:$id'),
          setText: (text) => events.add('text:$text'),
          isCurrentPage: () {
            events.add('isCurrentPage');
            return true;
          },
          requestFocus: () => events.add('focus'),
          readCursorPosition: (map, id) {
            events.add('cursor:$id:${identical(map, secondMap)}');
            return 137;
          },
          setSelection: (offset) => events.add('setSelection:$offset'),
        );

        expect(events, [
          'map:1',
          'selectionStart',
          'saveOld:6:true',
          'viewId:21',
          'text:exact <b>Front</b>',
          'isCurrentPage',
          'focus',
          'map:2',
          'cursor:21:true',
          'setSelection:137',
        ]);
      },
    );

    test(
      'non-current page skips focus and new absent map defaults to zero',
      () {
        final events = <String>[];
        final oldMap = Object();
        cardTemplateFragmentSetCurrentEditorView(
          cardId: 3,
          viewId: 8,
          editorContent: 'Styling',
          readCursorPositionMap: (cardId) {
            events.add('map');
            return events.where((event) => event == 'map').length == 1
                ? oldMap
                : null;
          },
          readSelectionStart: () {
            events.add('selectionStart');
            return 2;
          },
          saveSelectionForCurrentView: (map, start) =>
              events.add('save:$start'),
          setCurrentEditorViewId: (id) => events.add('viewId'),
          setText: (text) => events.add('text'),
          isCurrentPage: () {
            events.add('isCurrentPage');
            return false;
          },
          requestFocus: () => events.add('focus'),
          readCursorPosition: (map, id) {
            events.add('cursor');
            return 99;
          },
          setSelection: (offset) => events.add('setSelection:$offset'),
        );

        expect(events, [
          'map',
          'selectionStart',
          'save:2',
          'viewId',
          'text',
          'isCurrentPage',
          'map',
          'setSelection:0',
        ]);
      },
    );

    test(
      'propagates each callback failure unchanged and stops later callbacks',
      () {
        final callbacks = <String Function()>[
          () => 'map',
          () => 'selectionStart',
          () => 'save',
          () => 'viewId',
          () => 'text',
          () => 'isCurrentPage',
          () => 'focus',
          () => 'map',
          () => 'cursor',
          () => 'setSelection',
        ];
        for (
          var failingIndex = 0;
          failingIndex < callbacks.length;
          failingIndex++
        ) {
          final failure = StateError('failure $failingIndex');
          final events = <String>[];
          final map = Object();
          var mapReads = 0;
          expect(
            () => cardTemplateFragmentSetCurrentEditorView(
              cardId: 1,
              viewId: 2,
              editorContent: 'content',
              readCursorPositionMap: (cardId) {
                final readNumber = mapReads++;
                events.add(callbacks[readNumber == 0 ? 0 : 7]());
                if ((readNumber == 0 && failingIndex == 0) ||
                    (readNumber == 1 && failingIndex == 7)) {
                  throw failure;
                }
                return map;
              },
              readSelectionStart: () {
                events.add(callbacks[1]());
                if (failingIndex == 1) throw failure;
                return 4;
              },
              saveSelectionForCurrentView: (map, start) {
                events.add(callbacks[2]());
                if (failingIndex == 2) throw failure;
              },
              setCurrentEditorViewId: (id) {
                events.add(callbacks[3]());
                if (failingIndex == 3) throw failure;
              },
              setText: (text) {
                events.add(callbacks[4]());
                if (failingIndex == 4) throw failure;
              },
              isCurrentPage: () {
                events.add(callbacks[5]());
                if (failingIndex == 5) throw failure;
                return true;
              },
              requestFocus: () {
                events.add(callbacks[6]());
                if (failingIndex == 6) throw failure;
              },
              readCursorPosition: (map, id) {
                events.add(callbacks[8]());
                if (failingIndex == 8) throw failure;
                return 3;
              },
              setSelection: (offset) {
                events.add(callbacks[9]());
                if (failingIndex == 9) throw failure;
              },
            ),
            throwsA(same(failure)),
          );
          expect(events, hasLength(failingIndex + 1));
        }
      },
    );
  });
}
