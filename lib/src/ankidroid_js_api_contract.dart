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
 * Source-derived from AnkiDroidJsAPI.kt:83–100, 150–189, 616–686; see
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

/// Host operations used to parse and project an AnkiDroid JS API request.
///
/// [parseObject] captures the host byte decoding and `JSONObject` creation;
/// [optString] must delegate to the host object's `optString` so its fallback,
/// null, and coercion rules stay source-compatible. The remaining callbacks
/// classify and handle the host's source-equivalent `JSONException`. In
/// particular, [showInvalidJsonSnackbar] owns UI-thread scheduling, localized
/// string resolution, and Snackbar display.
class JsApiContractHostAdapter<ParsedObject> {
  const JsApiContractHostAdapter({
    required this.parseObject,
    required this.optString,
    required this.isJsonException,
    required this.logJsonException,
    required this.showInvalidJsonSnackbar,
  });

  final ParsedObject Function() parseObject;
  final String Function(ParsedObject object, String key, String fallback)
  optString;
  final bool Function(Exception exception) isJsonException;
  final void Function(Exception exception) logJsonException;
  final void Function(Exception exception) showInvalidJsonSnackbar;
}

/// Projects the source `parseJsApiContract()` behavior over host-parsed JSON.
///
/// Parsing and all three field reads occur inside the source JSON exception
/// boundary. Field reads are eager and ordered before [requireJsApiVersion];
/// only a host-classified source-equivalent `JSONException` is logged and
/// passed to the host's invalid-JSON UI callback before returning null.
ApiContract? parseJsApiContract<ParsedObject, Version>({
  required JsApiContractHostAdapter<ParsedObject> host,
  required JsApiVersionOperations<Version> versions,
  required JsApiVersionHostCallbacks versionHost,
}) {
  try {
    final parsedObject = host.parseObject();
    final version = host.optString(parsedObject, 'version', '');
    final developer = host.optString(parsedObject, 'developer', '');
    final data = host.optString(parsedObject, 'data', '');
    final isValid = requireJsApiVersion(
      apiVer: version,
      apiDevContact: developer,
      versions: versions,
      host: versionHost,
    );
    return ApiContract(
      isValid: isValid,
      cardSuppliedDeveloperContact: developer,
      cardSuppliedData: data,
    );
  } on Exception catch (exception) {
    if (!host.isJsonException(exception)) {
      rethrow;
    }
    host.logJsonException(exception);
    host.showInvalidJsonSnackbar(exception);
    return null;
  }
}

/// The source `ApiResult` envelope without Android `JSONObject` encoding.
///
/// [toOrderedHostMap] provides the fields in source insertion order. The Android
/// host remains responsible for Java number formatting, JSON encoding, and
/// UTF-8 conversion. These variants deliberately use identity equality.
sealed class ApiResult {
  ApiResult(this.status);

  final bool status;

  /// Projects the source envelope as ordered fields for host-side encoding.
  Map<String, Object> toOrderedHostMap() => {
    SUCCESS_KEY: status,
    VALUE_KEY: _value,
  };

  Object get _value;

  factory ApiResult.success(String value) => ApiResultString(true, value);

  factory ApiResult.failure(String value) => ApiResultString(false, value);
}

/// Source `ApiResult.Boolean`; the value remains distinct from numeric variants.
final class ApiResultBoolean extends ApiResult {
  ApiResultBoolean(super.status, this.value);

  final bool value;

  @override
  bool get _value => value;
}

/// Source `ApiResult.Integer` (a JVM `Int`).
final class ApiResultInteger extends ApiResult {
  ApiResultInteger(super.status, this.value);

  final int value;

  @override
  int get _value => value;
}

/// Source `ApiResult.Float` (a JVM `Float`), retained as its own variant.
final class ApiResultFloat extends ApiResult {
  ApiResultFloat(super.status, this.value);

  final double value;

  @override
  double get _value => value;
}

/// Source `ApiResult.Long`; distinct from `Integer` despite Dart's shared type.
final class ApiResultLong extends ApiResult {
  ApiResultLong(super.status, this.value);

  final int value;

  @override
  int get _value => value;
}

/// Source `ApiResult.String`.
final class ApiResultString extends ApiResult {
  ApiResultString(super.status, this.value);

  final String value;

  @override
  String get _value => value;
}

/// Projects the source Boolean `convertToByteArray` overload to its variant.
ApiResultBoolean apiResultFromBoolean(ApiContract contract, bool value) =>
    ApiResultBoolean(contract.isValid, value);

/// Projects the source Int `convertToByteArray` overload to its variant.
ApiResultInteger apiResultFromInteger(ApiContract contract, int value) =>
    ApiResultInteger(contract.isValid, value);

/// Projects the source Long `convertToByteArray` overload to its variant.
ApiResultLong apiResultFromLong(ApiContract contract, int value) =>
    ApiResultLong(contract.isValid, value);

/// Projects the source String `convertToByteArray` overload to its variant.
ApiResultString apiResultFromString(ApiContract contract, String value) =>
    ApiResultString(contract.isValid, value);

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
