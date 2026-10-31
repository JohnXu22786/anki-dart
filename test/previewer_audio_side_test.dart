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
 * Source-derived Previewer audio-side projection cases.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Previewer audio side', () {
    test('back-side-only loads and plays both card sides', () {
      expect(
        previewerAudioSide(backSideOnly: true, showingAnswer: false),
        PreviewerAudioSide.both,
      );
      expect(
        previewerAudioSide(backSideOnly: true, showingAnswer: true),
        PreviewerAudioSide.both,
      );
    });

    test('answer side is selected when showing the answer normally', () {
      expect(
        previewerAudioSide(backSideOnly: false, showingAnswer: true),
        PreviewerAudioSide.answer,
      );
    });

    test('question side is selected when showing the question normally', () {
      expect(
        previewerAudioSide(backSideOnly: false, showingAnswer: false),
        PreviewerAudioSide.question,
      );
    });
  });
}
