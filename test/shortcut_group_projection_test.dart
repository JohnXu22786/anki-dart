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
 * Source-derived from ShortcutGroup.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ShortcutGroup', () {
    test('uses ordered structural shortcut equality, ID, and hash', () {
      final shortcuts = [
        const Shortcut(shortcut: 'Ctrl+A', label: 'first'),
        const Shortcut(shortcut: 'Alt+B', label: 'second'),
      ];
      final group = ShortcutGroup(shortcuts: shortcuts, id: 17);

      expect(
        group,
        ShortcutGroup(
          shortcuts: [
            const Shortcut(shortcut: 'Ctrl+A', label: 'first'),
            const Shortcut(shortcut: 'Alt+B', label: 'second'),
          ],
          id: 17,
        ),
      );
      expect(
        group.hashCode,
        ShortcutGroup(
          shortcuts: [
            const Shortcut(shortcut: 'Ctrl+A', label: 'first'),
            const Shortcut(shortcut: 'Alt+B', label: 'second'),
          ],
          id: 17,
        ).hashCode,
      );
      expect(
        group,
        isNot(ShortcutGroup(shortcuts: shortcuts.reversed.toList(), id: 17)),
      );
      expect(group, isNot(ShortcutGroup(shortcuts: shortcuts, id: 18)));
    });

    test(
      'converts in list order before resolving the exact group title ID',
      () {
        final calls = <String>[];
        final group = ShortcutGroup(
          shortcuts: [
            const Shortcut(shortcut: 'Ctrl+A', label: 'first'),
            const Shortcut(shortcut: 'Alt+B', label: 'second'),
          ],
          id: 712,
        );

        final result = group.toShortcutGroup(
          _values(calls),
          resolveTitle: (resourceId) {
            calls.add('title:$resourceId');
            return 'Resolved title';
          },
        );

        expect(calls, ['key:A', 'key:B', 'title:712']);
        expect(
          result,
          ShortcutGroupProjection(
            label: 'Resolved title',
            shortcuts: const [
              ShortcutInfoProjection(
                label: 'first',
                keyCode: 42,
                modifierFlags: 4,
              ),
              ShortcutInfoProjection(
                label: 'second',
                keyCode: 42,
                modifierFlags: 8,
              ),
            ],
          ),
        );
      },
    );

    test('propagates conversion and title failures in source order', () {
      final conversionCalls = <String>[];
      final conversionError = StateError('conversion failed');
      final group = ShortcutGroup(
        shortcuts: [
          const Shortcut(shortcut: 'Ctrl+A', label: 'first'),
          const Shortcut(shortcut: 'Ctrl+B', label: 'second'),
          const Shortcut(shortcut: 'Ctrl+C', label: 'third'),
        ],
        id: 8,
      );

      expect(
        () => group.toShortcutGroup(
          _values(conversionCalls, failingKey: 'B', error: conversionError),
          resolveTitle: (resourceId) {
            conversionCalls.add('title:$resourceId');
            return 'unused';
          },
        ),
        throwsA(same(conversionError)),
      );
      expect(conversionCalls, ['key:A', 'key:B']);

      final titleCalls = <String>[];
      final titleError = StateError('title failed');
      expect(
        () => group.toShortcutGroup(
          _values(titleCalls),
          resolveTitle: (resourceId) {
            titleCalls.add('title:$resourceId');
            throw titleError;
          },
        ),
        throwsA(same(titleError)),
      );
      expect(titleCalls, ['key:A', 'key:B', 'key:C', 'title:8']);
    });
  });
}

ShortcutPlatformValues _values(
  List<String> calls, {
  String? failingKey,
  Object? error,
}) => ShortcutPlatformValues(
  keyCodeSlash: 1001,
  keyCodeEscape: 1002,
  keyCode0: 2000,
  metaCtrlOn: 4,
  metaAltOn: 8,
  metaShiftOn: 16,
  keyCodeFromString: (key) {
    calls.add('key:$key');
    if (key == failingKey) throw error!;
    return 42;
  },
);
