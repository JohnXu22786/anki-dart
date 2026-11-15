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
 * Source-derived from CsvImporterDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Arguments for opening the CSV importer for [filePath].
class CsvImporterDestination {
  const CsvImporterDestination(this.filePath);

  /// The source path, retained exactly as supplied.
  final String filePath;

  /// Delegates to the host CSV importer intent builder and returns its Intent.
  ///
  /// The host supplies Android Context and Intent behavior. The path is passed
  /// unchanged, and callback failures propagate unchanged.
  TIntent toIntent<TContext, TIntent>(
    TContext context,
    TIntent Function(TContext context, String filePath) getIntent,
  ) => getIntent(context, filePath);
}
