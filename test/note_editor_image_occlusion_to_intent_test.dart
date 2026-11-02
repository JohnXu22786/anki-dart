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
 * Source-derived from NoteEditorDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('noteEditorImageOcclusionToIntent', () {
    test(
      'always writes null image URI after the caller and returns intent',
      () {
        final context = Object();
        final intent = Object();
        final events = <Object?>[];

        final result = noteEditorImageOcclusionToIntent(
          context: context,
          imageUri: null,
          callbacks:
              NoteEditorImageOcclusionIntentCallbacks<Object, Object, Object>(
                createIntent: (actualContext) {
                  events.add(('create', actualContext));
                  return intent;
                },
                putIntExtra: (target, key, value) {
                  events.add(('int', target, key, value));
                },
                putParcelableExtra: (target, key, value) {
                  events.add(('parcelable', target, key, value));
                },
              ),
        );

        expect(result, same(intent));
        expect(events, [
          ('create', context),
          ('int', intent, 'CALLER', 12),
          ('parcelable', intent, 'image_uri', null),
        ]);
      },
    );

    test('passes a non-null image URI unchanged after the caller', () {
      final intent = Object();
      final uri = Object();
      final events = <Object?>[];

      final result = noteEditorImageOcclusionToIntent(
        context: Object(),
        imageUri: uri,
        callbacks:
            NoteEditorImageOcclusionIntentCallbacks<Object, Object, Object>(
              createIntent: (_) => intent,
              putIntExtra: (target, key, value) {
                events.add(('int', target, key, value));
              },
              putParcelableExtra: (target, key, value) {
                events.add(('parcelable', target, key, value));
              },
            ),
      );

      expect(result, same(intent));
      expect(events.length, 2);
      expect(events[0], ('int', intent, 'CALLER', 12));
      final uriEvent = events[1] as (String, Object, String, Object?);
      expect(uriEvent.$1, 'parcelable');
      expect(uriEvent.$2, same(intent));
      expect(uriEvent.$3, 'image_uri');
      expect(uriEvent.$4, same(uri));
    });

    test('propagates failures and stops later operations', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'create', reached: ['create']),
        (stage: 'caller', reached: ['create', 'caller']),
        (stage: 'uri', reached: ['create', 'caller', 'uri']),
      ];

      for (final testCase in cases) {
        final failure = StateError('${testCase.stage} failed');
        final reached = <String>[];
        void invoke(String stage) {
          reached.add(stage);
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => noteEditorImageOcclusionToIntent(
            context: Object(),
            imageUri: Object(),
            callbacks:
                NoteEditorImageOcclusionIntentCallbacks<Object, Object, Object>(
                  createIntent: (_) {
                    invoke('create');
                    return Object();
                  },
                  putIntExtra: (target, key, value) => invoke('caller'),
                  putParcelableExtra: (target, key, value) => invoke('uri'),
                ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(reached, testCase.reached, reason: testCase.stage);
      }
    });
  });
}
