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
 * Source-derived CardViewerViewModel sound-action cases; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CardViewer sound actions', () {
    test(
      'awaits the card, resolves its URL, then plays the same tag',
      () async {
        final calls = <String>[];
        final card = Object();
        final tag = Object();
        final url = 'https://host.invalid/playsound:q:0';

        await playCardViewerSoundFromUrl<Object, Object>(
          url: url,
          awaitCurrentCard: () async {
            calls.add('currentCard');
            return card;
          },
          getAvTag: (resolvedCard, resolvedUrl) async {
            calls.add('resolve');
            expect(identical(resolvedCard, card), isTrue);
            expect(identical(resolvedUrl, url), isTrue);
            return tag;
          },
          playOne: (resolvedTag) {
            calls.add('play');
            expect(identical(resolvedTag, tag), isTrue);
          },
        );

        expect(calls, ['currentCard', 'resolve', 'play']);
      },
    );

    test('does not play when the host resolver returns no AV tag', () async {
      final calls = <String>[];

      await playCardViewerSoundFromUrl<Object, Object>(
        url: 'unresolved URL',
        awaitCurrentCard: () {
          calls.add('currentCard');
          return Object();
        },
        getAvTag: (_, __) {
          calls.add('resolve');
          return null;
        },
        playOne: (_) => calls.add('play'),
      );

      expect(calls, ['currentCard', 'resolve']);
    });
  });
}
