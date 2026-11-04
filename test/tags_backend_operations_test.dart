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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived adapter cases for Tags backend forwarding; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Tags backend operations', () {
    test('all calls once, returns the result, and propagates failures', () {
      final result = Object();
      var calls = 0;
      final actual = tagsAll(
        allTags: () {
          calls++;
          return result;
        },
      );
      expect(calls, 1);
      expect(actual, same(result));

      final failure = StateError('allTags failed');
      calls = 0;
      expect(
        () => tagsAll<Object>(
          allTags: () {
            calls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });

    test('tree calls once, returns the result, and propagates failures', () {
      final result = Object();
      var calls = 0;
      final actual = tagsTree(
        tagTree: () {
          calls++;
          return result;
        },
      );
      expect(calls, 1);
      expect(actual, same(result));

      final failure = StateError('tagTree failed');
      calls = 0;
      expect(
        () => tagsTree<Object>(
          tagTree: () {
            calls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });

    test(
      'clearUnusedTags calls once, returns the result, and propagates failures',
      () {
        final result = Object();
        var calls = 0;
        final actual = tagsClearUnusedTags(
          clearUnusedTags: () {
            calls++;
            return result;
          },
        );
        expect(calls, 1);
        expect(actual, same(result));

        final failure = StateError('clearUnusedTags failed');
        calls = 0;
        expect(
          () => tagsClearUnusedTags<Object>(
            clearUnusedTags: () {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
      },
    );

    test(
      'bulkAdd preserves values and references, and propagates failures',
      () {
        final requestedNoteIds = <int>[0, -7, 41];
        const requestedTags = '  spaced  ';
        final result = Object();
        var calls = 0;
        final actual = tagsBulkAdd(
          noteIds: requestedNoteIds,
          tags: requestedTags,
          addNoteTags: ({required noteIds, required tags}) {
            calls++;
            expect(noteIds, same(requestedNoteIds));
            expect(noteIds, [0, -7, 41]);
            expect(tags, same(requestedTags));
            expect(tags, '  spaced  ');
            return result;
          },
        );
        expect(calls, 1);
        expect(actual, same(result));

        final failure = StateError('addNoteTags failed');
        calls = 0;
        expect(
          () => tagsBulkAdd<Object>(
            noteIds: requestedNoteIds,
            tags: requestedTags,
            addNoteTags: ({required noteIds, required tags}) {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
      },
    );

    test(
      'bulkRemove preserves values and references, and propagates failures',
      () {
        final requestedNoteIds = <int>[9, 2];
        const requestedTags = 'A::B  A';
        final result = Object();
        var calls = 0;
        final actual = tagsBulkRemove(
          noteIds: requestedNoteIds,
          tags: requestedTags,
          removeNoteTags: ({required noteIds, required tags}) {
            calls++;
            expect(noteIds, same(requestedNoteIds));
            expect(noteIds, [9, 2]);
            expect(tags, same(requestedTags));
            expect(tags, 'A::B  A');
            return result;
          },
        );
        expect(calls, 1);
        expect(actual, same(result));

        final failure = StateError('removeNoteTags failed');
        calls = 0;
        expect(
          () => tagsBulkRemove<Object>(
            noteIds: requestedNoteIds,
            tags: requestedTags,
            removeNoteTags: ({required noteIds, required tags}) {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
      },
    );

    test('rename maps prefixes and propagates the exact failure', () {
      final result = Object();
      var calls = 0;
      final actual = tagsRename(
        old: 'Old::',
        newValue: 'New::',
        renameTags: ({required currentPrefix, required newPrefix}) {
          calls++;
          expect(currentPrefix, 'Old::');
          expect(newPrefix, 'New::');
          return result;
        },
      );
      expect(calls, 1);
      expect(actual, same(result));

      final failure = StateError('renameTags failed');
      calls = 0;
      expect(
        () => tagsRename<Object>(
          old: '',
          newValue: 'New',
          renameTags: ({required currentPrefix, required newPrefix}) {
            calls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });

    test('remove maps the exact value to val and propagates failures', () {
      final result = Object();
      var calls = 0;
      final actual = tagsRemove(
        spaceSeparatedTags: '  one::two   three ',
        removeTags: ({required val}) {
          calls++;
          expect(val, '  one::two   three ');
          return result;
        },
      );
      expect(calls, 1);
      expect(actual, same(result));

      final failure = StateError('removeTags failed');
      calls = 0;
      expect(
        () => tagsRemove<Object>(
          spaceSeparatedTags: '',
          removeTags: ({required val}) {
            calls++;
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, 1);
    });

    test(
      'reparent preserves values and references and propagates failures',
      () {
        final requestedTags = _parentTags();
        final result = Object();
        var calls = 0;
        final actual = tagsReparent(
          tags: requestedTags,
          newParent: 'new parent::',
          reparentTags: ({required tags, required newParent}) {
            calls++;
            expect(tags, same(requestedTags));
            expect(tags.toList(), ['parent::child', 'other']);
            expect(newParent, 'new parent::');
            return result;
          },
        );
        expect(calls, 1);
        expect(actual, same(result));

        final failure = StateError('reparentTags failed');
        calls = 0;
        expect(
          () => tagsReparent<Object>(
            tags: requestedTags,
            newParent: '',
            reparentTags: ({required tags, required newParent}) {
              calls++;
              throw failure;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, 1);
      },
    );
  });
}

Iterable<String> _parentTags() sync* {
  yield 'parent::child';
  yield 'other';
}
