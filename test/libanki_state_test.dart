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
 * Source-derived from LibAnki.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. The pinned source has no direct test assertions for
 * these fields.
 */

// ignore_for_file: deprecated_member_use

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    LibAnki.backend = null;
    LibAnki.collection = null;
  });

  group('LibAnki global state', () {
    test('both fields default to and accept null', () {
      expect(LibAnki.backend, isNull);
      expect(LibAnki.collection, isNull);

      LibAnki.backend = null;
      LibAnki.collection = null;

      expect(LibAnki.backend, isNull);
      expect(LibAnki.collection, isNull);
    });

    test('retains exact opaque objects independently', () {
      final backend = Object();
      final collection = Object();

      LibAnki.backend = backend;
      LibAnki.collection = collection;

      expect(identical(LibAnki.backend, backend), isTrue);
      expect(identical(LibAnki.collection, collection), isTrue);
      expect(identical(LibAnki.backend, collection), isFalse);
      expect(identical(LibAnki.collection, backend), isFalse);
    });

    test('overwriting one field leaves the other unchanged', () {
      final initialBackend = Object();
      final replacementBackend = Object();
      final initialCollection = Object();
      final replacementCollection = Object();

      LibAnki.backend = initialBackend;
      LibAnki.collection = initialCollection;
      LibAnki.backend = replacementBackend;

      expect(identical(LibAnki.backend, replacementBackend), isTrue);
      expect(identical(LibAnki.collection, initialCollection), isTrue);

      LibAnki.collection = replacementCollection;

      expect(identical(LibAnki.backend, replacementBackend), isTrue);
      expect(identical(LibAnki.collection, replacementCollection), isTrue);
    });
  });
}
