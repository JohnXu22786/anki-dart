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
 * Source-derived from AnkiBackendLanguage.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// A well-formed language identifier accepted by Anki's backend translations.
///
/// The host supplies Java's `Locale.Builder` conversion for identifiers that do
/// not already match the backend's conventional language identifier syntax.
/// The host conversion should call `setLanguageTag`, `clearExtensions`,
/// `build`, then `toLanguageTag`; it should return null only for Java's
/// `IllformedLocaleException`. Other host failures are allowed to propagate.
final class AnkiBackendLanguage {
  AnkiBackendLanguage._(this.value);

  /// Converts a language tag, clearing host-locale extensions and applying the
  /// app's language aliases.
  ///
  /// The source-compatible direct parser runs first and preserves its exact
  /// spelling, including underscore separators and noncanonical variants. Only
  /// after it fails is [localeToLanguageTag] called, with underscores replaced
  /// by hyphens. The host callback represents Java `Locale.Builder` conversion
  /// with extensions cleared.
  static AnkiBackendLanguage? fromLanguageTag(
    String languageTag, {
    required String? Function(String languageTag) localeToLanguageTag,
  }) {
    if (_isKotlinBlank(languageTag)) return null;

    final direct = _fromIdentifier(languageTag);
    if (direct != null) return direct;

    final converted = localeToLanguageTag(languageTag.replaceAll('_', '-'));
    if (converted == null) return null;
    return _fromIdentifier(converted);
  }

  /// The accepted backend identifier, preserving direct input spelling.
  final String value;

  static final RegExp _languageIdentifier = RegExp(
    r'^(?:[a-zA-Z]{2,3}|[a-zA-Z]{5,8})(?:[-_][a-zA-Z]{4})?(?:[-_](?:[a-zA-Z]{2}|[0-9]{3}))?(?:[-_](?:[a-zA-Z0-9]{5,8}|[0-9][a-zA-Z0-9]{3}))*$',
  );

  static AnkiBackendLanguage? _fromIdentifier(String language) {
    final match = _languageIdentifier.matchAsPrefix(language);
    if (match == null || match.end != language.length) return null;

    final value = switch (language) {
      'heb' => 'he',
      'ind' => 'id',
      'tgl' => 'tl',
      'hi' => 'hi-IN',
      _ => language,
    };
    return AnkiBackendLanguage._(value);
  }

  static bool _isKotlinBlank(String value) {
    for (final codeUnit in value.codeUnits) {
      if (!_isKotlinWhitespace(codeUnit)) return false;
    }
    return true;
  }

  // Kotlin Char.isWhitespace includes Unicode space, line, and paragraph
  // separators plus U+0009..U+000D and U+001C..U+001F.
  static bool _isKotlinWhitespace(int codeUnit) =>
      (codeUnit >= 0x0009 && codeUnit <= 0x000d) ||
      (codeUnit >= 0x001c && codeUnit <= 0x001f) ||
      codeUnit == 0x0020 ||
      codeUnit == 0x00a0 ||
      codeUnit == 0x1680 ||
      (codeUnit >= 0x2000 && codeUnit <= 0x200a) ||
      codeUnit == 0x2028 ||
      codeUnit == 0x2029 ||
      codeUnit == 0x202f ||
      codeUnit == 0x205f ||
      codeUnit == 0x3000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnkiBackendLanguage && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AnkiBackendLanguage(value=$value)';
}
