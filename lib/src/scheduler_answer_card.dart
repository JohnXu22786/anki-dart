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
 * Source-derived from Scheduler.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Runs the host's answer builder, then records one successful answer.
///
/// The host retains the card, scheduling states, rating, scheduler, and answer
/// construction. Callback failures propagate in source order. The counter uses
/// Kotlin `Int` increment semantics, including signed 32-bit wraparound.
AnswerT schedulerAnswerCard<CardT, StatesT, RatingT, AnswerT>({
  required CardT card,
  required StatesT states,
  required RatingT rating,
  required AnswerT Function(CardT card, StatesT states, RatingT rating)
  buildAnswer,
  required int Function() getNumberOfAnswersRecorded,
  required void Function(int value) setNumberOfAnswersRecorded,
}) {
  final answer = buildAnswer(card, states, rating);
  final count = getNumberOfAnswersRecorded();
  final incrementedCount = count == 0x7fffffff ? -0x80000000 : count + 1;
  setNumberOfAnswersRecorded(incrementedCount);
  return answer;
}
