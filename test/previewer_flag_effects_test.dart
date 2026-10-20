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
 * Source-derived Previewer flag projection cases. The pinned ViewModel test
 * exercises RED but not every Flag code or write failure.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('PreviewerFlag', () {
    test('retains all AnkiDroid flag codes in source enum order', () {
      expect(
        PreviewerFlag.values.map((flag) => flag.code),
        [0, 1, 2, 3, 4, 5, 6, 7],
      );
      expect(
        PreviewerFlag.values,
        [
          PreviewerFlag.none,
          PreviewerFlag.red,
          PreviewerFlag.orange,
          PreviewerFlag.green,
          PreviewerFlag.blue,
          PreviewerFlag.pink,
          PreviewerFlag.turquoise,
          PreviewerFlag.purple,
        ],
      );
    });
  });

  group('Previewer flag effects', () {
    test('set writes the one current card, then publishes the same flag', () {
      const cardId = 982451653;
      const target = PreviewerFlag.purple;

      final effects = previewerSetFlagEffects(cardId: cardId, flag: target);

      _expectOrderedWriteAndPublish(effects, cardId, target);
    });

    test('toggling the current flag clears it to NONE', () {
      const cardId = 7;
      final effects = previewerToggleFlagEffects(
        cardId: cardId,
        currentFlag: PreviewerFlag.red,
        requestedFlag: PreviewerFlag.red,
      );

      _expectOrderedWriteAndPublish(effects, cardId, PreviewerFlag.none);
    });

    test('toggling a different flag selects the requested value', () {
      const cardId = 8;
      final effects = previewerToggleFlagEffects(
        cardId: cardId,
        currentFlag: PreviewerFlag.red,
        requestedFlag: PreviewerFlag.green,
      );

      _expectOrderedWriteAndPublish(effects, cardId, PreviewerFlag.green);
    });

    test('NONE follows the same enum equality rule and still plans a write',
        () {
      const cardId = 9;
      final sameNone = previewerToggleFlagEffects(
        cardId: cardId,
        currentFlag: PreviewerFlag.none,
        requestedFlag: PreviewerFlag.none,
      );
      final requestedNone = previewerToggleFlagEffects(
        cardId: cardId,
        currentFlag: PreviewerFlag.blue,
        requestedFlag: PreviewerFlag.none,
      );

      _expectOrderedWriteAndPublish(sameNone, cardId, PreviewerFlag.none);
      _expectOrderedWriteAndPublish(requestedNone, cardId, PreviewerFlag.none);
    });
  });
}

void _expectOrderedWriteAndPublish(
  List<PreviewerFlagEffect> effects,
  int cardId,
  PreviewerFlag flag,
) {
  expect(effects, hasLength(2));
  expect(
    effects.map((effect) => effect.runtimeType),
    [PreviewerSetUserFlagForCardsEffect, PreviewerPublishFlagOnSuccessEffect],
  );
  final write = effects[0] as PreviewerSetUserFlagForCardsEffect;
  expect(write.cardIds, [cardId]);
  expect(write.flag, flag);
  final publish = effects[1] as PreviewerPublishFlagOnSuccessEffect;
  expect(publish.flag, same(flag));
}
