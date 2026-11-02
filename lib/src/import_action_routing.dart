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
 * SPDX-FileCopyrightText: 2026 Georgios Michelakis <michelakisgio@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ImportViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// The import flow selected by AnkiDroid's ImportViewModel.
enum ImportAction { add, replace }

/// A host-facing import action and its original path.
///
/// The host owns flow delivery, coroutine scheduling, and import execution.
final class ImportActionRequest {
  const ImportActionRequest({required this.action, required this.path});

  final ImportAction action;
  final String path;
}

/// Projects `triggerImportAdd(path)` without changing [path].
ImportActionRequest projectImportAdd({required String path}) =>
    ImportActionRequest(action: ImportAction.add, path: path);

/// Projects `triggerImportReplace(path)` without changing [path].
ImportActionRequest projectImportReplace({required String path}) =>
    ImportActionRequest(action: ImportAction.replace, path: path);
