/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes', () {
    test('returns the source OR result for all boolean combinations', () {
      for (final combination in [
        (isCloze: false, isImageOcclusion: false, result: false),
        (isCloze: false, isImageOcclusion: true, result: true),
        (isCloze: true, isImageOcclusion: false, result: true),
        (isCloze: true, isImageOcclusion: true, result: true),
      ]) {
        expect(
          cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
            isCloze: () => combination.isCloze,
            isImageOcclusion: () => combination.isImageOcclusion,
          ),
          combination.result,
          reason: '$combination',
        );
      }
    });

    test('does not read image occlusion when cloze is true', () {
      final events = <String>[];

      final result = cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
        isCloze: () {
          events.add('cloze');
          return true;
        },
        isImageOcclusion: () {
          events.add('imageOcclusion');
          return false;
        },
      );

      expect(result, isTrue);
      expect(events, ['cloze']);
    });

    test(
      'reads lazily in source order using closures over the same note type',
      () {
        final sourceNoteType = Object();
        final accessedTypes = <Object>[];
        final events = <String>[];

        final result = cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
          isCloze: () {
            events.add('cloze');
            accessedTypes.add(sourceNoteType);
            return false;
          },
          isImageOcclusion: () {
            events.add('imageOcclusion');
            accessedTypes.add(sourceNoteType);
            return true;
          },
        );

        expect(result, isTrue);
        expect(events, ['cloze', 'imageOcclusion']);
        expect(accessedTypes, [same(sourceNoteType), same(sourceNoteType)]);
      },
    );

    test('propagates callback failures unchanged and stops later reads', () {
      final clozeFailure = StateError('cloze read failed');
      final clozeEvents = <String>[];
      expect(
        () => cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
          isCloze: () {
            clozeEvents.add('cloze');
            throw clozeFailure;
          },
          isImageOcclusion: () {
            clozeEvents.add('imageOcclusion');
            return true;
          },
        ),
        throwsA(same(clozeFailure)),
      );
      expect(clozeEvents, ['cloze']);

      final imageFailure = StateError('image occlusion read failed');
      final imageEvents = <String>[];
      expect(
        () => cardTemplateEditorNoteTypeCreatesDynamicNumberOfNotes(
          isCloze: () {
            imageEvents.add('cloze');
            return false;
          },
          isImageOcclusion: () {
            imageEvents.add('imageOcclusion');
            throw imageFailure;
          },
        ),
        throwsA(same(imageFailure)),
      );
      expect(imageEvents, ['cloze', 'imageOcclusion']);
    });
  });
}
