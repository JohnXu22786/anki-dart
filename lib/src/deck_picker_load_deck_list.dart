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
 * Source-derived from DeckPickerViewModel.kt:374–387 in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Loads the Deck Picker list in the source callback and async order.
///
/// The host reads collection state and Android's build fingerprint, starts the
/// background backup without waiting for it, and supplies the reload operation
/// with the host's Job-join semantics. This method does not own Android,
/// coroutine, IO, or lifecycle work.
Future<void> loadDeckList({
  required bool Function() isCollectionOpen,
  required String Function() fingerprint,
  required void Function() launchBackupInBackground,
  required void Function() logUpdateDeckList,
  required Future<void> Function() reloadDeckCounts,
}) async {
  // WARN: On a regular sync, this blocks until the sync completes.
  // On a full sync, the collection is closed.
  if (!isCollectionOpen()) return;

  if (fingerprint() != 'robolectric') {
    // The host launcher starts this asynchronously; it is intentionally not
    // awaited here.
    launchBackupInBackground();
  }

  logUpdateDeckList();
  await reloadDeckCounts();
}
