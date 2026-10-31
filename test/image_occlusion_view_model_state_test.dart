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
 * SPDX-FileCopyrightText: 2025 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ImageOcclusionViewModel.kt and
 * ImageOcclusionViewModelTest.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Image Occlusion arguments', () {
    test('add arguments preserve values and source mode keys', () {
      const args = ImageOcclusionAddArgs(
        imagePath: '  content://provider/image%2Fsource.png  ',
        noteTypeId: 9223372036854775807,
        originalDeckId: -9223372036854775808,
      );

      expect(
        args,
        const ImageOcclusionAddArgs(
          imagePath: '  content://provider/image%2Fsource.png  ',
          noteTypeId: 9223372036854775807,
          originalDeckId: -9223372036854775808,
        ),
      );
      expect(args.imagePath, '  content://provider/image%2Fsource.png  ');
      expect(args.noteTypeId, 9223372036854775807);
      expect(args.originalDeckId, -9223372036854775808);
      expect(args.toImageOcclusionMode(), {
        'kind': 'add',
        'imagePath': '  content://provider/image%2Fsource.png  ',
        'notetypeId': 9223372036854775807,
      });
    });

    test('edit arguments preserve note ID and source mode keys', () {
      const args = ImageOcclusionEditArgs(noteId: 9223372036854775807);

      expect(args, const ImageOcclusionEditArgs(noteId: 9223372036854775807));
      expect(args.noteId, 9223372036854775807);
      expect(args.toImageOcclusionMode(), {
        'kind': 'edit',
        'noteId': 9223372036854775807,
      });
    });
  });

  group('Image Occlusion view-model state', () {
    test(
      'add selection starts at original deck and requests restore if changed',
      () {
        final state = ImageOcclusionViewModelState(
          const ImageOcclusionAddArgs(
            imagePath: '/image.png',
            noteTypeId: 4,
            originalDeckId: 23,
          ),
        );

        expect(state.selectedDeckId, 23);
        expect(state.onSaveOperationCompleted(), isNull);

        state.handleDeckSelection(47);

        expect(state.selectedDeckId, 47);
        expect(state.onSaveOperationCompleted(), 23);
        // The source requests a backend reset without changing its selected-ID flow.
        expect(state.selectedDeckId, 47);
      },
    );

    test(
      'edit mode exposes no selection and ignores selection and save calls',
      () {
        final state = ImageOcclusionViewModelState(
          const ImageOcclusionEditArgs(noteId: 8),
        );

        expect(state.selectedDeckId, isNull);
        state.handleDeckSelection(47);
        expect(state.selectedDeckId, isNull);
        expect(state.onSaveOperationCompleted(), isNull);
      },
    );
  });
}
