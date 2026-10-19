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
 * Source mapping: CardTemplate.kt and CardTemplateTest.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md. Malformed-template cases are source-derived.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  const template =
      '<head>::style::</head>::script::<script>::class::<body>::content::<content>';

  group('CardTemplate', () {
    test('renders the five cached sections in source order', () {
      final rendered = CardTemplate(template).render(
        content: 'foo',
        style: 'bar',
        script: 'script',
        cardClass: 'baz',
      );

      expect(
          rendered,
          const RenderedCard(
            '<head>bar</head>script<script>baz<body>foo<content>',
          ));
      expect(
          rendered.html, '<head>bar</head>script<script>baz<body>foo<content>');
    });

    test('renders long replacement content without truncation', () {
      final content = 'a' * 1000;
      final rendered = CardTemplate(template).render(
        content: content,
        style: 'style',
        script: 'script',
        cardClass: 'class',
      );

      expect(
        rendered.html,
        '<head>style</head>script<script>class<body>$content<content>',
      );
    });

    test('consumes only the first marker occurrence of each section', () {
      const repeatedMarkers =
          'P::style::s::style::x::script::j::script::y::class::c::class::z::content::h::content::t';

      final rendered = CardTemplate(repeatedMarkers).render(
        content: 'C',
        style: 'S',
        script: 'J',
        cardClass: 'K',
      );

      expect(
        rendered.html,
        'PSs::style::xJj::script::yKc::class::zCh::content::t',
      );
    });

    test('missing style marker keeps the negative-take argument failure', () {
      expect(
        () => CardTemplate('template without a style marker'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('missing or reordered later markers use the source state failure', () {
      const sourceMessage =
          'The card template had replacement string order, or content changed';

      for (final malformed in [
        'prefix::style::no later markers',
        '::style::::class::::script::::content::',
      ]) {
        expect(
          () => CardTemplate(malformed),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              sourceMessage,
            ),
          ),
        );
      }
    });
  });
}
