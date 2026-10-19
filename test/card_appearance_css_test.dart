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
 * Source mapping: CardAppearance.appendCssStyle/getCssClasses/getCardClass,
 * CardTextScaleTest, and AndroidCardRenderContext in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. Class projection cases are source-derived because no
 * direct pinned tests assert these methods' output.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('appendCardAppearanceCss', () {
    test('appends font, card, and image rules in source order', () {
      final fontScale = Float32List.fromList([0.85])[0];

      expect(
        appendCardAppearanceCss(
          '',
          fontScale: fontScale,
          cardZoom: 80,
          imageZoom: 120,
        ),
        'html { zoom: 0.85 }\n'
        'body { zoom: 0.8 }\n'
        'img { zoom: 1.2 }\n',
      );
    });

    test('omits all rules for source defaults and preserves existing CSS', () {
      const existingStyle = '.card { color: red }\n';

      expect(
        appendCardAppearanceCss(
          existingStyle,
          fontScale: 1,
          cardZoom: 100,
          imageZoom: 100,
        ),
        existingStyle,
      );
    });

    test('emits each nondefault scale independently', () {
      expect(
        appendCardAppearanceCss('',
            fontScale: 1.3, cardZoom: 100, imageZoom: 100),
        'html { zoom: 1.3 }\n',
      );
      expect(
        appendCardAppearanceCss('', fontScale: 1, cardZoom: 80, imageZoom: 100),
        'body { zoom: 0.8 }\n',
      );
      expect(
        appendCardAppearanceCss('',
            fontScale: 1, cardZoom: 100, imageZoom: 120),
        'img { zoom: 1.2 }\n',
      );
    });

    test('appends after existing CSS without rewriting its prefix', () {
      const existingStyle = 'a { color: blue }\n';

      expect(
        appendCardAppearanceCss(
          existingStyle,
          fontScale: 1,
          cardZoom: 80,
          imageZoom: 100,
        ),
        '${existingStyle}body { zoom: 0.8 }\n',
      );
    });

    test('renders large integer zoom ratios in Java Double exponent form', () {
      expect(
        appendCardAppearanceCss(
          '',
          fontScale: 1,
          cardZoom: 1000000000,
          imageZoom: -2147483648,
        ),
        'body { zoom: 1.0E7 }\n'
        'img { zoom: -2.147483648E7 }\n',
      );
    });
  });

  group('cardAppearanceCssClasses', () {
    test('preserves theme suffixes and centering order for each projection',
        () {
      final cases = <(CardAppearanceThemeProjection, String)>[
        (CardAppearanceThemeProjection.dayOther, ''),
        (
          CardAppearanceThemeProjection.dayPlain,
          ' ankidroid_plain_mode',
        ),
        (
          CardAppearanceThemeProjection.nightOther,
          ' night_mode nightMode',
        ),
        (
          CardAppearanceThemeProjection.nightDark,
          ' night_mode nightMode ankidroid_dark_mode',
        ),
      ];

      for (final (theme, expectedSuffix) in cases) {
        expect(
          cardAppearanceCssClasses(
            theme: theme,
            centerVertically: false,
          ),
          expectedSuffix,
        );
        expect(
          cardAppearanceCssClasses(
            theme: theme,
            centerVertically: true,
          ),
          ' vertically_centered$expectedSuffix',
        );
      }
    });
  });

  group('cardAppearanceClassName', () {
    test('interpolates the one-based ordinal before the class suffix', () {
      expect(
        cardAppearanceClassName(
          3,
          theme: CardAppearanceThemeProjection.nightDark,
          centerVertically: true,
        ),
        'card card3 vertically_centered night_mode nightMode ankidroid_dark_mode',
      );
    });

    test('concatenates ordinals directly and does not append MathJax state',
        () {
      expect(
        cardAppearanceClassName(
          0,
          theme: CardAppearanceThemeProjection.dayOther,
          centerVertically: false,
        ),
        'card card0',
      );
    });
  });
}
