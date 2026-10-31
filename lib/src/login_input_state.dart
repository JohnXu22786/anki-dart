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
 * Source-derived from LoginViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The input errors represented by AnkiDroid's login fields.
enum LoginError { emptyUsername, emptyPassword }

/// Local state for LoginViewModel's input validation.
///
/// The host owns field focus, text inputs, StateFlow publication, and UI.
final class LoginInputState {
  bool _loginButtonEnabled = false;
  LoginError? _userNameError;
  LoginError? _passwordError;

  bool get loginButtonEnabled => _loginButtonEnabled;
  LoginError? get userNameError => _userNameError;
  LoginError? get passwordError => _passwordError;

  /// Mirrors `onUserNameFocusChange`: only an empty, unfocused value errors.
  void onUserNameFocusChange(bool hasFocus, String userName) {
    _userNameError = !hasFocus && userName.isEmpty
        ? LoginError.emptyUsername
        : null;
  }

  /// Mirrors `onPasswordFocusChange`: only an empty, unfocused value errors.
  void onPasswordFocusChange(bool hasFocus, String password) {
    _passwordError = !hasFocus && password.isEmpty
        ? LoginError.emptyPassword
        : null;
  }

  /// Mirrors `onTextChanged`; whitespace counts as nonempty and is not trimmed.
  void onTextChanged({required String userName, required String password}) {
    _loginButtonEnabled = userName.isNotEmpty && password.isNotEmpty;
  }
}

/// The result states exposed by LoginViewModel.
sealed class LoginState {
  const LoginState();
}

/// Initial login state.
final class LoginStateIdle extends LoginState {
  const LoginStateIdle._();

  static const instance = LoginStateIdle._();
}

/// Successful login state.
final class LoginStateSuccess extends LoginState {
  const LoginStateSuccess._();

  static const instance = LoginStateSuccess._();
}

/// Error state carrying the original exception as opaque host data.
///
/// The host owns any conversion or presentation; this value must not be
/// formatted or logged because the source exception may contain PII.
final class LoginStateError extends LoginState {
  const LoginStateError(this.exception);

  final Exception exception;
}
