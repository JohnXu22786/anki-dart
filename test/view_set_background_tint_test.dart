/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from View.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('setBackgroundTint', () {
    test('uses Float32 alpha arithmetic and Kotlin Float.toInt boundaries', () {
      final materialColors = _MaterialColorsAccess();
      final colorStateList = _ColorStateListAccess(_TintToken());
      final view = _ViewAccess<_TintToken>();

      for (final (alpha, expected) in <(double, int)>[
        (0.5, 127),
        // Kotlin receives this just-below-threshold value as the next Float32.
        (0.0039215686269, 1),
        (-0.5, -127),
        (1.25, 318),
        (double.nan, 0),
        (double.infinity, 0x7fffffff),
        (double.negativeInfinity, -0x80000000),
        (100000000.0, 0x7fffffff),
        (-100000000.0, -0x80000000),
      ]) {
        setBackgroundTint(
          0x12345678,
          alpha,
          materialColors,
          colorStateList,
          view,
        );
        expect(materialColors.alphaArguments.last, expected);
      }
    });

    test(
      'calls each host operation once in order and assigns its exact token',
      () {
        final events = <String>[];
        final tintToken = _TintToken();
        final materialColors = _MaterialColorsAccess(
          events: events,
          compositeResult: -0x1020304,
        );
        final colorStateList = _ColorStateListAccess(tintToken, events: events);
        final view = _ViewAccess<_TintToken>(events: events);

        setBackgroundTint(
          0x76543210,
          0.5,
          materialColors,
          colorStateList,
          view,
        );

        expect(events, ['composite', 'valueOf', 'assign']);
        expect(materialColors.colorArguments, [0x76543210]);
        expect(materialColors.alphaArguments, [127]);
        expect(colorStateList.colorArguments, [-0x1020304]);
        expect(view.assignedValues, hasLength(1));
        expect(identical(view.assignedValues.single, tintToken), isTrue);
      },
    );

    test(
      'composite failure propagates unchanged and skips later operations',
      () {
        final failure = StateError('composite failed');
        final events = <String>[];
        final materialColors = _MaterialColorsAccess(
          events: events,
          failure: failure,
        );
        final colorStateList = _ColorStateListAccess(
          _TintToken(),
          events: events,
        );
        final view = _ViewAccess<_TintToken>(events: events);

        expect(
          () => setBackgroundTint(
            0x12345678,
            0.5,
            materialColors,
            colorStateList,
            view,
          ),
          throwsA(same(failure)),
        );
        expect(events, ['composite']);
        expect(colorStateList.colorArguments, isEmpty);
        expect(view.assignedValues, isEmpty);
      },
    );

    test(
      'valueOf or assignment failure propagates unchanged and short-circuits',
      () {
        final valueOfFailure = StateError('valueOf failed');
        final valueOfEvents = <String>[];
        final materialColors = _MaterialColorsAccess(events: valueOfEvents);
        final colorStateList = _ColorStateListAccess(
          _TintToken(),
          events: valueOfEvents,
          failure: valueOfFailure,
        );
        final valueOfView = _ViewAccess<_TintToken>(events: valueOfEvents);

        expect(
          () => setBackgroundTint(
            0x12345678,
            0.5,
            materialColors,
            colorStateList,
            valueOfView,
          ),
          throwsA(same(valueOfFailure)),
        );
        expect(valueOfEvents, ['composite', 'valueOf']);
        expect(valueOfView.assignedValues, isEmpty);

        final assignmentFailure = StateError('assignment failed');
        final assignmentEvents = <String>[];
        final assignmentView = _ViewAccess<_TintToken>(
          events: assignmentEvents,
          failure: assignmentFailure,
        );
        expect(
          () => setBackgroundTint(
            0x12345678,
            0.5,
            _MaterialColorsAccess(events: assignmentEvents),
            _ColorStateListAccess(_TintToken(), events: assignmentEvents),
            assignmentView,
          ),
          throwsA(same(assignmentFailure)),
        );
        expect(assignmentEvents, ['composite', 'valueOf', 'assign']);
        expect(assignmentView.assignedValues, hasLength(1));
      },
    );
  });
}

class _TintToken {}

class _MaterialColorsAccess implements MaterialColorsAccess {
  _MaterialColorsAccess({this.events, this.compositeResult = 0, this.failure});

  final List<String>? events;
  final int compositeResult;
  final Object? failure;
  final colorArguments = <int>[];
  final alphaArguments = <int>[];

  @override
  int compositeARGBWithAlpha(int color, int alpha) {
    events?.add('composite');
    colorArguments.add(color);
    alphaArguments.add(alpha);
    if (failure case final error?) throw error;
    return compositeResult;
  }
}

class _ColorStateListAccess<TTint> implements ColorStateListAccess<TTint> {
  _ColorStateListAccess(this.token, {this.events, this.failure});

  final TTint token;
  final List<String>? events;
  final Object? failure;
  final colorArguments = <int>[];

  @override
  TTint valueOf(int color) {
    events?.add('valueOf');
    colorArguments.add(color);
    if (failure case final error?) throw error;
    return token;
  }
}

class _ViewAccess<TTint> implements ViewBackgroundTintAccess<TTint> {
  _ViewAccess({this.events, this.failure});

  final List<String>? events;
  final Object? failure;
  final assignedValues = <TTint>[];

  @override
  set backgroundTintList(TTint value) {
    events?.add('assign');
    assignedValues.add(value);
    if (failure case final error?) throw error;
  }
}
