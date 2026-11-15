/*
 * Copyright (c) 2024 Ashish Yadav <mailtoashish693@gmail.com>
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
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: String.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md. Unicode 18.0.0 NFD data is provided by the pinned
 * unorm_dart dependency; see NOTICE.md.
 */

import 'package:unorm_dart/unorm_dart.dart' as unorm;

final RegExp _combiningDiacriticalMarks = RegExp(r'[\u0300-\u036F]+');

/// Decomposes [value] canonically, then removes U+0300..U+036F.
///
/// AnkiDroid's JVM `Normalizer` uses the Unicode data of its running runtime.
/// This Dart port uses Unicode 18.0.0 data from unorm_dart 0.3.3, so results for
/// characters added outside that fixed version can differ between runtimes.
/// Combining marks outside U+0300..U+036F are preserved.
String normalizeForSearch(String value) =>
    unorm.nfd(value).replaceAll(_combiningDiacriticalMarks, '');
