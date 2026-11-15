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
 * Behavioral reference: Tags.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart' as anki;
import 'package:test/test.dart';

void main() {
  group('Tags.split', () {
    test('splits source examples and filters repeated whitespace', () {
      expect(anki.Tags.split('Todo todo Needs Revision'), [
        'Todo',
        'todo',
        'Needs',
        'Revision',
      ]);
      expect(anki.Tags.split('  alpha\t\nbeta  '), ['alpha', 'beta']);
      expect(anki.Tags.split(''), isEmpty);
    });

    test('replaces fullwidth space with ASCII space', () {
      expect(anki.Tags.split('alpha\u3000beta'), ['alpha', 'beta']);
    });

    test('matches Java Pattern ASCII whitespace without Unicode expansion', () {
      expect(anki.Tags.split('a\tb\nc\u000bd\u000ce\rd f'), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'd',
        'f',
      ]);
      expect(anki.Tags.split('a\u00a0b\u2003c\u0085d'), [
        'a\u00a0b\u2003c\u0085d',
      ]);
    });
  });

  group('Tags.join', () {
    test(
      'returns empty for empty input and surrounds joined tags with spaces',
      () {
        expect(anki.Tags.join([]), '');
        expect(anki.Tags.join(['alpha', 'beta']), ' alpha beta ');
      },
    );

    test('preserves empty elements and their additional spaces', () {
      expect(anki.Tags.join(['', 'alpha', '']), '  alpha  ');
      expect(anki.Tags.join(['']), '  ');
    });
  });

  group('Tags.canonify', () {
    test(
      'returns a deduplicated copy without normalizing or promising order',
      () {
        final source = ['Tag', 'tag', ' Tag ', 'Tag'];
        final result = anki.Tags.canonify(source);

        expect(result, {'Tag', 'tag', ' Tag '});
        expect(result, isA<Set<String>>());
        expect(identical(result, source), isFalse);
        source.add('later');
        expect(result, isNot(contains('later')));
      },
    );
  });

  group('Tags.inList', () {
    test('matches case-insensitively using lowercase semantics', () {
      expect(anki.Tags.inList('once More', ['Todo', 'Once more']), isTrue);
      expect(anki.Tags.inList('Done', ['Todo']), isFalse);
      expect(anki.Tags.inList('', <String>[]), isFalse);
      expect(anki.Tags.inList('\u0130', ['i\u0307']), isTrue);
      expect(anki.Tags.inList('ος', ['ΟΣ']), isTrue);
      expect(anki.Tags.inList('οσα', ['ΟΣΑ']), isTrue);
      expect(anki.Tags.inList('σο', ['ΣΟ']), isTrue);
      expect(anki.Tags.inList("ο'ς", ["Ο'Σ"]), isTrue);
      expect(anki.Tags.inList("οσ'a", ["ΟΣ'A"]), isTrue);
      expect(anki.Tags.inList("ος'", ["ΟΣ'"]), isTrue);
    });

    test(
      'consumes all tags after an earlier match and propagates later failure',
      () {
        final visited = <String>[];
        Iterable<String> values() sync* {
          visited.add('first');
          yield 'MATCH';
          visited.add('second');
          yield 'later';
        }

        expect(anki.Tags.inList('match', values()), isTrue);
        expect(visited, ['first', 'second']);

        Iterable<String> failingValues() sync* {
          yield 'MATCH';
          throw StateError('later tag failed');
        }

        expect(
          () => anki.Tags.inList('match', failingValues()),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'later tag failed',
            ),
          ),
        );
      },
    );
  });
}
