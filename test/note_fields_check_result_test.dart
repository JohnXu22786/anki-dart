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
 * Source-derived cases for NoteFieldsCheckResult.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('projectNoteFieldsCheckResult', () {
    test('maps every semantic status and preserves supplied messages', () {
      const messages = NoteFieldsCheckMessages(
        imageOcclusionEmpty: 'occlusion message',
        firstFieldEmpty: 'first field message',
        missingCloze: 'missing cloze message',
        noteTypeNotCloze: 'note type message',
        fieldNotCloze: 'field message',
      );
      const failureMessages = <NoteFieldsCheckStatus, String>{
        NoteFieldsCheckStatus.missingCloze: 'missing cloze message',
        NoteFieldsCheckStatus.noteTypeNotCloze: 'note type message',
        NoteFieldsCheckStatus.fieldNotCloze: 'field message',
      };

      for (final status in [
        NoteFieldsCheckStatus.normal,
        NoteFieldsCheckStatus.duplicate,
      ]) {
        expect(
          projectNoteFieldsCheckResult(
            status: status,
            isImageOcclusion: false,
            messages: messages,
          ),
          isA<NoteFieldsCheckSuccess>(),
          reason: '$status should succeed',
        );
      }

      final ordinaryEmpty = projectNoteFieldsCheckResult(
        status: NoteFieldsCheckStatus.empty,
        isImageOcclusion: false,
        messages: messages,
      );
      expect(ordinaryEmpty, isA<NoteFieldsCheckFailure>());
      expect(
        (ordinaryEmpty as NoteFieldsCheckFailure).localizedMessage,
        'first field message',
      );

      final imageOcclusionEmpty = projectNoteFieldsCheckResult(
        status: NoteFieldsCheckStatus.empty,
        isImageOcclusion: true,
        messages: messages,
      );
      expect(imageOcclusionEmpty, isA<NoteFieldsCheckFailure>());
      expect(
        (imageOcclusionEmpty as NoteFieldsCheckFailure).localizedMessage,
        'occlusion message',
      );

      for (final entry in failureMessages.entries) {
        final result = projectNoteFieldsCheckResult(
          status: entry.key,
          isImageOcclusion: false,
          messages: messages,
        );
        expect(result, isA<NoteFieldsCheckFailure>(), reason: '${entry.key}');
        expect(
          (result as NoteFieldsCheckFailure).localizedMessage,
          entry.value,
          reason: '${entry.key} should keep its host-localized message',
        );
      }

      final unrecognized = projectNoteFieldsCheckResult(
        status: NoteFieldsCheckStatus.unrecognized,
        isImageOcclusion: true,
        messages: messages,
      );
      expect(unrecognized, isA<NoteFieldsCheckFailure>());
      expect((unrecognized as NoteFieldsCheckFailure).localizedMessage, isNull);
    });
  });
}
