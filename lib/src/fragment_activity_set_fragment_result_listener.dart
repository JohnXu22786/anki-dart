/*
 * Copyright © 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from FragmentResult.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Registers [listener] for [requestKey] with this activity as its lifecycle
/// owner.
///
/// The host resolves the activity's current support FragmentManager once and
/// registers the exact request key, activity, and callback in source order.
/// Android FragmentActivity, FragmentManager, Bundle, and lifecycle behavior
/// remain host-side. Callback failures propagate unchanged and stop later work.
void fragmentActivitySetFragmentResultListener<
  TFragmentActivity,
  TFragmentManager,
  TListener
>({
  required TFragmentActivity fragmentActivity,
  required TFragmentManager Function(TFragmentActivity fragmentActivity)
  supportFragmentManager,
  required String requestKey,
  required TListener listener,
  required void Function(
    TFragmentManager manager,
    String requestKey,
    TFragmentActivity lifecycleOwner,
    TListener listener,
  )
  registerFragmentResultListener,
}) {
  final manager = supportFragmentManager(fragmentActivity);
  registerFragmentResultListener(
    manager,
    requestKey,
    fragmentActivity,
    listener,
  );
}
