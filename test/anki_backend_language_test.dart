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
 * Source-derived from AnkiBackendLanguageTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnkiBackendLanguage.fromLanguageTag', () {
    test('accepts source identifiers and preserves valid raw forms', () {
      const identifiers = [
        'pl',
        'pl-PL',
        'zh-Hant',
        'zh-Hant-TW',
        'es-419',
        'ca-Latn-ES-valencia',
        'de-1901',
        'sl-rozaj-biske',
        'und',
        'qaa',
        'pt_BR',
        'zh-guoyu',
        'zh-hakka',
        'zh-xiang',
      ];
      var calls = 0;

      for (final identifier in identifiers) {
        final language = AnkiBackendLanguage.fromLanguageTag(
          identifier,
          localeToLanguageTag: (_) {
            calls++;
            return null;
          },
        );
        expect(language?.value, identifier, reason: identifier);
      }

      expect(calls, 0);
    });

    test('maps aliases and rejects invalid or Kotlin-blank input', () {
      const aliases = {'heb': 'he', 'ind': 'id', 'tgl': 'tl', 'hi': 'hi-IN'};
      for (final entry in aliases.entries) {
        expect(
          AnkiBackendLanguage.fromLanguageTag(
            entry.key,
            localeToLanguageTag: (_) =>
                fail('valid raw identifier used fallback'),
          )?.value,
          entry.value,
          reason: entry.key,
        );
      }

      for (final identifier in [
        '',
        ' ',
        '\t\n',
        'e',
        'abcd',
        '123',
        'en-',
        'en--US',
        'en-US-Latn',
        'en-1234a5678',
        'en-12',
        'en US',
        'pl-PL-!',
      ]) {
        expect(
          AnkiBackendLanguage.fromLanguageTag(
            identifier,
            localeToLanguageTag: (_) => null,
          ),
          isNull,
          reason: identifier,
        );
      }

      var blankCalls = 0;
      for (final whitespace in ['\u00a0', '\u2007', '\u202f']) {
        expect(
          AnkiBackendLanguage.fromLanguageTag(
            whitespace,
            localeToLanguageTag: (_) {
              blankCalls++;
              return null;
            },
          ),
          isNull,
          reason: 'U+${whitespace.codeUnitAt(0).toRadixString(16)}',
        );
      }
      expect(blankCalls, 0);
    });

    test('uses host locale conversion only after direct parsing fails', () {
      const converted = {
        'pl-PL-u-fw-mon': 'pl-PL',
        'pl-PL-u-mu-celsius': 'pl-PL',
        'pl-PL-x-private': 'pl-PL',
        'pl-PL-a-example': 'pl-PL',
        'en-US-x-lvariant-WIN': 'en-US',
        'ja-JP-x-lvariant-JP': 'ja-JP',
        'th-TH-x-lvariant-TH': 'th-TH',
        'en_US-u-ca-gregory': 'en-US',
      };

      for (final entry in converted.entries) {
        var calls = 0;
        String? argument;
        final result = AnkiBackendLanguage.fromLanguageTag(
          entry.key,
          localeToLanguageTag: (tag) {
            calls++;
            argument = tag;
            return entry.value;
          },
        );

        expect(result?.value, entry.value, reason: entry.key);
        expect(calls, 1, reason: entry.key);
        expect(argument, entry.key.replaceAll('_', '-'), reason: entry.key);
      }

      expect(
        AnkiBackendLanguage.fromLanguageTag(
          'en-US-u-ca-gregory',
          localeToLanguageTag: (_) => null,
        ),
        isNull,
      );
    });

    test('propagates unexpected host conversion failures', () {
      final error = StateError('host locale conversion failed');
      expect(
        () => AnkiBackendLanguage.fromLanguageTag(
          'en-US-u-ca-gregory',
          localeToLanguageTag: (_) => throw error,
        ),
        throwsA(same(error)),
      );
    });

    test('has value equality, hash, and string behavior', () {
      final first = AnkiBackendLanguage.fromLanguageTag(
        'en-US',
        localeToLanguageTag: (_) => fail('valid raw identifier used fallback'),
      )!;
      final second = AnkiBackendLanguage.fromLanguageTag(
        'en-US',
        localeToLanguageTag: (_) => fail('valid raw identifier used fallback'),
      )!;
      final other = AnkiBackendLanguage.fromLanguageTag(
        'en-us',
        localeToLanguageTag: (_) => fail('valid raw identifier used fallback'),
      )!;

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.toString(), 'AnkiBackendLanguage(value=en-US)');
      expect(first, isNot(other));
    });
  });
}
