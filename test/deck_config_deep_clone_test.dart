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
 * Source-derived from PythonExtensions.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('deepCloneDeckConfig', () {
    test('reads and clones jsonObject before copying and returns the copy', () {
      final config = Object();
      final jsonObject = Object();
      final clonedJsonObject = Object();
      final copiedConfig = Object();
      final calls = <String>[];

      final result = deepCloneDeckConfig(
        config: config,
        readJsonObject: (actualConfig) {
          calls.add('read');
          expect(identical(actualConfig, config), isTrue);
          return jsonObject;
        },
        deepCloneJsonObject: (actualJsonObject) {
          calls.add('clone');
          expect(identical(actualJsonObject, jsonObject), isTrue);
          return clonedJsonObject;
        },
        copyWithJsonObject: (actualConfig, actualJsonObject) {
          calls.add('copy');
          expect(identical(actualConfig, config), isTrue);
          expect(identical(actualJsonObject, clonedJsonObject), isTrue);
          return copiedConfig;
        },
      );

      expect(calls, ['read', 'clone', 'copy']);
      expect(identical(result, copiedConfig), isTrue);
    });

    test('a jsonObject getter failure prevents cloning and copying', () {
      final failure = StateError('getter failed');
      final calls = <String>[];

      expect(
        () => deepCloneDeckConfig<Object, Object>(
          config: Object(),
          readJsonObject: (_) {
            calls.add('read');
            throw failure;
          },
          deepCloneJsonObject: (_) {
            calls.add('clone');
            return Object();
          },
          copyWithJsonObject: (_, __) {
            calls.add('copy');
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['read']);
    });

    test('a deep-clone failure prevents copying', () {
      final failure = StateError('clone failed');
      final calls = <String>[];

      expect(
        () => deepCloneDeckConfig<Object, Object>(
          config: Object(),
          readJsonObject: (_) {
            calls.add('read');
            return Object();
          },
          deepCloneJsonObject: (_) {
            calls.add('clone');
            throw failure;
          },
          copyWithJsonObject: (_, __) {
            calls.add('copy');
            return Object();
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['read', 'clone']);
    });
  });
}
