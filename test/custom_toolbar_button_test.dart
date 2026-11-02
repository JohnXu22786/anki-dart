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
 * Behavioral reference: CustomToolbarButton.kt and Toolbar.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CustomToolbarButton parsing', () {
    test('parses fields verbatim including empty trailing fields', () {
      expect(fieldSeparator, '\u001f');
      final trailingEmpty = CustomToolbarButton.fromString(
        '2\u001ftext\u001fprefix\u001f',
      )!;
      expect(
        [
          trailingEmpty.index,
          trailingEmpty.buttonText,
          trailingEmpty.prefix,
          trailingEmpty.suffix,
        ],
        [2, 'text', 'prefix', ''],
      );
      final emptyText = CustomToolbarButton.fromString(
        '2\u001f\u001fprefix\u001fsuffix',
      )!;
      expect(
        [
          emptyText.index,
          emptyText.buttonText,
          emptyText.prefix,
          emptyText.suffix,
        ],
        [2, '', 'prefix', 'suffix'],
      );
    });

    test('rejects null, empty, and any non-four-field record', () {
      expect(CustomToolbarButton.fromString(null), isNull);
      expect(CustomToolbarButton.fromString(''), isNull);
      expect(CustomToolbarButton.fromString('2\u001ftext\u001fprefix'), isNull);
      expect(
        CustomToolbarButton.fromString(
          '2\u001ftext\u001fprefix\u001fsuffix\u001fextra',
        ),
        isNull,
      );
    });

    test('construction and mutation keep indices within signed Int32', () {
      expect(
        () => CustomToolbarButton(2147483648, 't', 'p', 's'),
        throwsRangeError,
      );
      final button = CustomToolbarButton(0, 't', 'p', 's');
      expect(() => button.index = -2147483649, throwsRangeError);
      button.index = -2147483648;
      expect(button.index, -2147483648);
    });

    test(
      'accepts signed Int32 boundaries and warns once on invalid indices',
      () {
        expect(
          CustomToolbarButton.fromString(
            '-2147483648\u001ft\u001fp\u001fs',
          )!.index,
          -2147483648,
        );
        expect(
          CustomToolbarButton.fromString(
            '+2147483647\u001ft\u001fp\u001fs',
          )!.index,
          2147483647,
        );
        final warnings = <Object>[];

        expect(
          CustomToolbarButton.fromString(
            '2147483648\u001ft\u001fp\u001fs',
            warn: warnings.add,
          ),
          isNull,
        );
        expect(
          CustomToolbarButton.fromString(
            'not-an-int\u001ft\u001fp\u001fs',
            warn: warnings.add,
          ),
          isNull,
        );
        expect(warnings, hasLength(2));
        expect(warnings, everyElement(isA<FormatException>()));
        expect(
          CustomToolbarButton.fromString(
            '-2147483649\u001ft\u001fp\u001fs',
            warn: warnings.add,
          ),
          isNull,
        );
        expect(warnings, hasLength(3));
      },
    );
  });

  group('CustomToolbarButton set conversion', () {
    test(
      'skips bad entries and stable-sorts equal indices in iteration order',
      () {
        final buttons = CustomToolbarButton.fromStringSet([
          '8\u001ffirst\u001f(\u001f)',
          null,
          'bad\u001finvalid\u001f(\u001f)',
          '3\u001fsecond\u001f[\u001f]',
          '8\u001fthird\u001f{\u001f}',
        ]);

        expect(
          buttons.map(
            (button) => [
              button.index,
              button.buttonText,
              button.prefix,
              button.suffix,
            ],
          ),
          [
            [0, 'second', '[', ']'],
            [1, 'first', '(', ')'],
            [2, 'third', '{', '}'],
          ],
        );
      },
    );

    test(
      'removes all separators in fields and collapses serialized duplicates',
      () {
        final serialized = CustomToolbarButton.toStringSet([
          CustomToolbarButton(1, 'a\u001fb', 'p\u001f', '\u001fs'),
          CustomToolbarButton(1, 'ab', 'p', 's'),
        ]);

        expect(serialized, {'1\u001fab\u001fp\u001fs'});
      },
    );
  });

  test('toFormatter wraps and applies the source selection rules', () {
    final formatter = CustomToolbarButton(
      0,
      'button',
      r'\(',
      r'\)',
    ).toFormatter();
    final empty = formatter.format('');
    final selected = formatter.format('🙂');

    expect(empty, StringFormat(r'\(\)', 2, 2));
    expect(selected.result, r'\(🙂\)');
    expect(selected.selectionStart, 0);
    expect(selected.selectionEnd, selected.result.length);
    expect(selected.selectionEnd, 6);
  });
}
