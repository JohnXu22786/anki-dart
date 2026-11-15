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
 * Source-derived from Exceptions.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Projects `Context.getUserFriendlyErrorText(e)` through host callbacks.
///
/// The host supplies exception type/property access, Kotlin-compatible blank
/// checking, and localized resource lookup. A translatable exception's message
/// is returned directly, including when blank. Otherwise, the first nonblank
/// value among [getLocalizedMessage], [getMessage], and
/// [getExceptionSimpleName] is returned, followed by [getUnknownErrorText].
/// Callback failures propagate immediately and unchanged.
String contextGetUserFriendlyErrorText({
  required Object error,
  required bool Function(Object error) isTranslatableException,
  required String Function(Object error) getTranslatedMessage,
  required String? Function(Object error) getLocalizedMessage,
  required String? Function(Object error) getMessage,
  required String? Function(Object error) getExceptionSimpleName,
  required bool Function(String text) isBlank,
  required String Function() getUnknownErrorText,
}) {
  if (isTranslatableException(error)) {
    return getTranslatedMessage(error);
  }

  final localizedMessage = getLocalizedMessage(error);
  if (localizedMessage != null && !isBlank(localizedMessage)) {
    return localizedMessage;
  }

  final message = getMessage(error);
  if (message != null && !isBlank(message)) {
    return message;
  }

  final simpleName = getExceptionSimpleName(error);
  if (simpleName != null && !isBlank(simpleName)) {
    return simpleName;
  }

  return getUnknownErrorText();
}
