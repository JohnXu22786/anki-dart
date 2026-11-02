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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2026 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SwitchProfilesViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Portable dialog state from AnkiDroid's SwitchProfilesViewModel.
///
/// Profile loading, validation, logging, StateFlow, lifecycle, and Android UI
/// remain host-side. Profile creation is still a source TODO in AnkiDroid 2.25.3.
final class SwitchProfilesDialogState {
  bool _isAddProfileDialogVisible = false;

  /// The pinned source initializes this list empty and does not populate it.
  List<Object> get profiles => const [];

  bool get isAddProfileDialogVisible => _isAddProfileDialogVisible;

  void showAddProfileDialog() {
    _isAddProfileDialogVisible = true;
  }

  void dismissAddProfileDialog() {
    _isAddProfileDialogVisible = false;
  }

  /// Hides the dialog; profile creation remains TODO in the pinned source.
  void addProfile(String validName) {
    _isAddProfileDialogVisible = false;
  }
}
