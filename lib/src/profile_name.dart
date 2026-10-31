/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: ProfileName.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'kotlin_whitespace.dart';

/// A validated, user-facing profile display name.
///
/// Use [validate] for raw user input. [fromTrustedSource] intentionally keeps
/// persisted or hard-coded values unchanged, including values that would fail
/// input validation.
final class ProfileName {
  ProfileName._(this.value);

  /// Maximum Kotlin/JVM `String.length`, measured in UTF-16 code units.
  static const maxLength = 50;

  /// The exact profile display text.
  final String value;

  /// Constructs a profile name from a value already validated elsewhere.
  ///
  /// This mirrors AnkiDroid's internal persisted-value boundary. Do not use it
  /// for user input; use [validate] instead.
  factory ProfileName.fromTrustedSource(String value) => ProfileName._(value);

  /// Validates raw input using Kotlin `String.trim()` and UTF-16 length rules.
  static ProfileNameValidationResult validate(String raw) {
    final cleaned = trimKotlinWhitespace(raw);
    if (cleaned.isEmpty) {
      return const ProfileNameEmpty();
    }
    if (cleaned.length > maxLength) {
      return ProfileNameTooLong(cleaned.length);
    }
    return ProfileNameValid(ProfileName._(cleaned));
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is ProfileName && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Result of validating raw profile-name input.
sealed class ProfileNameValidationResult {
  const ProfileNameValidationResult();
}

/// A successfully validated name.
final class ProfileNameValid extends ProfileNameValidationResult {
  const ProfileNameValid(this.name);

  /// The trimmed name.
  final ProfileName name;
}

/// The trimmed input contained no characters.
final class ProfileNameEmpty extends ProfileNameValidationResult {
  const ProfileNameEmpty();
}

/// The trimmed input exceeded [ProfileName.maxLength] UTF-16 code units.
final class ProfileNameTooLong extends ProfileNameValidationResult {
  const ProfileNameTooLong(this.actualLength);

  /// UTF-16 code-unit length of the trimmed input.
  final int actualLength;
}
