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
 * Source-derived from Shortcut.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Shortcut', () {
    test('uses shortcut and label for Kotlin data-class equality and hash', () {
      const shortcut = Shortcut(shortcut: 'Ctrl+A', label: 'label');
      const equalShortcut = Shortcut(shortcut: 'Ctrl+A', label: 'label');

      expect(shortcut, equalShortcut);
      expect(shortcut.hashCode, equalShortcut.hashCode);
      expect(shortcut.hashCode, -1429511725);
      expect(
        shortcut,
        isNot(const Shortcut(shortcut: 'Alt+A', label: 'label')),
      );
      expect(
        shortcut,
        isNot(const Shortcut(shortcut: 'Ctrl+A', label: 'other')),
      );
    });

    test(
      'adds recognized modifiers arithmetically and ignores unknown ones',
      () {
        final projection = const Shortcut(
          shortcut: 'Ctrl+Ctrl+Unknown+Shift+Q',
          label: 'Question',
        ).toShortcutInfo(_values([]));

        expect(
          projection,
          const ShortcutInfoProjection(
            label: 'Question',
            keyCode: 42,
            modifierFlags: 18,
          ),
        );
      },
    );

    test(
      'maps slash, escape, and numeric shortcuts using source comparisons',
      () {
        final lookedUpKeys = <String>[];
        final values = _values(lookedUpKeys);
        expect(
          const Shortcut(shortcut: '/', label: 'slash').toShortcutInfo(values),
          const ShortcutInfoProjection(
            label: 'slash',
            keyCode: 1001,
            modifierFlags: 0,
          ),
        );
        expect(
          const Shortcut(
            shortcut: 'Esc',
            label: 'escape',
          ).toShortcutInfo(values),
          const ShortcutInfoProjection(
            label: 'escape',
            keyCode: 1002,
            modifierFlags: 0,
          ),
        );
        expect(
          const Shortcut(
            shortcut: '01',
            label: 'zero-one',
          ).toShortcutInfo(values),
          const ShortcutInfoProjection(
            label: 'zero-one',
            keyCode: 2001,
            modifierFlags: 0,
          ),
        );
        expect(
          const Shortcut(
            shortcut: '1٢',
            label: 'unicode-digit',
          ).toShortcutInfo(values),
          const ShortcutInfoProjection(
            label: 'unicode-digit',
            keyCode: 2012,
            modifierFlags: 0,
          ),
        );
        expect(
          () => const Shortcut(
            shortcut: '1x',
            label: 'invalid',
          ).toShortcutInfo(values),
          throwsFormatException,
        );
        expect(
          () => const Shortcut(
            shortcut: '2147483648',
            label: 'overflow',
          ).toShortcutInfo(values),
          throwsFormatException,
        );
        expect(lookedUpKeys, isEmpty);
      },
    );

    test('delegates all other keys once with their exact source text', () {
      final lookedUpKeys = <String>[];
      final values = _values(lookedUpKeys);
      final projection = const Shortcut(
        shortcut: 'Alt+  F13 ',
        label: 'Host label',
      ).toShortcutInfo(values);

      expect(lookedUpKeys, ['  F13 ']);
      expect(
        projection,
        const ShortcutInfoProjection(
          label: 'Host label',
          keyCode: 42,
          modifierFlags: 8,
        ),
      );
    });
  });
}

ShortcutPlatformValues _values(List<String> lookedUpKeys) =>
    ShortcutPlatformValues(
      keyCodeSlash: 1001,
      keyCodeEscape: 1002,
      keyCode0: 2000,
      metaCtrlOn: 4,
      metaAltOn: 8,
      metaShiftOn: 10,
      keyCodeFromString: (key) {
        lookedUpKeys.add(key);
        return 42;
      },
    );
