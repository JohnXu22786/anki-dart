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
 * Source-derived from `fetchSyncIconState` and `SyncIconState` in
 * DeckPickerViewModel.kt, AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Deck Picker sync icon projection', () {
    test('gates auth and backend work in source order', () {
      final disabled = planDeckPickerSyncIconFetch(
        displaySyncStatus: false,
        authState: DeckPickerSyncAuthState.notChecked,
      );
      expect(disabled.shouldLookupAuth, isFalse);
      expect(disabled.shouldRequestStatus, isFalse);
      expect(disabled.finalState, DeckPickerSyncIconState.normal);

      final authPending = planDeckPickerSyncIconFetch(
        displaySyncStatus: true,
        authState: DeckPickerSyncAuthState.notChecked,
      );
      expect(authPending.shouldLookupAuth, isTrue);
      expect(authPending.shouldRequestStatus, isFalse);
      expect(authPending.finalState, isNull);

      final loggedOut = planDeckPickerSyncIconFetch(
        displaySyncStatus: true,
        authState: DeckPickerSyncAuthState.unavailable,
      );
      expect(loggedOut.shouldLookupAuth, isFalse);
      expect(loggedOut.shouldRequestStatus, isFalse);
      expect(loggedOut.finalState, DeckPickerSyncIconState.notLoggedIn);

      final authenticated = planDeckPickerSyncIconFetch(
        displaySyncStatus: true,
        authState: DeckPickerSyncAuthState.available,
      );
      expect(authenticated.shouldLookupAuth, isFalse);
      expect(authenticated.shouldRequestStatus, isTrue);
      expect(authenticated.finalState, isNull);
    });

    test('maps every recognized required status', () {
      const mappings = <DeckPickerSyncRequiredStatus, DeckPickerSyncIconState>{
        DeckPickerSyncRequiredStatus.noChanges: DeckPickerSyncIconState.normal,
        DeckPickerSyncRequiredStatus.normalSync:
            DeckPickerSyncIconState.pendingChanges,
        DeckPickerSyncRequiredStatus.fullSync: DeckPickerSyncIconState.oneWay,
      };

      for (final entry in mappings.entries) {
        final effects = projectDeckPickerSyncIconResponse(
          DeckPickerSyncStatusSuccess(requiredStatus: entry.key),
        ).toList();
        expect(effects, [SetDeckPickerSyncIconEffect(entry.value)]);
      }
    });

    test('persists a nonempty new endpoint before projecting the icon', () {
      final effects = projectDeckPickerSyncIconResponse(
        const DeckPickerSyncStatusSuccess(
          requiredStatus: DeckPickerSyncRequiredStatus.normalSync,
          hasNewEndpoint: true,
          newEndpoint: 'https://sync.example.test/',
        ),
      ).toList();

      expect(effects, [
        const PersistDeckPickerSyncEndpointEffect('https://sync.example.test/'),
        const SetDeckPickerSyncIconEffect(
          DeckPickerSyncIconState.pendingChanges,
        ),
      ]);
      expect(
        projectDeckPickerSyncIconResponse(
          const DeckPickerSyncStatusSuccess(
            requiredStatus: DeckPickerSyncRequiredStatus.noChanges,
            hasNewEndpoint: false,
            newEndpoint: 'https://ignored.example.test/',
          ),
        ).toList(),
        [const SetDeckPickerSyncIconEffect(DeckPickerSyncIconState.normal)],
      );
      expect(
        projectDeckPickerSyncIconResponse(
          const DeckPickerSyncStatusSuccess(
            requiredStatus: DeckPickerSyncRequiredStatus.noChanges,
            hasNewEndpoint: true,
            newEndpoint: '',
          ),
        ).toList(),
        [const SetDeckPickerSyncIconEffect(DeckPickerSyncIconState.normal)],
      );
    });

    test('caught backend errors select the Normal icon', () {
      expect(
        projectDeckPickerSyncIconResponse(
          const DeckPickerSyncStatusFailure(),
        ).toList(),
        [const SetDeckPickerSyncIconEffect(DeckPickerSyncIconState.normal)],
      );
    });

    test(
      'null and unrecognized required statuses preserve the source TODO',
      () {
        expect(
          () => projectDeckPickerSyncIconResponse(
            const DeckPickerSyncStatusSuccess(requiredStatus: null),
          ).toList(),
          throwsA(isA<UnimplementedError>()),
        );
        expect(
          () => projectDeckPickerSyncIconResponse(
            const DeckPickerSyncStatusSuccess(
              requiredStatus: DeckPickerSyncRequiredStatus.unrecognized,
            ),
          ).toList(),
          throwsA(isA<UnimplementedError>()),
        );
      },
    );

    test('applies a new endpoint before an unrecognized status throws', () {
      final effects = projectDeckPickerSyncIconResponse(
        const DeckPickerSyncStatusSuccess(
          requiredStatus: DeckPickerSyncRequiredStatus.unrecognized,
          hasNewEndpoint: true,
          newEndpoint: 'https://sync.example.test/',
        ),
      );
      final iterator = effects.iterator;

      expect(iterator.moveNext(), isTrue);
      expect(
        iterator.current,
        const PersistDeckPickerSyncEndpointEffect('https://sync.example.test/'),
      );
      expect(() => iterator.moveNext(), throwsA(isA<UnimplementedError>()));
    });
  });
}
