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

/// Host callbacks for reading the fields of AnkiDroid's backend card.
///
/// A host adapts its backend card or protobuf to these callbacks. This class
/// contains no backend model and reads each field only when the loader reaches
/// it. Optional values have separate presence and value callbacks to preserve
/// the source's short-circuit behavior.
final class CardBackendLoadSource {
  const CardBackendLoadSource({
    required this.id,
    required this.noteId,
    required this.deckId,
    required this.templateIdx,
    required this.mtimeSecs,
    required this.usn,
    required this.cardTypeCode,
    required this.queueCode,
    required this.due,
    required this.interval,
    required this.easeFactor,
    required this.reps,
    required this.lapses,
    required this.remainingSteps,
    required this.originalDue,
    required this.originalDeckId,
    required this.flags,
    required this.hasOriginalPosition,
    required this.originalPosition,
    required this.customData,
    required this.hasMemoryState,
    required this.memoryState,
    required this.hasDesiredRetention,
    required this.desiredRetention,
    required this.hasDecay,
    required this.decay,
    required this.hasLastReviewTimeSecs,
    required this.lastReviewTimeSecs,
  });

  final int Function() id;
  final int Function() noteId;
  final int Function() deckId;
  final int Function() templateIdx;
  final int Function() mtimeSecs;
  final int Function() usn;
  final int Function() cardTypeCode;
  final int Function() queueCode;
  final int Function() due;
  final int Function() interval;
  final int Function() easeFactor;
  final int Function() reps;
  final int Function() lapses;
  final int Function() remainingSteps;
  final int Function() originalDue;
  final int Function() originalDeckId;
  final int Function() flags;
  final bool Function() hasOriginalPosition;
  final int Function() originalPosition;
  final String Function() customData;
  final bool Function() hasMemoryState;
  final Object? Function() memoryState;
  final bool Function() hasDesiredRetention;
  final double Function() desiredRetention;
  final bool Function() hasDecay;
  final double Function() decay;
  final bool Function() hasLastReviewTimeSecs;
  final int Function() lastReviewTimeSecs;
}

/// Host callbacks for clearing caches and assigning loaded card fields.
///
/// Setter callbacks are invoked in source order. If one throws, prior side
/// effects remain and later callbacks are not invoked, matching the source's
/// sequential property assignments.
final class CardBackendLoadTarget<TType, TQueue> {
  const CardBackendLoadTarget({
    required this.clearRenderOutput,
    required this.clearCachedNote,
    required this.setId,
    required this.setNoteId,
    required this.setDeckId,
    required this.setTemplateIdx,
    required this.setMtimeSecs,
    required this.setUsn,
    required this.setType,
    required this.setQueue,
    required this.setDue,
    required this.setInterval,
    required this.setEaseFactor,
    required this.setReps,
    required this.setLapses,
    required this.setRemainingSteps,
    required this.setOriginalDue,
    required this.setOriginalDeckId,
    required this.setFlags,
    required this.setOriginalPosition,
    required this.setCustomData,
    required this.setMemoryState,
    required this.setDesiredRetention,
    required this.setDecay,
    required this.setLastReviewTimeSecs,
  });

  final void Function() clearRenderOutput;
  final void Function() clearCachedNote;
  final void Function(int) setId;
  final void Function(int) setNoteId;
  final void Function(int) setDeckId;
  final void Function(int) setTemplateIdx;
  final void Function(int) setMtimeSecs;
  final void Function(int) setUsn;
  final void Function(TType) setType;
  final void Function(TQueue) setQueue;
  final void Function(int) setDue;
  final void Function(int) setInterval;
  final void Function(int) setEaseFactor;
  final void Function(int) setReps;
  final void Function(int) setLapses;
  final void Function(int) setRemainingSteps;
  final void Function(int) setOriginalDue;
  final void Function(int) setOriginalDeckId;
  final void Function(int) setFlags;
  final void Function(int?) setOriginalPosition;
  final void Function(String) setCustomData;
  final void Function(Object?) setMemoryState;
  final void Function(double?) setDesiredRetention;
  final void Function(double?) setDecay;
  final void Function(int?) setLastReviewTimeSecs;
}

/// Loads backend card fields into a host card through ordered callbacks.
///
/// The host supplies backend field access, card type and queue decoding, and
/// target mutation. It retains Card, backend card/protobuf, constructors,
/// Collection access, and storage. Callback failures propagate unchanged; no
/// rollback is attempted.
void loadCardFromBackend<TType, TQueue>({
  required CardBackendLoadSource source,
  required CardBackendLoadTarget<TType, TQueue> target,
  required TType Function(int code) decodeCardType,
  required TQueue Function(int code) decodeQueue,
}) {
  target.clearRenderOutput();
  target.clearCachedNote();
  target.setId(source.id());
  target.setNoteId(source.noteId());
  target.setDeckId(source.deckId());
  target.setTemplateIdx(source.templateIdx());
  target.setMtimeSecs(source.mtimeSecs());
  target.setUsn(source.usn());
  target.setType(decodeCardType(source.cardTypeCode()));
  target.setQueue(decodeQueue(source.queueCode()));
  target.setDue(source.due());
  target.setInterval(source.interval());
  target.setEaseFactor(source.easeFactor());
  target.setReps(source.reps());
  target.setLapses(source.lapses());
  target.setRemainingSteps(source.remainingSteps());
  target.setOriginalDue(source.originalDue());
  target.setOriginalDeckId(source.originalDeckId());
  target.setFlags(source.flags());
  target.setOriginalPosition(
    source.hasOriginalPosition() ? source.originalPosition() : null,
  );
  target.setCustomData(source.customData());
  target.setMemoryState(source.hasMemoryState() ? source.memoryState() : null);
  target.setDesiredRetention(
    source.hasDesiredRetention() ? source.desiredRetention() : null,
  );
  target.setDecay(source.hasDecay() ? source.decay() : null);
  target.setLastReviewTimeSecs(
    source.hasLastReviewTimeSecs() ? source.lastReviewTimeSecs() : null,
  );
}
