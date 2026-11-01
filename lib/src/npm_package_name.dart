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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from NpmUtils.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'kotlin_whitespace.dart';

/// Checks a package name using the ordered rules in AnkiDroid's `NpmUtils`.
///
/// The host supplies [lowercase] to preserve Java's default-locale behavior,
/// [urlEncode] for Java `URLEncoder.encode(value, "UTF-8")`, and [logInfo] for
/// Timber info messages. Callback exceptions propagate unchanged.
bool validateNpmPackageName(
  String name, {
  required String Function(String value) lowercase,
  required String Function(String value) urlEncode,
  required void Function(String message) logInfo,
}) {
  if (trimKotlinWhitespace(name).isEmpty) {
    logInfo('Invalid package name: non-empty characters allowed');
    return false;
  }

  if (trimKotlinWhitespace(name) != name) {
    logInfo('Invalid package name: non-empty characters allowed');
    return false;
  }

  if (name.length > 214) {
    logInfo('Invalid package name: name string length less than 214 allowed');
    return false;
  }

  if (name.startsWith('.') || name.startsWith('_')) {
    logInfo(
      'Invalid package name: name cannot start with a period or an underscore',
    );
    return false;
  }

  if (lowercase(name) != name) {
    logInfo('Invalid package name: only small letters allowed');
    return false;
  }

  if (name.startsWith('@')) {
    if (name.indexOf('@') != name.lastIndexOf('@')) {
      logInfo("Invalid scoped package name: only one '@' allowed");
      return false;
    }

    if (!name.contains('/')) {
      logInfo("Invalid scoped package name: must have '/'");
      return false;
    }

    if (name.indexOf('/') != name.lastIndexOf('/')) {
      logInfo("Invalid scoped package name: only one '/' allowed");
      return false;
    }

    final parts = name.split('/');
    final scope = parts[0].replaceFirst('@', '');
    if (!validateNpmPackageName(
      scope,
      lowercase: lowercase,
      urlEncode: urlEncode,
      logInfo: logInfo,
    )) {
      return false;
    }

    return validateNpmPackageName(
      parts[1],
      lowercase: lowercase,
      urlEncode: urlEncode,
      logInfo: logInfo,
    );
  }

  if (urlEncode(name) != name) {
    logInfo('Invalid package name: only URL safe characters allowed');
    return false;
  }

  if ("~'!()*".codeUnits.any(name.codeUnits.contains)) {
    logInfo('Invalid package name: no special characters allowed');
    return false;
  }

  return true;
}
