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
 * Behavioral reference: ReviewerViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The host action selected for AnkiDroid's Reviewer state-mutation hook.
sealed class ReviewerStateMutationHookDecision {
  const ReviewerStateMutationHookDecision();
}

/// No host action is needed because the mutation signal is already complete.
final class ReviewerStateMutationHookNoAction
    extends ReviewerStateMutationHookDecision {
  const ReviewerStateMutationHookNoAction();
}

/// The host should complete its pending mutation signal.
final class ReviewerStateMutationHookCompleteSignal
    extends ReviewerStateMutationHookDecision {
  const ReviewerStateMutationHookCompleteSignal();
}

/// The host should emit this script and wait for its later mutation callback.
final class ReviewerStateMutationHookEmitScript
    extends ReviewerStateMutationHookDecision {
  const ReviewerStateMutationHookEmitScript(this.script);

  final String script;
}

/// Projects the host-supplied mutation JavaScript and signal state to an action.
///
/// The host still awaits the JavaScript, emits the returned script through its
/// flow, and completes the signal from the later `statesMutated` callback. A
/// failed host emission propagates and does not complete the signal locally.
ReviewerStateMutationHookDecision reviewerStateMutationHookDecision({
  required String stateMutationJs,
  required String stateMutationKey,
  required bool mutationSignalCompleted,
}) {
  if (stateMutationJs.isEmpty) {
    return mutationSignalCompleted
        ? const ReviewerStateMutationHookNoAction()
        : const ReviewerStateMutationHookCompleteSignal();
  }

  return ReviewerStateMutationHookEmitScript(
    "\n            anki.mutateNextCardStates('$stateMutationKey', async (states, customData, ctx) => { $stateMutationJs })\n"
    '                .finally(() => fetch("ankidroid/statesMutated", { method: "POST" }));\n'
    '            ',
  );
}
