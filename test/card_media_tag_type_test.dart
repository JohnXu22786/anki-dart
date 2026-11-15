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
 * Source-derived contract tests for `SoundOrVideoTag.getTagType()` in
 * AnkiDroid 2.25.3.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  const videoOnlyExtensions = {'mov', 'mkv'};
  const audioOrVideoExtensions = {'mp4', 'mpg', 'mpeg', 'webm'};

  group('cardMediaTagType', () {
    test('defaults unknown extensions to audio without resolving a file', () {
      final calls = <String>[];

      expect(
        cardMediaTagType(
          extension: 'wav',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return true;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return true;
          },
        ),
        CardMediaTagType.audio,
      );
      expect(calls, isEmpty);
    });

    test('classifies video-only extensions without filesystem callbacks', () {
      final calls = <String>[];

      expect(
        cardMediaTagType(
          extension: 'mkv',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return true;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return true;
          },
        ),
        CardMediaTagType.video,
      );
      expect(calls, isEmpty);
    });

    test('checks existence before thumbnail and maps all source outcomes', () {
      final calls = <String>[];
      expect(
        cardMediaTagType(
          extension: 'mp4',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return false;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return true;
          },
        ),
        CardMediaTagType.video,
      );
      expect(calls, ['exists']);

      calls.clear();
      expect(
        cardMediaTagType(
          extension: 'webm',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return true;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return true;
          },
        ),
        CardMediaTagType.video,
      );
      expect(calls, ['exists', 'thumbnail']);

      calls.clear();
      expect(
        cardMediaTagType(
          extension: 'mpg',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return true;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return false;
          },
        ),
        CardMediaTagType.audio,
      );
      expect(calls, ['exists', 'thumbnail']);

      calls.clear();
      expect(
        cardMediaTagType(
          extension: 'mpg',
          videoOnlyExtensions: videoOnlyExtensions,
          audioOrVideoExtensions: audioOrVideoExtensions,
          fileExists: () {
            calls.add('exists');
            return true;
          },
          hasVideoThumbnail: () {
            calls.add('thumbnail');
            return null;
          },
        ),
        CardMediaTagType.video,
      );
      expect(calls, ['exists', 'thumbnail']);
    });

    test(
      'propagates a host existence failure and stops before thumbnail check',
      () {
        final failure = StateError('file lookup failed');
        final calls = <String>[];

        expect(
          () => cardMediaTagType(
            extension: 'mp4',
            videoOnlyExtensions: videoOnlyExtensions,
            audioOrVideoExtensions: audioOrVideoExtensions,
            fileExists: () {
              calls.add('exists');
              throw failure;
            },
            hasVideoThumbnail: () {
              calls.add('thumbnail');
              return false;
            },
          ),
          throwsA(same(failure)),
        );
        expect(calls, ['exists']);
      },
    );
  });
}
