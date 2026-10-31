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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardViewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// Executes the portable host effects of `CardViewerViewModel.showAnswer()`.
///
/// Host operations remain injected. Calls are awaited and propagated in source
/// order, so a failure leaves completed effects observable and skips later ones.
/// The three current-card reads mirror the source's answer, media-rendering, and
/// body-class accesses. Media escaping, AV replacement, type-answer filtering,
/// JSON encoding, SharedFlow delivery, and collection behavior belong to the
/// host callbacks.
Future<void> runCardViewerShowAnswer<Card>({
  required FutureOr<void> Function(bool value) publishShowingAnswer,
  required FutureOr<void> Function() notifyCardSideChange,
  required FutureOr<Card> Function() awaitCurrentCard,
  required FutureOr<String> Function(Card card) readAnswer,
  required FutureOr<String> Function(String text) escapeMediaFilenames,
  required FutureOr<String> Function(Card card) renderOutput,
  required FutureOr<String> Function(String text, String renderOutput)
  replaceAvRefsWithPlayButtons,
  required FutureOr<String> Function(String text) typeAnswerFilter,
  required FutureOr<String> Function(Card card) bodyClassForCard,
  required FutureOr<String> Function(String answer) encodeAnswer,
  required FutureOr<void> Function(String script) emitEval,
}) async {
  await publishShowingAnswer(true);
  await notifyCardSideChange();

  final card = await awaitCurrentCard();
  final answerData = await readAnswer(card);

  final escapedAnswer = await escapeMediaFilenames(answerData);
  final mediaCard = await awaitCurrentCard();
  final renderedMedia = await renderOutput(mediaCard);
  final answerWithPlayButtons = await replaceAvRefsWithPlayButtons(
    escapedAnswer,
    renderedMedia,
  );
  final answer = await typeAnswerFilter(answerWithPlayButtons);

  final bodyCard = await awaitCurrentCard();
  final bodyClass = await bodyClassForCard(bodyCard);
  final encodedAnswer = await encodeAnswer(answer);
  await emitEval("_showAnswer($encodedAnswer, '$bodyClass');");
}
