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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2025 Eric Li <ericli3690@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ScheduleRemindersDestination.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'review_reminder_form_state.dart';

/// Opens review-reminder scheduling for the supplied deck.
class ScheduleRemindersDestination {
  const ScheduleRemindersDestination(this.deckId);

  /// The supplied deck ID, retained unchanged for host routing.
  final int deckId;

  /// Delegates reminder Intent construction to the host with a deck-specific
  /// scope created for this projection call.
  ///
  /// The host owns Context and Android Intent/Parcelable behavior. The deck ID
  /// and callback failures pass through unchanged.
  TIntent toIntent<TContext, TIntent>(
    TContext context,
    TIntent Function(TContext context, ReviewReminderScope scope) getIntent,
  ) => getIntent(context, DeckSpecificReminderScope(deckId));
}
