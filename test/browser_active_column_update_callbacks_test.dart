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
 * Source-derived from AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('browser active-column update callbacks', () {
    test(
      'empty or unchanged columns skip all persistence and backend work',
      () async {
        final events = <String>[];
        final callbacks = BrowserActiveColumnUpdateCallbacks(
          readPreference: (_) async {
            events.add('read');
            return null;
          },
          defaultColumnKeys: (_) => ['question'],
          writePreference: (_, _) async => events.add('write'),
          scheduleActiveUpdate: (update) => events.add('schedule'),
          setBackendActiveColumns: (_) async => events.add('backend'),
          publishActiveColumns: (_) => events.add('publish'),
        );

        expect(
          await updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: const [],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.cards,
            callbacks: callbacks,
          ),
          isFalse,
        );
        expect(
          await updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: [BrowserColumn.question],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.cards,
            callbacks: callbacks,
          ),
          isFalse,
        );
        expect(events, isEmpty);
      },
    );

    test(
      'persists changed columns before scheduling current-mode update',
      () async {
        final events = <String>[];
        Future<void> Function()? scheduled;
        final callbacks = BrowserActiveColumnUpdateCallbacks(
          readPreference: (mode) async {
            events.add('read:$mode');
            return 'question';
          },
          defaultColumnKeys: (mode) {
            events.add('defaults:$mode');
            return ['question'];
          },
          writePreference: (mode, value) async =>
              events.add('write:$mode:$value'),
          scheduleActiveUpdate: (update) {
            events.add('schedule');
            scheduled = update;
          },
          setBackendActiveColumns: (keys) async =>
              events.add('backend:${keys.join(',')}'),
          publishActiveColumns: (columns) =>
              events.add('publish:${columns.preferenceValue}'),
        );

        expect(
          await updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: [BrowserColumn.answer, BrowserColumn.question],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.cards,
            callbacks: callbacks,
          ),
          isTrue,
        );
        expect(events, [
          'defaults:BrowserColumnMode.cards',
          'read:BrowserColumnMode.cards',
          'write:BrowserColumnMode.cards:answer|question',
          'schedule',
        ]);
        await scheduled!();
        expect(events, [
          'defaults:BrowserColumnMode.cards',
          'read:BrowserColumnMode.cards',
          'write:BrowserColumnMode.cards:answer|question',
          'schedule',
          'backend:answer,question',
          'publish:answer|question',
        ]);
      },
    );

    test(
      'preference exceptions fall back while errors still propagate',
      () async {
        final writes = <String>[];
        final fallbackCallbacks = BrowserActiveColumnUpdateCallbacks(
          readPreference: (_) async => throw Exception('preference failure'),
          defaultColumnKeys: (_) => ['question'],
          writePreference: (_, value) async => writes.add(value),
          scheduleActiveUpdate: (_) {},
          setBackendActiveColumns: (_) async {},
          publishActiveColumns: (_) {},
        );

        expect(
          await updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: [BrowserColumn.answer],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.notes,
            callbacks: fallbackCallbacks,
          ),
          isTrue,
        );
        expect(writes, ['answer']);

        final errorCallbacks = BrowserActiveColumnUpdateCallbacks(
          readPreference: (_) async => throw StateError('not an Exception'),
          defaultColumnKeys: (_) => ['question'],
          writePreference: (_, _) async => fail('write must not run'),
          scheduleActiveUpdate: (_) => fail('schedule must not run'),
          setBackendActiveColumns: (_) async {},
          publishActiveColumns: (_) {},
        );
        await expectLater(
          updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: [BrowserColumn.answer],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.notes,
            callbacks: errorCallbacks,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'persists a non-current mode without scheduling backend updates',
      () async {
        final events = <String>[];
        final callbacks = BrowserActiveColumnUpdateCallbacks(
          readPreference: (_) async => 'question',
          defaultColumnKeys: (_) => ['question'],
          writePreference: (_, value) async => events.add('write:$value'),
          scheduleActiveUpdate: (_) => events.add('schedule'),
          setBackendActiveColumns: (_) async => events.add('backend'),
          publishActiveColumns: (_) => events.add('publish'),
        );

        expect(
          await updateBrowserActiveColumns(
            currentActiveColumns: [BrowserColumn.question],
            requestedColumns: [BrowserColumn.answer],
            currentMode: BrowserColumnMode.cards,
            targetMode: BrowserColumnMode.notes,
            callbacks: callbacks,
          ),
          isTrue,
        );
        expect(events, ['write:answer']);
      },
    );

    test('backend failure prevents active-column publication', () async {
      final events = <String>[];
      Future<void> Function()? scheduled;
      final callbacks = BrowserActiveColumnUpdateCallbacks(
        readPreference: (_) async => 'question',
        defaultColumnKeys: (_) => ['question'],
        writePreference: (_, _) async => events.add('write'),
        scheduleActiveUpdate: (update) => scheduled = update,
        setBackendActiveColumns: (_) async {
          events.add('backend');
          throw StateError('backend failed');
        },
        publishActiveColumns: (_) => events.add('publish'),
      );

      await updateBrowserActiveColumns(
        currentActiveColumns: [BrowserColumn.question],
        requestedColumns: [BrowserColumn.answer],
        currentMode: BrowserColumnMode.cards,
        targetMode: BrowserColumnMode.cards,
        callbacks: callbacks,
      );
      await expectLater(scheduled!(), throwsStateError);

      expect(events, ['write', 'backend']);
    });
  });
}
