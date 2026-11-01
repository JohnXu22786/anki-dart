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
 * Source-derived from AnkiDroidJsAPI.kt:150–189, 681–686; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'ankidroid_js_api_constants.dart';

/// Parsed request fields retained by the JS API contract.
///
/// This deliberately has identity equality, like the source Kotlin class.
class ApiContract {
  ApiContract({
    required this.isValid,
    required this.cardSuppliedDeveloperContact,
    required this.cardSuppliedData,
  });

  final bool isValid;
  final String cardSuppliedDeveloperContact;
  final String cardSuppliedData;
}

/// Host-provided parsing and comparison operations for Java semver versions.
///
/// Keeping these operations on the host preserves the exact `Version.parse`
/// and comparison behavior without adding a Dart semver implementation.
class JsApiVersionOperations<Version> {
  const JsApiVersionOperations({
    required this.parse,
    required this.equals,
    required this.isLowerThan,
    required this.isHigherThanOrEquivalentTo,
  });

  final Version Function(String value) parse;
  final bool Function(Version left, Version right) equals;
  final bool Function(Version version, Version other) isLowerThan;
  final bool Function(Version version, Version minimum)
  isHigherThanOrEquivalentTo;
}

/// Host effects used by the JS API version compatibility gate.
class JsApiVersionHostCallbacks {
  const JsApiVersionHostCallbacks({
    required this.showInvalidDataSnackbar,
    required this.showUpdateVersionSnackbar,
    required this.showValidVersionSnackbar,
    required this.warn,
  });

  final void Function(String detail) showInvalidDataSnackbar;
  final void Function(String developerContact) showUpdateVersionSnackbar;
  final void Function(String developerContact) showValidVersionSnackbar;
  final void Function(String message) warn;
}

/// Applies the portable `requireApiVersion()` policy from AnkiDroid.
///
/// The host supplies semver operations and UI/logging callbacks; JSON parsing,
/// Android thread scheduling, and the Java semver implementation stay there.
bool requireJsApiVersion<Version>({
  required String apiVer,
  required String apiDevContact,
  required JsApiVersionOperations<Version> versions,
  required JsApiVersionHostCallbacks host,
}) {
  try {
    if (apiDevContact.isEmpty || apiVer.isEmpty) {
      host.showInvalidDataSnackbar('');
      return false;
    }

    final versionCurrent = versions.parse(currentJsApiVersion);
    final versionSupplied = versions.parse(apiVer);

    if (versions.equals(versionSupplied, versionCurrent)) {
      return true;
    }
    if (versions.isLowerThan(versionSupplied, versionCurrent)) {
      host.showUpdateVersionSnackbar(apiDevContact);
      final minimumVersion = versions.parse(minimumJsApiVersion);
      return versions.isHigherThanOrEquivalentTo(
        versionSupplied,
        minimumVersion,
      );
    }

    host.showValidVersionSnackbar(apiDevContact);
    return false;
  } on Exception {
    host.warn('requireApiVersion::exception');
    return false;
  }
}
