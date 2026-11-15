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
 * Source-derived from ViewerRefresh.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Data for a deferred refresh of the CardViewer.
final class ViewerRefresh {
  const ViewerRefresh({
    required this.queues,
    required this.note,
    required this.card,
  });

  final bool queues;
  final bool note;
  final bool card;

  /// Merges the extracted `OpChanges` flags into the pending refresh state.
  ///
  /// The host reads `studyQueues`, `noteText`, and `card` from its generated
  /// `OpChanges` value and retains lifecycle storage and refresh consumption.
  static ViewerRefresh? updateState({
    required ViewerRefresh? currentState,
    required bool studyQueues,
    required bool noteText,
    required bool card,
  }) {
    if (!studyQueues && !noteText && !card) return currentState;
    return ViewerRefresh(
      queues: studyQueues || currentState?.queues == true,
      note: noteText || currentState?.note == true,
      card: card || currentState?.card == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewerRefresh &&
          other.queues == queues &&
          other.note == note &&
          other.card == card;

  @override
  int get hashCode => Object.hash(queues, note, card);

  @override
  String toString() => 'ViewerRefresh(queues=$queues, note=$note, card=$card)';
}
