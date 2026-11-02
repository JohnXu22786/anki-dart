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
 * Source-derived from AnkiDroid 2.25.3 DeckPicker.kt:1871–1880 and
 * DeckPickerViewModel.kt:659–692.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Picker previous version preference', () {
    test(
      'checks for the stored key once before falling back and writing current',
      () {
        final calls = <String>[];
        final previousVersion = orchestrateDeckPickerVersionPreference(
          current: const DeckPickerVersionLong(25000000),
          contains: (key) {
            calls.add('contains:$key');
            return true;
          },
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (key, defaultValue) {
              calls.add('long:$key:${defaultValue.value}');
              throw const DeckPickerPreferenceTypeMismatch();
            },
            getInt: (key, defaultValue) {
              calls.add('int:$key:${defaultValue.value}');
              return const DeckPickerVersionInt(20900203);
            },
            getString: (_, _) => fail('did not attempt String fallback'),
            remove: (key) => calls.add('remove:$key'),
          ),
          setLong: (key, value) => calls.add('setLong:$key:${value.value}'),
        );

        expect(previousVersion.value, 20900203);
        expect(calls, [
          'contains:lastUpgradeVersion',
          'long:lastUpgradeVersion:25000000',
          'int:lastUpgradeVersion:20900203',
          'remove:lastUpgradeVersion',
          'setLong:lastUpgradeVersion:25000000',
        ]);
      },
    );

    test('uses current without getters or removal when the key is missing', () {
      final calls = <String>[];
      final previousVersion = orchestrateDeckPickerVersionPreference(
        current: const DeckPickerVersionLong(25000000),
        contains: (key) {
          calls.add('contains:$key');
          return false;
        },
        preferences: DeckPickerVersionPreferenceCallbacks(
          getLong: (_, _) => fail('did not read Long'),
          getInt: (_, _) => fail('did not read Int'),
          getString: (_, _) => fail('did not read String'),
          remove: (_) => fail('did not remove the key'),
        ),
        setLong: (key, value) => calls.add('setLong:$key:${value.value}'),
      );

      expect(previousVersion.value, 25000000);
      expect(calls, [
        'contains:lastUpgradeVersion',
        'setLong:lastUpgradeVersion:25000000',
      ]);
    });

    test(
      'propagates contains failure without reading or writing preferences',
      () {
        final failure = StateError('contains failed');
        var laterCallbackCalled = false;

        expect(
          () => orchestrateDeckPickerVersionPreference(
            current: const DeckPickerVersionLong(25000000),
            contains: (_) => throw failure,
            preferences: DeckPickerVersionPreferenceCallbacks(
              getLong: (_, _) {
                laterCallbackCalled = true;
                return const DeckPickerVersionLong(1);
              },
              getInt: (_, _) => const DeckPickerVersionInt(1),
              getString: (_, _) => '',
              remove: (_) {},
            ),
            setLong: (_, _) => laterCallbackCalled = true,
          ),
          throwsA(same(failure)),
        );
        expect(laterCallbackCalled, isFalse);
      },
    );

    test('does not write current after a present-key fallback failure', () {
      final failure = StateError('fallback failed');
      final calls = <String>[];

      expect(
        () => orchestrateDeckPickerVersionPreference(
          current: const DeckPickerVersionLong(25000000),
          contains: (key) {
            calls.add('contains:$key');
            return true;
          },
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (key, _) {
              calls.add('long:$key');
              throw const DeckPickerPreferenceTypeMismatch();
            },
            getInt: (key, _) {
              calls.add('int:$key');
              throw failure;
            },
            getString: (key, _) {
              calls.add('string:$key');
              return '';
            },
            remove: (key) => calls.add('remove:$key'),
          ),
          setLong: (key, value) => calls.add('setLong:$key:${value.value}'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, [
        'contains:lastUpgradeVersion',
        'long:lastUpgradeVersion',
        'int:lastUpgradeVersion',
      ]);
    });

    test('propagates current-version write failure after selection', () {
      final failure = StateError('write failed');
      final calls = <String>[];

      expect(
        () => orchestrateDeckPickerVersionPreference(
          current: const DeckPickerVersionLong(25000000),
          contains: (key) {
            calls.add('contains:$key');
            return false;
          },
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (_, _) => fail('did not read Long'),
            getInt: (_, _) => fail('did not read Int'),
            getString: (_, _) => fail('did not read String'),
            remove: (_) => fail('did not remove the key'),
          ),
          setLong: (key, value) {
            calls.add('setLong:$key:${value.value}');
            throw failure;
          },
        ),
        throwsA(same(failure)),
      );
      expect(calls, [
        'contains:lastUpgradeVersion',
        'setLong:lastUpgradeVersion:25000000',
      ]);
    });

    test('returns a Long read directly without removing the preference', () {
      final reads = <String>[];
      var removed = false;

      final version = getPreviousDeckPickerVersion(
        current: const DeckPickerVersionLong(25000000),
        preferences: DeckPickerVersionPreferenceCallbacks(
          getLong: (key, defaultValue) {
            reads.add('long:$key:${defaultValue.value}');
            return const DeckPickerVersionLong(24000000);
          },
          getInt: (_, _) => fail('did not attempt Int fallback'),
          getString: (_, _) => fail('did not attempt String fallback'),
          remove: (_) => removed = true,
        ),
      );

      expect(version.value, 24000000);
      expect(reads, ['long:lastUpgradeVersion:25000000']);
      expect(removed, isFalse);
    });

    test('falls back to Int with its source default then removes the key', () {
      final calls = <String>[];

      final version = getPreviousDeckPickerVersion(
        current: const DeckPickerVersionLong(25000000),
        preferences: DeckPickerVersionPreferenceCallbacks(
          getLong: (_, _) {
            calls.add('long');
            throw const DeckPickerPreferenceTypeMismatch();
          },
          getInt: (key, defaultValue) {
            calls.add('int:$key:${defaultValue.value}');
            return const DeckPickerVersionInt(20900203);
          },
          getString: (_, _) => fail('did not attempt String fallback'),
          remove: (key) => calls.add('remove:$key'),
        ),
      );

      expect(version.value, 20900203);
      expect(calls, [
        'long',
        'int:lastUpgradeVersion:20900203',
        'remove:lastUpgradeVersion',
      ]);
    });

    test('falls back to String and maps only the exact legacy value to 40', () {
      for (final value in ['2.0.2', '2.0.2 ', '2.0.3', '']) {
        final calls = <String>[];
        final version = getPreviousDeckPickerVersion(
          current: const DeckPickerVersionLong(25000000),
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (_, _) => throw const DeckPickerPreferenceTypeMismatch(),
            getInt: (_, _) => throw const DeckPickerPreferenceTypeMismatch(),
            getString: (key, defaultValue) {
              calls.add('string:$key:$defaultValue');
              return value;
            },
            remove: (key) => calls.add('remove:$key'),
          ),
        );

        expect(version.value, value == '2.0.2' ? 40 : 0);
        expect(calls, [
          'string:lastUpgradeVersion:',
          'remove:lastUpgradeVersion',
        ]);
      }
    });

    test('propagates String read failure without removing the preference', () {
      final failure = const DeckPickerPreferenceTypeMismatch();
      var removed = false;

      expect(
        () => getPreviousDeckPickerVersion(
          current: const DeckPickerVersionLong(25000000),
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (_, _) => throw const DeckPickerPreferenceTypeMismatch(),
            getInt: (_, _) => throw const DeckPickerPreferenceTypeMismatch(),
            getString: (_, _) => throw failure,
            remove: (_) => removed = true,
          ),
        ),
        throwsA(same(failure)),
      );
      expect(removed, isFalse);
    });

    test('propagates failures other than the preference type mismatch', () {
      final failure = StateError('storage failed');
      var attemptedFallback = false;

      expect(
        () => getPreviousDeckPickerVersion(
          current: const DeckPickerVersionLong(25000000),
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (_, _) => throw failure,
            getInt: (_, _) {
              attemptedFallback = true;
              return const DeckPickerVersionInt(0);
            },
            getString: (_, _) => '',
            remove: (_) {},
          ),
        ),
        throwsA(same(failure)),
      );
      expect(attemptedFallback, isFalse);
    });

    test('does not turn an Int read failure into a String fallback', () {
      final failure = StateError('int read failed');
      var attemptedString = false;
      var removed = false;

      expect(
        () => getPreviousDeckPickerVersion(
          current: const DeckPickerVersionLong(25000000),
          preferences: DeckPickerVersionPreferenceCallbacks(
            getLong: (_, _) => throw const DeckPickerPreferenceTypeMismatch(),
            getInt: (_, _) => throw failure,
            getString: (_, _) {
              attemptedString = true;
              return '';
            },
            remove: (_) => removed = true,
          ),
        ),
        throwsA(same(failure)),
      );
      expect(attemptedString, isFalse);
      expect(removed, isFalse);
    });
  });
}
