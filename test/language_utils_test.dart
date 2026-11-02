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
 * Source-derived from LanguageUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('localeFromStringIgnoringScriptAndExtensions', () {
    test('maps one, two, three, and invalid field counts once', () {
      final inputs = ['en', 'en_US', 'en_US_POSIX', 'en_US_POSIX_extra'];
      final calls = <String>[];

      for (final input in inputs) {
        expect(
          localeFromStringIgnoringScriptAndExtensions(
            input,
            localeForLanguageTag: (tag) {
              calls.add(tag);
              return 'locale:$tag';
            },
          ),
          startsWith('locale:'),
        );
      }

      expect(calls, ['en', 'en-US', 'en-US-POSIX', '']);
    });

    test('truncates at the first hash while preserving source field text', () {
      final calls = <String>[];

      for (final input in ['en_US#Latn#u-ca-gregory', 'EN_us']) {
        localeFromStringIgnoringScriptAndExtensions(
          input,
          localeForLanguageTag: (tag) {
            calls.add(tag);
            return tag;
          },
        );
      }

      expect(calls, ['en-US', 'EN-us']);
    });

    test(
      'preserves empty and trailing split fields, including an empty prefix',
      () {
        final calls = <String>[];

        for (final input in ['', '#script', 'en_', '_US', 'en_US_']) {
          localeFromStringIgnoringScriptAndExtensions(
            input,
            localeForLanguageTag: (tag) {
              calls.add(tag);
              return tag;
            },
          );
        }

        expect(calls, ['', '', 'en-', '-US', 'en-US-']);
      },
    );
  });

  group('appLanguageIsRTL', () {
    test(
      'queries only the first UTF-16 code unit and recognizes the two RTL cases',
      () {
        final codeUnits = <int>[];
        var directionality = javaCharacterDirectionalityRightToLeft;

        expect(
          appLanguageIsRTL(
            'اEnglish',
            characterGetDirectionality: (codeUnit) {
              codeUnits.add(codeUnit);
              return directionality;
            },
          ),
          isTrue,
        );
        directionality = javaCharacterDirectionalityRightToLeftArabic;
        expect(
          appLanguageIsRTL(
            'اEnglish',
            characterGetDirectionality: (codeUnit) {
              codeUnits.add(codeUnit);
              return directionality;
            },
          ),
          isTrue,
        );
        directionality = javaCharacterDirectionalityLeftToRight;
        expect(
          appLanguageIsRTL(
            'اEnglish',
            characterGetDirectionality: (codeUnit) {
              codeUnits.add(codeUnit);
              return directionality;
            },
          ),
          isFalse,
        );

        expect(codeUnits, [0x0627, 0x0627, 0x0627]);
      },
    );

    test(
      'empty display name returns false without querying directionality',
      () {
        var called = false;

        expect(
          appLanguageIsRTL(
            '',
            characterGetDirectionality: (_) {
              called = true;
              return javaCharacterDirectionalityRightToLeft;
            },
          ),
          isFalse,
        );
        expect(called, isFalse);
      },
    );

    test(
      'passes the first UTF-16 unit even when the display name starts with a pair',
      () {
        final codeUnits = <int>[];

        appLanguageIsRTL(
          '😀Arabic',
          characterGetDirectionality: (codeUnit) {
            codeUnits.add(codeUnit);
            return javaCharacterDirectionalityOtherNeutral;
          },
        );

        expect(codeUnits, [0xd83d]);
      },
    );
  });
}
