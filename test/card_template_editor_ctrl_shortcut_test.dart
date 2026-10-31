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
 * the pinned CardTemplateEditorTest only directly covers Ctrl+2.
 * See ANKIDROID_UPSTREAM.md for the other source-derived branches.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('dispatchCardTemplateEditorCtrlShortcut', () {
    test('null fragment skips Ctrl state and immediately falls back', () {
      final event = Object();
      final reached = <String>[];
      final result = dispatchCardTemplateEditorCtrlShortcut<Object, Object>(
        keyCode: 42,
        event: event,
        keyCodes: _keyCodes,
        callbacks: CardTemplateEditorCtrlShortcutCallbacks<Object, Object>(
          currentFragment: () {
            reached.add('fragment');
            return null;
          },
          isCtrlPressed: (_) {
            reached.add('ctrl');
            return true;
          },
          superclassOnKeyUp: (keyCode, receivedEvent) {
            reached.add('fallback');
            expect(keyCode, 42);
            expect(identical(receivedEvent, event), isTrue);
            return false;
          },
          log: (_) => reached.add('log'),
          performAction: (_, __) => reached.add('action'),
        ),
      );

      expect(result, isFalse);
      expect(reached, ['fragment', 'fallback']);
    });

    test('non-Ctrl event falls back without changing key or event', () {
      final fragment = Object();
      final event = Object();
      final reached = <String>[];
      final result = dispatchCardTemplateEditorCtrlShortcut<Object, Object>(
        keyCode: 42,
        event: event,
        keyCodes: _keyCodes,
        callbacks: CardTemplateEditorCtrlShortcutCallbacks<Object, Object>(
          currentFragment: () {
            reached.add('fragment');
            return fragment;
          },
          isCtrlPressed: (receivedEvent) {
            reached.add('ctrl');
            expect(identical(receivedEvent, event), isTrue);
            return false;
          },
          superclassOnKeyUp: (keyCode, receivedEvent) {
            reached.add('fallback');
            expect(keyCode, 42);
            expect(identical(receivedEvent, event), isTrue);
            return true;
          },
          log: (_) => reached.add('log'),
          performAction: (_, __) => reached.add('action'),
        ),
      );

      expect(result, isTrue);
      expect(reached, ['fragment', 'ctrl', 'fallback']);
    });

    test('unknown Ctrl key falls back after fragment and modifier reads', () {
      final fragment = Object();
      final event = Object();
      final reached = <String>[];
      final result = dispatchCardTemplateEditorCtrlShortcut<Object, Object>(
        keyCode: 42,
        event: event,
        keyCodes: _keyCodes,
        callbacks: CardTemplateEditorCtrlShortcutCallbacks<Object, Object>(
          currentFragment: () {
            reached.add('fragment');
            return fragment;
          },
          isCtrlPressed: (_) {
            reached.add('ctrl');
            return true;
          },
          superclassOnKeyUp: (keyCode, receivedEvent) {
            reached.add('fallback');
            expect(keyCode, 42);
            expect(identical(receivedEvent, event), isTrue);
            return false;
          },
          log: (_) => reached.add('log'),
          performAction: (_, __) => reached.add('action'),
        ),
      );

      expect(result, isFalse);
      expect(reached, ['fragment', 'ctrl', 'fallback']);
    });

    test(
      'maps every keycode, logs first, and acts once on the same fragment',
      () {
        const cases = <(int, CardTemplateEditorCtrlAction)>[
          (10, CardTemplateEditorCtrlAction.performPreview),
          (11, CardTemplateEditorCtrlAction.selectFrontTab),
          (12, CardTemplateEditorCtrlAction.selectBackTab),
          (13, CardTemplateEditorCtrlAction.selectStylingTab),
          (14, CardTemplateEditorCtrlAction.saveNoteType),
          (15, CardTemplateEditorCtrlAction.showInsertFieldDialog),
          (16, CardTemplateEditorCtrlAction.addCardTemplate),
          (17, CardTemplateEditorCtrlAction.showRenameDialog),
          (18, CardTemplateEditorCtrlAction.openBrowserAppearance),
          (19, CardTemplateEditorCtrlAction.deleteCardTemplate),
          (20, CardTemplateEditorCtrlAction.displayDeckOverrideDialog),
          (21, CardTemplateEditorCtrlAction.copyMarkdown),
        ];

        for (final (keyCode, expectedAction) in cases) {
          final fragment = Object();
          final event = Object();
          final reached = <String>[];
          final result = dispatchCardTemplateEditorCtrlShortcut<Object, Object>(
            keyCode: keyCode,
            event: event,
            keyCodes: _keyCodes,
            callbacks: CardTemplateEditorCtrlShortcutCallbacks<Object, Object>(
              currentFragment: () {
                reached.add('fragment');
                return fragment;
              },
              isCtrlPressed: (receivedEvent) {
                reached.add('ctrl');
                expect(identical(receivedEvent, event), isTrue);
                return true;
              },
              superclassOnKeyUp: (_, __) {
                reached.add('fallback');
                return false;
              },
              log: (action) {
                reached.add('log');
                expect(action, expectedAction);
              },
              performAction: (receivedFragment, action) {
                reached.add('action');
                expect(identical(receivedFragment, fragment), isTrue);
                expect(action, expectedAction);
              },
            ),
          );

          expect(result, isTrue);
          expect(reached, ['fragment', 'ctrl', 'log', 'action']);
        }
      },
    );

    test(
      'host action failures propagate without fallback or later callback',
      () {
        final fragment = Object();
        final failure = StateError('host action failed');
        final reached = <String>[];

        expect(
          () => dispatchCardTemplateEditorCtrlShortcut<Object, Object>(
            keyCode: 10,
            event: Object(),
            keyCodes: _keyCodes,
            callbacks: CardTemplateEditorCtrlShortcutCallbacks<Object, Object>(
              currentFragment: () => fragment,
              isCtrlPressed: (_) => true,
              superclassOnKeyUp: (_, __) {
                reached.add('fallback');
                return false;
              },
              log: (_) => reached.add('log'),
              performAction: (receivedFragment, _) {
                reached.add('action');
                expect(identical(receivedFragment, fragment), isTrue);
                throw failure;
              },
            ),
          ),
          throwsA(same(failure)),
        );

        expect(reached, ['log', 'action']);
      },
    );
  });
}

const _keyCodes = CardTemplateEditorCtrlKeyCodes(
  p: 10,
  one: 11,
  two: 12,
  three: 13,
  s: 14,
  i: 15,
  n: 16,
  r: 17,
  b: 18,
  d: 19,
  o: 20,
  m: 21,
);
