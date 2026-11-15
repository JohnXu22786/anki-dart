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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

typedef _ObjectCallbacks =
    PreferencesDestinationIntentCallbacks<Object, Object, Object>;

void main() {
  group('PreferencesDestination variants', () {
    test('exposes the three source variants as stable singletons', () {
      expect(PreferencesDestination.root, same(PreferencesDestination.root));
      expect(
        PreferencesDestination.advanced,
        same(PreferencesDestination.advanced),
      );
      expect(
        PreferencesDestination.accessibility,
        same(PreferencesDestination.accessibility),
      );
      expect(PreferencesDestination.root, isA<PreferencesDestinationRoot>());
      expect(
        PreferencesDestination.advanced,
        isA<PreferencesDestinationAdvanced>(),
      );
      expect(
        PreferencesDestination.accessibility,
        isA<PreferencesDestinationAccessibility>(),
      );
    });
  });

  group('PreferencesDestination.toIntent', () {
    test('delegates each variant once with exact host token and result', () {
      final context = Object();
      final advancedToken = Object();
      final accessibilityToken = Object();
      final rootIntent = Object();
      final advancedIntent = Object();
      final accessibilityIntent = Object();
      final calls = <Object?>[];
      final callbacks = _ObjectCallbacks(
        getRootIntent: (actualContext) {
          calls.add(('root', actualContext));
          return rootIntent;
        },
        getScreenIntent: (actualContext, screenToken) {
          calls.add(('screen', actualContext, screenToken));
          return identical(screenToken, advancedToken)
              ? advancedIntent
              : accessibilityIntent;
        },
      );

      expect(
        PreferencesDestination.root.toIntent(
          context: context,
          advancedSettingsFragment: advancedToken,
          accessibilitySettingsFragment: accessibilityToken,
          callbacks: callbacks,
        ),
        same(rootIntent),
      );
      expect(
        PreferencesDestination.advanced.toIntent(
          context: context,
          advancedSettingsFragment: advancedToken,
          accessibilitySettingsFragment: accessibilityToken,
          callbacks: callbacks,
        ),
        same(advancedIntent),
      );
      expect(
        PreferencesDestination.accessibility.toIntent(
          context: context,
          advancedSettingsFragment: advancedToken,
          accessibilitySettingsFragment: accessibilityToken,
          callbacks: callbacks,
        ),
        same(accessibilityIntent),
      );
      expect(calls, [
        ('root', context),
        ('screen', context, advancedToken),
        ('screen', context, accessibilityToken),
      ]);
      expect(
        identical((calls[1] as (String, Object, Object)).$2, context),
        isTrue,
      );
      expect(
        identical((calls[1] as (String, Object, Object)).$3, advancedToken),
        isTrue,
      );
      expect(
        identical(
          (calls[2] as (String, Object, Object)).$3,
          accessibilityToken,
        ),
        isTrue,
      );
    });

    test('propagates callback failures unchanged after one delegation', () {
      for (final failRoot in [true, false]) {
        final failure = StateError('host getIntent failed');
        final calls = <String>[];
        final callbacks = _ObjectCallbacks(
          getRootIntent: (_) {
            calls.add('root');
            if (failRoot) throw failure;
            return Object();
          },
          getScreenIntent: (_, _) {
            calls.add('screen');
            if (!failRoot) throw failure;
            return Object();
          },
        );

        expect(
          () =>
              (failRoot
                      ? PreferencesDestination.root
                      : PreferencesDestination.advanced)
                  .toIntent(
                    context: Object(),
                    advancedSettingsFragment: Object(),
                    accessibilitySettingsFragment: Object(),
                    callbacks: callbacks,
                  ),
          throwsA(same(failure)),
        );
        expect(calls, [failRoot ? 'root' : 'screen']);
      }
    });
  });
}
