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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2025 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived cases for LoginViewModel input validation and state variants;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Login input validation', () {
    test('focus changes report empty fields only after focus is lost', () {
      final state = LoginInputState();

      state.onUserNameFocusChange(false, '');
      state.onPasswordFocusChange(false, '');
      expect(state.userNameError, LoginError.emptyUsername);
      expect(state.passwordError, LoginError.emptyPassword);

      state.onUserNameFocusChange(true, '');
      state.onPasswordFocusChange(true, '');
      expect(state.userNameError, isNull);
      expect(state.passwordError, isNull);

      state.onUserNameFocusChange(false, 'user');
      state.onPasswordFocusChange(false, 'secret');
      expect(state.userNameError, isNull);
      expect(state.passwordError, isNull);
    });

    test(
      'login is enabled only when both values are nonempty without trimming',
      () {
        final state = LoginInputState();
        expect(state.loginButtonEnabled, isFalse);

        state.onTextChanged(userName: 'user', password: '');
        expect(state.loginButtonEnabled, isFalse);
        state.onTextChanged(userName: '', password: 'secret');
        expect(state.loginButtonEnabled, isFalse);
        state.onTextChanged(userName: ' ', password: '\t');
        expect(state.loginButtonEnabled, isTrue);
        state.onTextChanged(userName: 'user', password: 'secret');
        expect(state.loginButtonEnabled, isTrue);
      },
    );
  });

  group('Login state', () {
    test('has singleton Idle and Success states', () {
      expect(LoginStateIdle.instance, same(LoginStateIdle.instance));
      expect(LoginStateSuccess.instance, same(LoginStateSuccess.instance));
    });

    test('Error retains the opaque exception object by identity', () {
      final exception = Object();
      final state = LoginStateError(exception);

      expect(state.exception, same(exception));
    });
  });
}
