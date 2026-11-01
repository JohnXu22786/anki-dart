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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from AddonData.kt, AddonModel.kt, AddonsConst.kt, and
 * AnkiDroidJsAPIConstants.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'npm_package_name.dart';
import 'ankidroid_js_api_constants.dart';
import 'kotlin_string_hash_code.dart';
import 'kotlin_whitespace.dart';

const ankidroidJsAddonKeyword = 'ankidroid-js-addon';
const reviewerAddon = 'reviewer';
const noteEditorAddon = 'note-editor';

/// Parsed package manifest fields consumed by AnkiDroid's add-on projection.
///
/// Parsing JSON, including unknown-key handling, remains the host's job.
class AddonData {
  const AddonData({
    this.name,
    this.addonTitle,
    this.icon,
    this.version,
    this.description,
    this.main,
    this.ankidroidJsApi,
    this.addonType,
    this.keywords,
    this.author,
    this.license,
    this.homepage,
    this.dist,
  });

  final String? name;
  final String? addonTitle;
  final String? icon;
  final String? version;
  final String? description;
  final String? main;
  final String? ankidroidJsApi;
  final String? addonType;
  final List<String>? keywords;
  final Map<String, String>? author;
  final String? license;
  final String? homepage;
  final DistInfo? dist;
}

/// npm registry tarball information; absent for locally installed add-ons.
final class DistInfo {
  const DistInfo(this.tarball);

  final String tarball;

  @override
  bool operator ==(Object other) =>
      other is DistInfo && other.tarball == tarball;

  @override
  int get hashCode => kotlinStringHashCode(tarball);

  @override
  String toString() => 'DistInfo(tarball=$tarball)';
}

/// A validated add-on manifest projection or its validation errors.
sealed class AddonValidationResult {
  const AddonValidationResult();
}

final class AddonValidationResultValid extends AddonValidationResult {
  const AddonValidationResultValid(this.addonModel);

  final AddonModel addonModel;

  @override
  bool operator ==(Object other) =>
      other is AddonValidationResultValid && other.addonModel == addonModel;

  @override
  int get hashCode => addonModel.hashCode;

  @override
  String toString() => 'Valid(addonModel=$addonModel)';
}

final class AddonValidationResultInvalid extends AddonValidationResult {
  const AddonValidationResultInvalid(this.errors);

  final List<String> errors;

  @override
  bool operator ==(Object other) =>
      other is AddonValidationResultInvalid &&
      _orderedIterableEquals(other.errors, errors);

  @override
  int get hashCode => _kotlinStringListHashCode(errors);

  @override
  String toString() => 'Invalid(errors=$errors)';
}

/// The validated values exposed to the add-on host.
final class AddonModel {
  const AddonModel({
    required this.name,
    required this.addonTitle,
    required this.icon,
    required this.version,
    required this.description,
    required this.main,
    required this.ankidroidJsApi,
    required this.addonType,
    required this.keywords,
    required this.author,
    required this.license,
    required this.homepage,
    required this.dist,
  });

  final String name;
  final String addonTitle;
  final String icon;
  final String version;
  final String description;
  final String main;
  final String ankidroidJsApi;
  final String addonType;
  final List<String> keywords;
  final Map<String, String> author;
  final String license;
  final String homepage;
  final DistInfo? dist;

  @override
  bool operator ==(Object other) =>
      other is AddonModel &&
      other.name == name &&
      other.addonTitle == addonTitle &&
      other.icon == icon &&
      other.version == version &&
      other.description == description &&
      other.main == main &&
      other.ankidroidJsApi == ankidroidJsApi &&
      other.addonType == addonType &&
      _orderedIterableEquals(other.keywords, keywords) &&
      _stringMapEquals(other.author, author) &&
      other.license == license &&
      other.homepage == homepage &&
      other.dist == dist;

  @override
  int get hashCode => _kotlinDataClassHashCode([
    kotlinStringHashCode(name),
    kotlinStringHashCode(addonTitle),
    kotlinStringHashCode(icon),
    kotlinStringHashCode(version),
    kotlinStringHashCode(description),
    kotlinStringHashCode(main),
    kotlinStringHashCode(ankidroidJsApi),
    kotlinStringHashCode(addonType),
    _kotlinStringListHashCode(keywords),
    _kotlinStringMapHashCode(author),
    kotlinStringHashCode(license),
    kotlinStringHashCode(homepage),
    dist?.hashCode ?? 0,
  ]);

  @override
  String toString() =>
      'AddonModel(name=$name, addonTitle=$addonTitle, icon=$icon, '
      'version=$version, description=$description, main=$main, '
      'ankidroidJsApi=$ankidroidJsApi, addonType=$addonType, '
      'keywords=$keywords, author=${_kotlinStringMap(author)}, license=$license, '
      'homepage=$homepage, dist=$dist)';
}

