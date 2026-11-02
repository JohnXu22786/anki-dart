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
 * Source-derived from Fragment.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Reads [fragment]'s PackageManager through its required Context.
///
/// [requireContext] runs once before [packageManager], and the exact Context
/// token it returns is passed to that callback. Its result is returned
/// unchanged. Android Fragment, Context, and PackageManager implementations
/// remain host-side; callback failures propagate unchanged.
TPackageManager fragmentPackageManager<TFragment, TContext, TPackageManager>({
  required TFragment fragment,
  required TContext Function(TFragment fragment) requireContext,
  required TPackageManager Function(TContext context) packageManager,
}) {
  final context = requireContext(fragment);
  return packageManager(context);
}
