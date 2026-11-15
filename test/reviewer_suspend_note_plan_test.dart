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
 * Source-derived Reviewer suspend-note effect cases; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reviewer suspend-note plan', () {
    test('suspends only the supplied note before feedback and reload', () {
      const noteId = 821;
      final effects = planReviewerSuspendNote(
        noteId: noteId,
        suspendedMessage: 'Note suspended',
      );

      expect(effects, hasLength(3));
      expect(effects.map((effect) => effect.runtimeType), [
        SuspendReviewerNoteEffect,
        ShowReviewerSuspendNoteFeedbackEffect,
        ReloadReviewerCurrentCardAfterNoteSuspendEffect,
      ]);
      expect((effects[0] as SuspendReviewerNoteEffect).noteIds, [noteId]);
    });

    test('passes host-localized feedback text through unchanged', () {
      const message = '  Note suspended — 暂停  ';

      final effects = planReviewerSuspendNote(
        noteId: 1,
        suspendedMessage: message,
      );

      expect(
        (effects[1] as ShowReviewerSuspendNoteFeedbackEffect).message,
        message,
      );
    });

    test('suspend effect carries no scheduler count result', () {
      final effect =
          planReviewerSuspendNote(
                noteId: 73,
                suspendedMessage: 'Suspended',
              ).first
              as SuspendReviewerNoteEffect;

      // The source discards suspendNotes()'s count; the host effect only needs
      // the singleton note IDs and its success/failure boundary.
      expect(effect.noteIds, [73]);
    });
  });
}
