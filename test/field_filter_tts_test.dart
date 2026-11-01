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
 * Source-derived tests for FieldFilters.TextToSpeechFilter;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TextToSpeechOptions', () {
    test(
      'renders present options in source order and omits absent options',
      () {
        expect(
          TextToSpeechOptions(
            language: 'ja_JP',
            voices: ['Apple_Name', 'Microsoft_Name'],
            speed: 0.8,
          ).render(),
          ' lang=ja_JP voices=Apple_Name,Microsoft_Name speed=0.8',
        );
        expect(const TextToSpeechOptions().render(), '');
      },
    );

    test('emits empty-but-present language and voices', () {
      expect(const TextToSpeechOptions(language: '').render(), ' lang=');
      expect(const TextToSpeechOptions(voices: []).render(), ' voices=');
      expect(
        const TextToSpeechOptions(language: '', voices: []).render(),
        ' lang= voices=',
      );
      expect(const TextToSpeechOptions(language: '').isValid, isFalse);
      expect(const TextToSpeechOptions(language: 'en_GB').isValid, isTrue);
    });

    test('formats Kotlin Float values and notation boundaries', () {
      expect(TextToSpeechOptions(speed: 0.8).render(), ' speed=0.8');
      expect(TextToSpeechOptions(speed: 1e-3).render(), ' speed=0.001');
      expect(TextToSpeechOptions(speed: 1e-4).render(), ' speed=1.0E-4');
      expect(TextToSpeechOptions(speed: 1e7).render(), ' speed=1.0E7');
      expect(TextToSpeechOptions(speed: 1e6).render(), ' speed=1000000.0');
      expect(TextToSpeechOptions(speed: -0.0).render(), ' speed=-0.0');
      expect(TextToSpeechOptions(speed: double.nan).render(), ' speed=NaN');
      expect(
        TextToSpeechOptions(speed: double.infinity).render(),
        ' speed=Infinity',
      );
      expect(
        TextToSpeechOptions(speed: double.negativeInfinity).render(),
        ' speed=-Infinity',
      );
      expect(
        TextToSpeechOptions(speed: 1.401298464324817e-45).render(),
        ' speed=1.4E-45',
      );
    });

    test(
      'uses Float32 constructor values and Kotlin data-class equality/hash',
      () {
        final voices = ['one', 'two'];
        final options = TextToSpeechOptions(
          language: 'en_GB',
          voices: voices,
          speed: 0.1,
        );
        final equal = TextToSpeechOptions(
          language: 'en_GB',
          voices: ['one', 'two'],
          speed: 0.10000000149011612,
        );

        expect(options.speed, 0.10000000149011612);
        expect(options, equal);
        expect(options.hashCode, equal.hashCode);
        expect(options.hashCode, -465968841);
        expect(const TextToSpeechOptions().hashCode, 0);
        expect(
          TextToSpeechOptions(speed: double.nan),
          TextToSpeechOptions(speed: double.nan),
        );
        expect(
          TextToSpeechOptions(speed: 0.0),
          isNot(TextToSpeechOptions(speed: -0.0)),
        );
        expect(TextToSpeechOptions(speed: 0.0).hashCode, 0);
        expect(TextToSpeechOptions(speed: -0.0).hashCode, -2147483648);
        expect(TextToSpeechOptions(speed: double.nan).hashCode, 2143289344);

        final beforeMutation = TextToSpeechOptions(voices: voices);
        voices.add('three');
        expect(
          beforeMutation,
          TextToSpeechOptions(voices: ['one', 'two', 'three']),
        );
        expect(
          beforeMutation.hashCode,
          TextToSpeechOptions(voices: ['one', 'two', 'three']).hashCode,
        );
      },
    );
  });

  group('TextToSpeechFilter and FieldFilters.ALL', () {
    test('matches terminal validity and rendering behavior', () {
      final filter = TextToSpeechFilter(
        options: TextToSpeechOptions(language: 'en_GB'),
      );
      const context = FilterContext(isClozeNoteType: false);

      expect(filter.name, 'tts');
      expect(filter.render(), 'tts lang=en_GB');
      expect(filter.isValid, isTrue);
      expect(TextToSpeechFilter().isValid, isFalse);
      expect(filter.updateContext(context).isTerminal, isTrue);
      expect(filter.canApplyTo(context), isTrue);
      expect(filter.canApplyTo(filter.updateContext(context)), isFalse);
      expect(
        filter,
        TextToSpeechFilter(options: TextToSpeechOptions(language: 'en_GB')),
      );
      expect(
        filter.hashCode,
        TextToSpeechFilter(
          options: TextToSpeechOptions(language: 'en_GB'),
        ).hashCode,
      );

      final chain = FieldFilterChain.build(
        const FieldName('Front'),
        isClozeNoteType: false,
      );
      expect(chain.tryAdd(TextToSpeechFilter()), isNull);
      final invalid = chain.tryAdd(TextToSpeechFilter(), allowInvalid: true)!;
      expect(invalid.isValid, isFalse);
      expect(invalid.tryAdd(FieldFilters.text, allowInvalid: true), isNull);
    });

    test('contains the source builtin list in exact order', () {
      expect(FieldFilters.ALL.map((filter) => filter.name), [
        'text',
        'cloze',
        'cloze-only',
        'hint',
        'type',
        'type:nc',
        'nosuggest',
        'tts',
        'furigana',
        'kana',
        'kanji',
      ]);
      expect(FieldFilters.ALL[7], isA<TextToSpeechFilter>());
      expect(FieldFilters.ALL[7], same(FieldFilters.textToSpeech));
    });

    test('tts terminates a field-filter chain', () {
      final chain =
          FieldFilterChain.build(
            const FieldName('Front'),
            isClozeNoteType: false,
          ).tryAdd(
            TextToSpeechFilter(options: TextToSpeechOptions(language: 'ja_JP')),
          )!;

      expect(chain.context.isTerminal, isTrue);
      expect(chain.render(), '{{tts lang=ja_JP:Front}}');
      expect(chain.tryAdd(FieldFilters.text), isNull);
    });
  });
}
