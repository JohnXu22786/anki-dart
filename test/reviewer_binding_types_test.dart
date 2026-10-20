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
 * Behavioral reference: Binding.kt, ReviewerBinding.kt, MappableBinding.kt,
 * and CardSide.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  const codec = ReviewerBindingCodec();

  group('typed reviewer binding values', () {
    test('decodes key codes and canonicalizes modifiers in source order', () {
      final binding = codec.decodeBinding('⌨ShiftedCtrl+Alt+00088');

      expect(binding, isA<ReviewerKeyCodeBinding>());
      final key = binding as ReviewerKeyCodeBinding;
      expect(key.keyCode, 88);
      expect(key.modifierKeys.shift, isTrue);
      expect(key.modifierKeys.ctrl, isTrue);
      expect(key.modifierKeys.alt, isTrue);
      expect(key.toString(), '⌨Ctrl+Alt+Shift+88');
      expect(codec.decode('1/r⌨ShiftedCtrl+Alt+000882').single.binding, key);
    });

    test('parses only text before the final plus as modifiers', () {
      final binding = codec.decodeBinding('⌨Ctrl+Alt+not-a-modifier+9');

      expect(binding, isA<ReviewerKeyCodeBinding>());
      final key = binding as ReviewerKeyCodeBinding;
      expect(key.modifierKeys.ctrl, isTrue);
      expect(key.modifierKeys.alt, isTrue);
      expect(key.modifierKeys.shift, isFalse);
      expect(key.keyCode, 9);
      expect(key.toString(), '⌨Ctrl+Alt+9');
    });

    test('uses signed 32-bit key codes and returns Unknown outside that range',
        () {
      expect(
        (codec.decodeBinding('⌨2147483647') as ReviewerKeyCodeBinding).keyCode,
        2147483647,
      );
      expect(
        (codec.decodeBinding('⌨-2147483648') as ReviewerKeyCodeBinding).keyCode,
        -2147483648,
      );
      expect(codec.decodeBinding('⌨2147483648'), isA<ReviewerUnknownBinding>());
      expect(
          codec.decodeBinding('⌨-2147483649'), isA<ReviewerUnknownBinding>());
      expect(codec.decodeBinding('⌨+'), isA<ReviewerUnknownBinding>());
    });

    test('typed key-code constructors enforce the source Int range', () {
      expect(
        () => ReviewerKeyCodeBinding(keyCode: 2147483648),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReviewerKeyCodeBinding(keyCode: -2147483649),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReviewerBindingValue.forKeyCode(2147483648),
        throwsA(isA<RangeError>()),
      );
    });

    test('decodes one UTF-16 code unit and preserves Unicode bindings', () {
      final binding = codec.decodeBinding('✅Ctrl+Alt+Shift+Ä');

      expect(binding, isA<ReviewerUnicodeCharacterBinding>());
      final character = binding as ReviewerUnicodeCharacterBinding;
      expect(character.codeUnit, 'Ä'.codeUnitAt(0));
      expect(character.modifierKeys.toString(), 'Ctrl+Alt+Shift+');
      expect(character.toString(), '✅Ctrl+Alt+Shift+Ä');

      final supplementary = codec.decodeBinding('✅😀');
      expect(supplementary, isA<ReviewerUnicodeCharacterBinding>());
      expect(
          (supplementary as ReviewerUnicodeCharacterBinding).codeUnit, 0xD83D);
      expect(supplementary.toString().codeUnits.last, 0xD83D);
    });

    test('typed Unicode constructors enforce the source Char range', () {
      expect(
        () => ReviewerUnicodeCharacterBinding(codeUnit: -1),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReviewerUnicodeCharacterBinding(codeUnit: 0x10000),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReviewerBindingValue.forUnicodeCharacter(0x10000),
        throwsA(isA<RangeError>()),
      );
    });

    test('keeps decoded Unicode wrappers typed and serializable', () {
      final binding = codec.decode('1/r✅Ctrl+A1').single;

      expect(binding.binding, isA<ReviewerUnicodeCharacterBinding>());
      expect(binding.isKey, isTrue);
      expect(binding.side, ReviewerCardSide.answer);
      expect(codec.encode([binding]), '1/r✅Ctrl+A1');
    });

    test('deserialization accepts separator character but factory rejects it',
        () {
      final decoded = codec.decodeBinding('✅|');
      final made = ReviewerBindingValue.forUnicodeCharacter(0x7C);

      expect(decoded, isA<ReviewerUnicodeCharacterBinding>());
      expect((decoded as ReviewerUnicodeCharacterBinding).toString(), '✅|');
      expect(made.binding, isA<ReviewerUnknownBinding>());
      expect(made.isValid, isFalse);
      expect(made.toPreferenceString(), isNull);
    });

    test('distinguishes parsed no-modifier keys from AppDefined defaults', () {
      final parsed =
          codec.decodeBinding('✅A') as ReviewerUnicodeCharacterBinding;
      final made = ReviewerBindingValue.forUnicodeCharacter(0x41).binding
          as ReviewerUnicodeCharacterBinding;

      expect(parsed.modifierKeys, isNot(isA<ReviewerAppDefinedModifierKeys>()));
      expect(parsed.modifierKeys.shiftMatches(true), isFalse);
      expect(made.modifierKeys, isA<ReviewerAppDefinedModifierKeys>());
      expect(made.modifierKeys.shiftMatches(true), isTrue);
      expect(made.modifierKeys.shiftMatches(false), isTrue);
      expect(parsed.modifierKeys, made.modifierKeys);
      expect(parsed.modifierKeys.hashCode, isNot(made.modifierKeys.hashCode));
      expect(parsed, made);
      // This source equality/hash quirk is intentional: AppDefined matches
      // both shift states but its modifier hash uses shiftMatches(true).
      // UnicodeCharacter itself then omits modifiers from its own hash.
      expect(parsed.hashCode, made.hashCode);

      final shifted = ReviewerModifierKeys(shift: true);
      final allowShift = ReviewerAppDefinedModifierKeys.allowShift();
      expect(allowShift, shifted);
      expect(allowShift.hashCode, shifted.hashCode);
    });

    test('preserves key data-class equality and key-code-only hash', () {
      final noModifier = ReviewerKeyCodeBinding(keyCode: 88);
      final control = ReviewerKeyCodeBinding(
        keyCode: 88,
        modifierKeys: const ReviewerModifierKeys(ctrl: true),
      );

      expect(noModifier, isNot(control));
      expect(noModifier.hashCode, control.hashCode);
    });

    test('unknown data object instances compare equally with the same hash',
        () {
      final first = ReviewerUnknownBinding();
      final second = ReviewerUnknownBinding();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.isValid, isFalse);
      expect(first.toString(), isEmpty);
    });
  });

  group('reviewer binding wrapper semantics', () {
    test('serializes side codes and applies BOTH as an equality wildcard', () {
      final question = ReviewerBindingValue.forKeyCode(
        88,
        side: ReviewerCardSide.question,
      );
      final answer = ReviewerBindingValue.forKeyCode(
        88,
        side: ReviewerCardSide.answer,
      );
      final both = ReviewerBindingValue.forKeyCode(88);

      expect(codec.encode([question, answer, both]),
          '1/r⌨88' '0|r⌨88' '1|r⌨88' '2');
      expect(question, both);
      expect(both, answer);
      expect(question, isNot(answer));
      expect(question.hashCode, answer.hashCode);
      expect(answer.hashCode, both.hashCode);
      expect(ReviewerCardSide.fromAnswer(true), ReviewerCardSide.answer);
      expect(ReviewerCardSide.fromAnswer(false), ReviewerCardSide.question);
    });

    test('marks typed key and Unicode values as keys', () {
      expect(ReviewerBindingValue.forKeyCode(88).isKey, isTrue);
      expect(ReviewerBindingValue.forUnicodeCharacter(0x41).isKey, isTrue);
      expect(ReviewerBindingValue.forGesture(Gesture.tapTop).isKey, isFalse);
    });
  });
}
