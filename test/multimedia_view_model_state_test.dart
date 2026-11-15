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
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from MultimediaViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Multimedia view-model state', () {
    test('starts empty with a zero selected file size', () {
      final state = MultimediaViewModelState<Object, Object>();

      expect(state.currentMultimediaUri, isNull);
      expect(state.currentMultimediaPath, isNull);
      expect(state.selectedMediaFileSize, 0);
    });

    test('save and restore retain the exact opaque values and nulls', () {
      final state = MultimediaViewModelState<Object, Object>();
      final previousUri = Object();
      final previousPath = Object();
      final currentUri = Object();
      final currentPath = Object();

      state.saveMultimediaForRevert(previousPath, previousUri);
      state.updateCurrentMultimediaUri(currentUri);
      state.updateCurrentMultimediaPath(currentPath);
      state.restoreMultimedia();

      expect(state.currentMultimediaUri, same(previousUri));
      expect(state.currentMultimediaPath, same(previousPath));

      state.saveMultimediaForRevert(null, null);
      state.restoreMultimedia();

      expect(state.currentMultimediaUri, isNull);
      expect(state.currentMultimediaPath, isNull);
    });

    test('updates preserve opaque values and signed 64-bit lengths', () {
      final state = MultimediaViewModelState<Object, Object>();
      final uri = Object();
      final path = Object();

      state.updateMediaFileLength(-9223372036854775808);
      state.updateCurrentMultimediaUri(uri);
      state.updateCurrentMultimediaPath(path);

      expect(state.selectedMediaFileSize, -9223372036854775808);
      expect(state.currentMultimediaUri, same(uri));
      expect(state.currentMultimediaPath, same(path));

      state.updateMediaFileLength(9223372036854775807);
      state.updateCurrentMultimediaUri(null);
      state.updateCurrentMultimediaPath(null);

      expect(state.selectedMediaFileSize, 9223372036854775807);
      expect(state.currentMultimediaUri, isNull);
      expect(state.currentMultimediaPath, isNull);
    });
  });
}
