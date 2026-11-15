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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentShowRepositionDialog', () {
    test(
      'sets up dialog in order with the same opaque values and item count',
      () {
        final harness = _Harness();

        cardTemplateFragmentShowRepositionDialog(callbacks: harness.callbacks);

        expect(harness.events, [
          'require context',
          'pager adapter',
          'adapter item count',
          'show dialog',
        ]);
        expect(harness.dialogContext, same(harness.context));
        expect(harness.dialogItemCount, 7);
        expect(harness.confirmation, isNotNull);
        expect(harness.ordinalReads, 0);
        expect(harness.warnings, isEmpty);
      },
    );

    test(
      'confirmation warns once then preserves the exact source TODO failure',
      () {
        final harness = _Harness();

        cardTemplateFragmentShowRepositionDialog(callbacks: harness.callbacks);
        expect(harness.ordinalReads, 0);
        expect(harness.warnings, isEmpty);

        expect(
          () => harness.confirmation!(23),
          throwsA(
            isA<UnimplementedError>().having(
              (error) => error.message,
              'message',
              'CardTemplateNotetype is a complex class and requires significant testing',
            ),
          ),
        );
        expect(harness.events, [
          'require context',
          'pager adapter',
          'adapter item count',
          'show dialog',
          'ordinal',
          'warning',
        ]);
        expect(harness.ordinalReads, 1);
        expect(harness.warningFormat, 'moving card template %d to %d');
        expect(harness.warningCurrentPosition, 12);
        expect(harness.warningNewPosition, 23);
      },
    );

    test('setup failures and missing adapter stop later setup work', () {
      for (final stage in [
        'require context',
        'pager adapter',
        'adapter item count',
        'show dialog',
      ]) {
        final harness = _Harness(failAt: stage);
        expect(
          () => cardTemplateFragmentShowRepositionDialog(
            callbacks: harness.callbacks,
          ),
          throwsA(same(harness.failure)),
          reason: stage,
        );
        expect(harness.events.last, stage, reason: stage);
        expect(harness.confirmation, isNull, reason: stage);
      }

      final harness = _Harness(nullAdapter: true);
      expect(
        () => cardTemplateFragmentShowRepositionDialog(
          callbacks: harness.callbacks,
        ),
        throwsA(isA<TypeError>()),
      );
      expect(harness.events, ['require context', 'pager adapter']);
    });

    test('confirmation callback failures propagate and stop later work', () {
      for (final stage in ['ordinal', 'warning']) {
        final harness = _Harness(failAt: stage);
        cardTemplateFragmentShowRepositionDialog(callbacks: harness.callbacks);

        expect(
          () => harness.confirmation!(23),
          throwsA(same(harness.failure)),
          reason: stage,
        );
        expect(harness.events.last, stage, reason: stage);
        expect(harness.ordinalReads, stage == 'ordinal' ? 0 : 1);
        expect(harness.warnings, isEmpty);
      }
    });
  });
}

final class _Harness {
  _Harness({this.failAt, this.nullAdapter = false});

  final String? failAt;
  final bool nullAdapter;
  final events = <String>[];
  final failure = StateError('callback failed');
  final context = Object();
  final adapter = Object();
  void Function(int newPosition)? confirmation;
  Object? dialogContext;
  int? dialogItemCount;
  int ordinalReads = 0;
  final warnings = <(String, int, int)>[];

  String? warningFormat;
  int? warningCurrentPosition;
  int? warningNewPosition;

  void _record(String stage) {
    events.add(stage);
    if (failAt == stage) throw failure;
  }

  late final callbacks =
      CardTemplateFragmentShowRepositionDialogCallbacks<Object, Object>(
        requireContext: () {
          _record('require context');
          return context;
        },
        readPagerAdapter: () {
          _record('pager adapter');
          return nullAdapter ? null : adapter;
        },
        readAdapterItemCount: (value) {
          expect(value, same(adapter));
          _record('adapter item count');
          return 7;
        },
        showRepositionDialog:
            ({required context, required itemCount, required onConfirm}) {
              _record('show dialog');
              dialogContext = context;
              dialogItemCount = itemCount;
              confirmation = onConfirm;
            },
        readOrdinal: () {
          _record('ordinal');
          ordinalReads++;
          return 12;
        },
        warn: (format, currentPosition, newPosition) {
          _record('warning');
          warningFormat = format;
          warningCurrentPosition = currentPosition;
          warningNewPosition = newPosition;
          warnings.add((format, currentPosition, newPosition));
        },
      );
}
