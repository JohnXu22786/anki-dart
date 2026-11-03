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
 * Source-derived from BackendStats.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('BackendStatsRaw', () {
    test('passes card stats, graphs, and graph preference bytes through', () {
      final calls = <String>[];
      final cardInput = Uint8List.fromList([0, 1, 255]);
      final cardResult = Uint8List.fromList([9, 0, 8]);
      final graphsInput = Uint8List.fromList([2, 0, 254]);
      final graphsResult = Uint8List.fromList([7, 6, 0]);
      final preferencesInput = Uint8List.fromList([3, 255, 4]);
      final preferencesResult = Uint8List.fromList([0, 5, 255]);
      final stats = BackendStatsRaw<_Preferences, _Builder>(
        BackendStatsRawCallbacks(
          cardStatsRaw: (input) {
            calls.add('cardStatsRaw');
            expect(input, same(cardInput));
            return cardResult;
          },
          graphsRaw: (input) {
            calls.add('graphsRaw');
            expect(input, same(graphsInput));
            return graphsResult;
          },
          setGraphPreferencesRaw: (input) {
            calls.add('setGraphPreferencesRaw');
            expect(input, same(preferencesInput));
            return preferencesResult;
          },
          getGraphPreferences: () => throw StateError('not used'),
          toBuilder: (_) => throw StateError('not used'),
          setBrowserLinksSupported: (_, _) => throw StateError('not used'),
          buildGraphPreferences: (_) => throw StateError('not used'),
          serializeGraphPreferences: (_) => throw StateError('not used'),
        ),
      );

      expect(stats.cardStatsRaw(cardInput), same(cardResult));
      expect(stats.graphsRaw(graphsInput), same(graphsResult));
      expect(
        stats.setGraphPreferencesRaw(preferencesInput),
        same(preferencesResult),
      );
      expect(calls, ['cardStatsRaw', 'graphsRaw', 'setGraphPreferencesRaw']);
    });

    test(
      'gets and copies preferences, disables browser links, then builds and serializes',
      () {
        final calls = <String>[];
        final original = _Preferences(browserLinksSupported: true);
        final builder = _Builder(
          browserLinksSupported: original.browserLinksSupported,
        );
        final built = _Preferences(browserLinksSupported: false);
        final serialized = Uint8List.fromList([0, 1, 2, 255]);
        final stats = BackendStatsRaw<_Preferences, _Builder>(
          BackendStatsRawCallbacks(
            cardStatsRaw: (_) => throw StateError('not used'),
            graphsRaw: (_) => throw StateError('not used'),
            setGraphPreferencesRaw: (_) => throw StateError('not used'),
            getGraphPreferences: () {
              calls.add('get');
              return original;
            },
            toBuilder: (preferences) {
              calls.add('toBuilder');
              expect(preferences, same(original));
              return builder;
            },
            setBrowserLinksSupported: (value, enabled) {
              calls.add('setBrowserLinksSupported');
              expect(value, same(builder));
              expect(enabled, isFalse);
              value.browserLinksSupported = enabled;
            },
            buildGraphPreferences: (value) {
              calls.add('build');
              expect(value, same(builder));
              expect(value.browserLinksSupported, isFalse);
              return built;
            },
            serializeGraphPreferences: (preferences) {
              calls.add('serialize');
              expect(preferences, same(built));
              return serialized;
            },
          ),
        );

        expect(stats.getGraphPreferencesRaw(), same(serialized));
        expect(original.browserLinksSupported, isTrue);
        expect(calls, [
          'get',
          'toBuilder',
          'setBrowserLinksSupported',
          'build',
          'serialize',
        ]);
      },
    );

    test('propagates a host callback exception unchanged', () {
      final failure = StateError('host failure');
      final calls = <String>[];
      final stats = BackendStatsRaw<_Preferences, _Builder>(
        BackendStatsRawCallbacks(
          cardStatsRaw: (_) => throw StateError('not used'),
          graphsRaw: (_) => throw StateError('not used'),
          setGraphPreferencesRaw: (_) => throw StateError('not used'),
          getGraphPreferences: () {
            calls.add('get');
            return _Preferences(browserLinksSupported: true);
          },
          toBuilder: (_) {
            calls.add('toBuilder');
            throw failure;
          },
          setBrowserLinksSupported: (_, _) =>
              calls.add('setBrowserLinksSupported'),
          buildGraphPreferences: (_) {
            calls.add('build');
            return _Preferences(browserLinksSupported: false);
          },
          serializeGraphPreferences: (_) => Uint8List(0),
        ),
      );

      expect(() => stats.getGraphPreferencesRaw(), throwsA(same(failure)));
      expect(calls, ['get', 'toBuilder']);
    });
  });
}

class _Preferences {
  _Preferences({required this.browserLinksSupported});

  final bool browserLinksSupported;
}

class _Builder {
  _Builder({required this.browserLinksSupported});

  bool browserLinksSupported;
}
