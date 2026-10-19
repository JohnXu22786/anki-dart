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
 * Behavioral reference: MappableBinding.kt, ReviewerBinding.kt, Binding.kt,
 * Axis.kt, CardSide.kt, and ViewerCommand.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  const codec = ReviewerBindingCodec();

  group('ReviewerBindingCodec', () {
    test('null, empty, and unversioned preference values produce no entries',
        () {
      expect(codec.decode(null), isEmpty);
      expect(codec.decode(''), isEmpty);
      expect(codec.decode('r⍝TAP_TOP2'), isEmpty);
      expect(codec.decode('2/r⍝TAP_TOP2'), isEmpty);
    });

    test('splits list values and filters empty entries', () {
      final bindings = codec.decode('1/||r⍝TAP_TOP2|||r⍝TAP_BOTTOM1|');

      expect(bindings, hasLength(2));
      expect(bindings[0].gesture, Gesture.tapTop);
      expect(bindings[1].gesture, Gesture.tapBottom);
      expect(codec.encode(bindings), '1/r⍝TAP_TOP2|r⍝TAP_BOTTOM1');
    });

    test('writes exact gesture identifiers and reviewer side suffixes', () {
      final allGestures = codec.encode([
        for (final gesture in Gesture.values)
          ReviewerBindingValue.forGesture(gesture),
      ]);
      expect(
        allGestures,
        '1/r⍝SWIPE_UP2|r⍝SWIPE_DOWN2|r⍝SWIPE_LEFT2|r⍝SWIPE_RIGHT2|'
        'r⍝DOUBLE_TAP2|r⍝TAP_TOP_LEFT2|r⍝TAP_TOP2|r⍝TAP_TOP_RIGHT2|'
        'r⍝TAP_LEFT2|r⍝TAP_CENTER2|r⍝TAP_RIGHT2|r⍝TAP_BOTTOM_LEFT2|'
        'r⍝TAP_BOTTOM2|r⍝TAP_BOTTOM_RIGHT2|r⍝TWO_FINGER_TAP2|'
        'r⍝THREE_FINGER_TAP2|r⍝FOUR_FINGER_TAP2|r⍝SHAKE2',
      );
      expect(
        codec.decode(allGestures).map((binding) => binding.gesture),
        Gesture.values,
      );

      expect(
        codec.encode([
          ReviewerBindingValue.forGesture(
            Gesture.tapTop,
            side: ReviewerCardSide.question,
          ),
          ReviewerBindingValue.forGesture(
            Gesture.swipeUp,
            side: ReviewerCardSide.answer,
          ),
          ReviewerBindingValue.forGesture(Gesture.shake),
        ]),
        '1/r⍝TAP_TOP0|r⍝SWIPE_UP1|r⍝SHAKE2',
      );
    });

    test('preserves a valid keyboard binding as non-gesture data', () {
      final binding = codec.decode('1/r⌨Ctrl+00071').single;

      expect(binding.kind, ReviewerBindingKind.nonGesture);
      expect(binding.isValid, isTrue);
      expect(codec.encode([binding]), '1/r⌨Ctrl+71');
    });

    test('parses Kotlin Unicode decimal digits in key codes and axis IDs', () {
      final bindings = codec.decode('1/r⌨٢2|r◯٢ 1.02');

      expect(
        bindings.map((binding) => binding.kind),
        everyElement(ReviewerBindingKind.nonGesture),
      );
      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        ['r⌨22', 'r◯2 1.02'],
      );
    });

    test('uses Java Float serialization and ignores extra axis tokens', () {
      final bindings = codec.decode(
        '1/r◯0 0x1.0p02|r◯0 1.0 extra2|'
        'r◯0 0.100000001490116122',
      );

      expect(bindings, hasLength(3));
      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        ['r◯0 1.02', 'r◯0 1.02', 'r◯0 0.12'],
      );
    });

    test('rounds hexadecimal floats directly to binary32 at boundaries', () {
      final bindings = codec.decode(
        '1/r◯0 0x0p9999999999999999999999992|'
        'r◯0 0x1p9999999999999999999999992|'
        'r◯0 0x1p-9999999999999999999999992|'
        'r◯0 0x1p-1502|'
        'r◯0 0x1.000002p-1502|'
        'r◯0 0x1.fffffep1272',
      );

      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        [
          'r◯0 0.02',
          'r◯0 Infinity2',
          'r◯0 0.02',
          'r◯0 0.02',
          'r◯0 1.4E-452',
          'r◯0 3.4028235E382',
        ],
      );
    });

    test('hexadecimal floats that round beyond binary32 become infinity', () {
      final bindings = codec.decode(
        '1/r◯0 0x1.ffffff8p1272|r◯0 -0x1.ffffff8p1272',
      );

      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        ['r◯0 Infinity2', 'r◯0 -Infinity2'],
      );
    });

    test('uses ties-to-even decimal digits when formatting Java floats', () {
      final bindings = codec.decode(
        '1/r◯0 -0x1.8f5e8p122|r◯0 0x1.d725aap212',
      );

      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        ['r◯0 -6389.90622', 'r◯0 3859637.22'],
      );
    });

    test('parses decimal Float32 midpoint values without binary64 double-round',
        () {
      final bindings = codec.decode(
        '1/r◯0 1.00000005960464477539062500000000000000012|'
        'r◯0 1.0000000596046447753906252|'
        'r◯0 1.00000005960464477539062492|'
        'r◯0 -1.00000005960464477539062500000000000000012',
      );

      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        [
          'r◯0 1.00000012',
          'r◯0 1.02',
          'r◯0 1.02',
          'r◯0 -1.00000012',
        ],
      );
    });

    test('handles extreme decimal float exponents like Java', () {
      final bindings = codec.decode(
        '1/r◯0 0e9999999999999999999999992|'
        'r◯0 1e9999999999999999999999992|'
        'r◯0 -1e-9999999999999999999999992',
      );

      expect(
        bindings.map((binding) => binding.toPreferenceString()),
        ['r◯0 0.02', 'r◯0 Infinity2', 'r◯0 -0.02'],
      );
    });

    test('uses Java float parsing whitespace boundaries', () {
      final bindings = codec.decode('1/r◯0 1.0\t2|r◯0 \u00a01.0\u00a02');

      expect(bindings[0].kind, ReviewerBindingKind.nonGesture);
      expect(bindings[0].toPreferenceString(), 'r◯0 1.02');
      expect(bindings[1].kind, ReviewerBindingKind.unknown);
    });

    test('rejects malformed axis bindings without routing valid axes', () {
      final bindings = codec.decode(
        '1/r◯0 1.02|r◯20 -1.02|r◯7 1.02|r◯999 1.02|'
        'r◯0 not-a-float2|r◯0 2',
      );

      expect(bindings, hasLength(6));
      expect(
        bindings.take(2).map((binding) => binding.kind),
        everyElement(ReviewerBindingKind.nonGesture),
      );
      expect(bindings.first.toPreferenceString(), 'r◯0 1.02');
      expect(
        bindings.skip(2).map((binding) => binding.kind),
        everyElement(ReviewerBindingKind.unknown),
      );
      expect(codec.encode(bindings), '1/r◯0 1.02|r◯20 -1.02');
    });

    test('accepts a missing reviewer prefix and maps unknown suffixes to both',
        () {
      final bindings = codec.decode('1/⍝TAP_TOP0|r⍝TAP_BOTTOMx');

      expect(bindings, hasLength(2));
      expect(bindings[0].gesture, Gesture.tapTop);
      expect(bindings[0].side, ReviewerCardSide.question);
      expect(bindings[1].gesture, Gesture.tapBottom);
      expect(bindings[1].side, ReviewerCardSide.both);
    });

    test('malformed and unknown bindings stay invalid and are omitted on write',
        () {
      final bindings = codec.decode(
        '1/|r⍝NOT_A_GESTURE2|z0|r0|r⌨not-a-number0||',
      );

      expect(bindings, hasLength(4));
      expect(
        bindings.map((binding) => binding.kind),
        everyElement(ReviewerBindingKind.unknown),
      );
      expect(codec.encode(bindings), '1/');
    });

    test('uses UTF-16 code units when removing the side suffix', () {
      final bindings = codec.decode('1/r⍝TAP_TOP😀');

      expect(bindings, hasLength(1));
      expect(bindings.single.side, ReviewerCardSide.both);
      expect(bindings.single.kind, ReviewerBindingKind.unknown);
    });
  });

  test('router factory ignores non-gesture and missing preference bindings',
      () {
    ViewerCommand? routedCommand;
    final router = GestureCommandRouter.fromPreferenceValues(
      isEnabled: true,
      cornerTouchEnabled: true,
      serializedBindingsByCommand: {
        // An absent preference must not add the source's keyboard defaults.
        ViewerCommand.ANSWER_GOOD: null,
        ViewerCommand.ANSWER_AGAIN: '1/r⌨291|r⍝TAP_TOP1',
      },
      executeCommand: (command, _) {
        routedCommand = command;
        return true;
      },
    );

    expect(router.route(Gesture.tapTop), isTrue);
    expect(routedCommand, ViewerCommand.ANSWER_AGAIN);
    expect(router.route(Gesture.tapBottom), isFalse);
  });
}
