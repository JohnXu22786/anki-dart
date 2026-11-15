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
 * Source-derived cases for TypeAnswer.removeTags; there is no direct pinned
 * test for that method.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('removeTypeAnswerTags', () {
    test('removes one nonempty tag and preserves surrounding text', () {
      expect(
        removeTypeAnswerTags('before [[type:Back]] after'),
        'before  after',
      );
    });

    test('removes all nonoverlapping tags', () {
      expect(
        removeTypeAnswerTags('a[[type:Front]]b[[type:Back]]c'),
        'abc',
      );
    });

    test('does not match an empty payload', () {
      expect(removeTypeAnswerTags('before [[type:]] after'),
          'before [[type:]] after');
    });

    test('an empty opener can extend through a later closing delimiter', () {
      expect(
        removeTypeAnswerTags('[[type:]][[type:Back]]'),
        '',
      );
    });

    test('matches the literal prefix with source case sensitivity', () {
      expect(removeTypeAnswerTags('[[TYPE:Back]]'), '[[TYPE:Back]]');
      expect(removeTypeAnswerTags('[[type:Back]]'), '');
    });

    test('does not let the regex dot cross Java line terminators', () {
      for (final lineTerminator in ['\n', '\r', '\u0085', '\u2028', '\u2029']) {
        final text = 'before [[type:Back${lineTerminator}]] after';
        expect(removeTypeAnswerTags(text), text);
      }
    });

    test('lazy payload ends at the first closing delimiter', () {
      expect(
        removeTypeAnswerTags('before [[type:Back]] after]] end'),
        'before  after]] end',
      );
    });
  });
}
