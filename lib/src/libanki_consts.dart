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
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Consts.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// A card type identified by Anki's integer code.
sealed class LibAnkiCardType {
  const LibAnkiCardType._(this.code);

  /// The exact source integer code.
  final int code;

  /// The canonical New card type.
  static const LibAnkiCardType newCard = _LibAnkiCardTypeKnown(0);

  /// The canonical learning card type.
  static const LibAnkiCardType learning = _LibAnkiCardTypeKnown(1);

  /// The canonical review card type.
  static const LibAnkiCardType review = _LibAnkiCardTypeKnown(2);

  /// The canonical relearning card type.
  static const LibAnkiCardType relearning = _LibAnkiCardTypeKnown(3);

  /// Returns the canonical known variant or a new [LibAnkiCardTypeUnknown].
  static LibAnkiCardType fromCode(int code) => switch (code) {
    0 => newCard,
    1 => learning,
    2 => review,
    3 => relearning,
    _ => LibAnkiCardTypeUnknown(code),
  };
}

final class _LibAnkiCardTypeKnown extends LibAnkiCardType {
  const _LibAnkiCardTypeKnown(int code) : super._(code);

  @override
  bool operator ==(Object other) =>
      other is _LibAnkiCardTypeKnown && other.code == code;

  @override
  int get hashCode => code;
}

/// A card type code not represented by a known variant.
///
/// Instances use identity equality and hashing, matching Kotlin's ordinary
/// class.
final class LibAnkiCardTypeUnknown extends LibAnkiCardType {
  /// Creates an unknown card type while preserving [code].
  LibAnkiCardTypeUnknown(int code) : super._(code);
}

/// A queue state identified by Anki's integer code.
sealed class LibAnkiQueueType {
  const LibAnkiQueueType._(this.code);

  /// The exact source integer code.
  final int code;

  static const LibAnkiQueueType manuallyBuried = _LibAnkiQueueTypeKnown(-3);
  static const LibAnkiQueueType siblingBuried = _LibAnkiQueueTypeKnown(-2);
  static const LibAnkiQueueType suspended = _LibAnkiQueueTypeKnown(-1);
  static const LibAnkiQueueType newCard = _LibAnkiQueueTypeKnown(0);
  static const LibAnkiQueueType learning = _LibAnkiQueueTypeKnown(1);
  static const LibAnkiQueueType review = _LibAnkiQueueTypeKnown(2);
  static const LibAnkiQueueType dayLearnRelearn = _LibAnkiQueueTypeKnown(3);
  static const LibAnkiQueueType preview = _LibAnkiQueueTypeKnown(4);

  /// Returns the canonical known variant or a new [LibAnkiQueueTypeUnknown].
  static LibAnkiQueueType fromCode(int code) => switch (code) {
    -3 => manuallyBuried,
    -2 => siblingBuried,
    -1 => suspended,
    0 => newCard,
    1 => learning,
    2 => review,
    3 => dayLearnRelearn,
    _ => LibAnkiQueueTypeUnknown(code),
  };

  /// Whether this queue state is buried or suspended.
  bool buriedOrSuspended() {
    if (this is LibAnkiQueueTypeUnknown) return code < 0;
    return this == manuallyBuried || this == siblingBuried || this == suspended;
  }
}

final class _LibAnkiQueueTypeKnown extends LibAnkiQueueType {
  const _LibAnkiQueueTypeKnown(int code) : super._(code);

  @override
  bool operator ==(Object other) =>
      other is _LibAnkiQueueTypeKnown && other.code == code;

  @override
  int get hashCode => code;
}

/// A queue code not represented by a known variant.
///
/// Instances use identity equality and hashing, matching Kotlin's ordinary
/// class.
final class LibAnkiQueueTypeUnknown extends LibAnkiQueueType {
  /// Creates an unknown queue type while preserving [code].
  LibAnkiQueueTypeUnknown(int code) : super._(code);
}

/// A note type kind identified by Anki's integer code.
sealed class LibAnkiNoteTypeKind {
  const LibAnkiNoteTypeKind._(this.code);

  /// The exact source integer code.
  final int code;

  /// The canonical standard note type kind.
  static const LibAnkiNoteTypeKind std = _LibAnkiNoteTypeKindKnown(0);

  /// The canonical cloze note type kind.
  static const LibAnkiNoteTypeKind cloze = _LibAnkiNoteTypeKindKnown(1);

  /// Returns the canonical known variant or a new [LibAnkiNoteTypeKindUnknown].
  static LibAnkiNoteTypeKind fromCode(int code) => switch (code) {
    0 => std,
    1 => cloze,
    _ => LibAnkiNoteTypeKindUnknown(code),
  };
}

final class _LibAnkiNoteTypeKindKnown extends LibAnkiNoteTypeKind {
  const _LibAnkiNoteTypeKindKnown(int code) : super._(code);

  @override
  bool operator ==(Object other) =>
      other is _LibAnkiNoteTypeKindKnown && other.code == code;

  @override
  int get hashCode => code;
}

/// A note type kind code not represented by a known variant.
///
/// Instances use identity equality and hashing, matching Kotlin's ordinary
/// class.
final class LibAnkiNoteTypeKindUnknown extends LibAnkiNoteTypeKind {
  /// Creates an unknown note type kind while preserving [code].
  LibAnkiNoteTypeKindUnknown(int code) : super._(code);
}

/// Public constants ported from AnkiDroid's `Consts` object.
///
/// Kotlin's `@IntDef` and `@Retention(SOURCE)` on `DynPriority` are
/// compile-time metadata and have no Dart runtime behavior.
abstract final class LibAnkiConsts {
  static const int dynOldest = 0;
  static const int dynRandom = 1;
  static const int dynSmallInt = 2;
  static const int dynBigInt = 3;
  static const int dynLapses = 4;
  static const int dynAdded = 5;
  static const int dynDue = 6;
  static const int dynRevAdded = 7;
  static const int dynDuePriority = 8;
  static const int dynMaxSize = 99999;

  static const int startingFactor = 2500;
  static const int backendSchemaVersion = 18;
  static const int syncVer = 10;
  static const int leechSuspend = 0;
  static const int defaultDeckId = 1;
  static const String fieldSeparator = '\u001f';

  /// Toast duration in milliseconds.
  static const int shortToastDuration = 2000;
}