/// Validates and projects parsed manifest data using the pinned AnkiDroid rules.
///
/// The host supplies Java default-locale lowercasing, Java UTF-8 form URL
/// encoding, and Timber info logging callbacks. Callback exceptions propagate.
AddonValidationResult getAddonModelFromAddonData(
  AddonData addonData, {
  required String Function(String value) lowercase,
  required String Function(String value) urlEncode,
  required void Function(String message) logInfo,
}) {
  if (_isNullOrBlank(addonData.name) ||
      _isNullOrBlank(addonData.addonTitle) ||
      _isNullOrBlank(addonData.main) ||
      _isNullOrBlank(addonData.version) ||
      _isNullOrBlank(addonData.ankidroidJsApi) ||
      _isNullOrBlank(addonData.addonType) ||
      _isNullOrBlank(addonData.homepage) ||
      addonData.keywords == null ||
      addonData.keywords!.isEmpty) {
    return const AddonValidationResultInvalid([
      'Invalid addon package: fields in package.json are empty or null',
    ]);
  }

  final errorList = <String>[];

  if (!validateNpmPackageName(
    addonData.name!,
    lowercase: lowercase,
    urlEncode: urlEncode,
    logInfo: logInfo,
  )) {
    errorList.add('Invalid addon package: package name failed validation');
  }

  if (addonData.addonType != reviewerAddon &&
      addonData.addonType != noteEditorAddon) {
    errorList.add(
      "Invalid addon package: ${addonData.addonType} is not valid addon type, "
      "package.json must have 'addonType' fields of 'reviewer' or "
      "'note-editor'",
    );
  }

  if (addonData.addonType == noteEditorAddon &&
      _isNullOrBlank(addonData.icon)) {
    errorList.add(
      "Invalid addon package: note editor addon must have 'icon' fields in "
      'package.json',
    );
  }

  if (!addonData.keywords!.contains(ankidroidJsAddonKeyword)) {
    errorList.add(
      "Invalid addon package: package.json does not have "
      "'ankidroid-js-addon' in ${addonData.keywords} keywords",
    );
  }

  if (addonData.ankidroidJsApi != currentJsApiVersion) {
    errorList.add(
      'Invalid addon package: supplied js api version '
      '${addonData.ankidroidJsApi} must be equal to current js api version '
      '$currentJsApiVersion',
    );
  }

  if (errorList.isNotEmpty) {
    return AddonValidationResultInvalid(errorList);
  }

  final icon = addonData.addonType == noteEditorAddon ? addonData.icon! : '';
  return AddonValidationResultValid(
    AddonModel(
      name: addonData.name!,
      addonTitle: addonData.addonTitle!,
      icon: icon,
      version: addonData.version!,
      description: addonData.description ?? '',
      main: addonData.main!,
      ankidroidJsApi: addonData.ankidroidJsApi!,
      addonType: addonData.addonType!,
      keywords: addonData.keywords!,
      author: addonData.author ?? const {},
      license: addonData.license ?? '',
      homepage: addonData.homepage!,
      dist: addonData.dist,
    ),
  );
}

bool _isNullOrBlank(String? value) =>
    value == null || trimKotlinWhitespace(value).isEmpty;

bool _orderedIterableEquals<T>(Iterable<T> left, Iterable<T> right) {
  if (left.length != right.length) {
    return false;
  }
  final leftIterator = left.iterator;
  final rightIterator = right.iterator;
  while (leftIterator.moveNext()) {
    if (!rightIterator.moveNext() ||
        leftIterator.current != rightIterator.current) {
      return false;
    }
  }
  return !rightIterator.moveNext();
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _kotlinStringListHashCode(List<String> value) {
  var hash = 1;
  for (final item in value) {
    hash = _kotlinInt32(31 * hash + kotlinStringHashCode(item));
  }
  return hash;
}

int _kotlinStringMapHashCode(Map<String, String> value) {
  var hash = 0;
  for (final entry in value.entries) {
    hash = _kotlinInt32(
      hash +
          (kotlinStringHashCode(entry.key) ^ kotlinStringHashCode(entry.value)),
    );
  }
  return hash;
}

int _kotlinDataClassHashCode(List<int> fields) {
  var hash = fields.first;
  for (final field in fields.skip(1)) {
    hash = _kotlinInt32(31 * hash + field);
  }
  return hash;
}

int _kotlinInt32(int value) {
  final unsigned = value & 0xFFFFFFFF;
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}

String _kotlinStringMap(Map<String, String> value) =>
    '{${value.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}}';
