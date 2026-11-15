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
 * Behavioral reference: CardBrowserViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('runBrowserAppendSelectedRowsEffects', () {
    test(
      'emits the supplied reason before one refresh and one log when rows remain',
      () {
        final reason = Object();
        final effects = <String>[];

        runBrowserAppendSelectedRowsEffects(
          hasSelectedRows: true,
          reason: reason,
          emitMultiSelectModeChanged: (value) {
            expect(identical(value, reason), isTrue);
            effects.add('mode');
          },
          refreshSelectedRows: () => effects.add('refresh'),
          logRefreshedSelectedRows: () => effects.add('log'),
        );

        expect(effects, ['mode', 'refresh', 'log']);
      },
    );

    test('skips the reason when empty but still refreshes and logs', () {
      final effects = <String>[];

      runBrowserAppendSelectedRowsEffects(
        hasSelectedRows: false,
        reason: Object(),
        emitMultiSelectModeChanged: (_) => effects.add('mode'),
        refreshSelectedRows: () => effects.add('refresh'),
        logRefreshedSelectedRows: () => effects.add('log'),
      );

      expect(effects, ['refresh', 'log']);
    });

    test(
      'a mode callback failure propagates and stops refresh and logging',
      () {
        final error = StateError('mode failed');
        final effects = <String>[];

        expect(
          () => runBrowserAppendSelectedRowsEffects(
            hasSelectedRows: true,
            reason: Object(),
            emitMultiSelectModeChanged: (_) {
              effects.add('mode');
              throw error;
            },
            refreshSelectedRows: () => effects.add('refresh'),
            logRefreshedSelectedRows: () => effects.add('log'),
          ),
          throwsA(same(error)),
        );
        expect(effects, ['mode']);
      },
    );

    test('a refresh failure propagates unchanged and stops logging', () {
      final error = StateError('refresh failed');
      final effects = <String>[];

      expect(
        () => runBrowserAppendSelectedRowsEffects(
          hasSelectedRows: true,
          reason: Object(),
          emitMultiSelectModeChanged: (_) => effects.add('mode'),
          refreshSelectedRows: () {
            effects.add('refresh');
            throw error;
          },
          logRefreshedSelectedRows: () => effects.add('log'),
        ),
        throwsA(same(error)),
      );
      expect(effects, ['mode', 'refresh']);
    });
  });

  group('runBrowserRemoveSelectedRowsEffects', () {
    test('emits the supplied reason only when empty and enabled', () {
      for (final hasSelectedRows in [false, true]) {
        for (final disableMultiSelectIfEmpty in [false, true]) {
          final reason = Object();
          final effects = <String>[];

          runBrowserRemoveSelectedRowsEffects(
            hasSelectedRows: hasSelectedRows,
            disableMultiSelectIfEmpty: disableMultiSelectIfEmpty,
            reason: reason,
            emitSingleSelectModeChanged: (value) {
              expect(identical(value, reason), isTrue);
              effects.add('mode');
            },
            refreshSelectedRows: () => effects.add('refresh'),
            logRefreshedSelectedRows: () => effects.add('log'),
          );

          expect(
            effects,
            !hasSelectedRows && disableMultiSelectIfEmpty
                ? ['mode', 'refresh', 'log']
                : ['refresh', 'log'],
          );
        }
      }
    });

    test('defaults to disabling multi-select when the last row is removed', () {
      final reason = Object();
      final effects = <String>[];

      runBrowserRemoveSelectedRowsEffects(
        hasSelectedRows: false,
        reason: reason,
        emitSingleSelectModeChanged: (value) {
          expect(identical(value, reason), isTrue);
          effects.add('mode');
        },
        refreshSelectedRows: () => effects.add('refresh'),
        logRefreshedSelectedRows: () => effects.add('log'),
      );

      expect(effects, ['mode', 'refresh', 'log']);
    });

    test(
      'a mode callback failure propagates and stops refresh and logging',
      () {
        final error = StateError('mode failed');
        final effects = <String>[];

        expect(
          () => runBrowserRemoveSelectedRowsEffects(
            hasSelectedRows: false,
            reason: Object(),
            emitSingleSelectModeChanged: (_) {
              effects.add('mode');
              throw error;
            },
            refreshSelectedRows: () => effects.add('refresh'),
            logRefreshedSelectedRows: () => effects.add('log'),
          ),
          throwsA(same(error)),
        );
        expect(effects, ['mode']);
      },
    );

    test('a refresh failure propagates unchanged and stops logging', () {
      final error = StateError('refresh failed');
      final effects = <String>[];

      expect(
        () => runBrowserRemoveSelectedRowsEffects(
          hasSelectedRows: false,
          reason: Object(),
          emitSingleSelectModeChanged: (_) => effects.add('mode'),
          refreshSelectedRows: () {
            effects.add('refresh');
            throw error;
          },
          logRefreshedSelectedRows: () => effects.add('log'),
        ),
        throwsA(same(error)),
      );
      expect(effects, ['mode', 'refresh']);
    });
  });
}
