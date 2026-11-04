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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// A host-independent mapping of source card fields to backend card fields.
///
/// This projection does not build a generated backend card. That conversion and
/// its protobuf types remain host-owned. Optional fields stay null when the
/// source card has no value for them; hosts should omit those protobuf fields.
final class BackendCardProjection {
  /// Maps the source `Card` fields used by `toBackendCard()`.
  const BackendCardProjection.fromCard({
    required int id,
    required int nid,
    required int did,
    required int ord,
    required int typeCode,
    required int queueCode,
    required int due,
    required int ivl,
    required int factor,
    required int reps,
    required int lapses,
    required int left,
    required int oDue,
    required int oDid,
    required int flags,
    required String customData,
    int? originalPosition,
    Object? memoryState,
    double? desiredRetention,
    double? decay,
    int? lastReviewTimeSecs,
  }) : id = id,
       noteId = nid,
       deckId = did,
       templateIdx = ord,
       ctype = typeCode,
       queue = queueCode,
       due = due,
       interval = ivl,
       easeFactor = factor,
       reps = reps,
       lapses = lapses,
       remainingSteps = left,
       originalDue = oDue,
       originalDeckId = oDid,
       flags = flags,
       customData = customData,
       originalPosition = originalPosition,
       memoryState = memoryState,
       desiredRetention = desiredRetention,
       decay = decay,
       lastReviewTimeSecs = lastReviewTimeSecs;

  /// The source card `id`.
  final int id;

  /// The source card `nid`, mapped to backend `noteId`.
  final int noteId;

  /// The source card `did`, mapped to backend `deckId`.
  final int deckId;

  /// The source card `ord`, mapped to backend `templateIdx`.
  final int templateIdx;

  /// The source card type code, mapped to backend `ctype`.
  final int ctype;

  /// The source queue code.
  final int queue;

  /// The source card `due`.
  final int due;

  /// The source card `ivl`, mapped to backend `interval`.
  final int interval;

  /// The source card `factor`, mapped to backend `easeFactor`.
  final int easeFactor;

  /// The source card `reps`.
  final int reps;

  /// The source card `lapses`.
  final int lapses;

  /// The source card `left`, mapped to backend `remainingSteps`.
  final int remainingSteps;

  /// The source card `oDue`, mapped to backend `originalDue`.
  final int originalDue;

  /// The source card `oDid`, mapped to backend `originalDeckId`.
  final int originalDeckId;

  /// The source card `flags`.
  final int flags;

  /// The source card `customData`.
  final String customData;

  /// The nullable source card `originalPosition`.
  final int? originalPosition;

  /// The opaque nullable source card memory state, preserved by identity.
  final Object? memoryState;

  /// The nullable source card `desiredRetention`.
  final double? desiredRetention;

  /// The nullable source card `decay`.
  final double? decay;

  /// The nullable source card `lastReviewTimeSecs`.
  final int? lastReviewTimeSecs;
}
