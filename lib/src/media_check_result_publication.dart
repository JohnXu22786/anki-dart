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
 * Behavioral reference: MediaCheckViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'media_check_unused_deletion.dart';

/// Source-ordered check and publication behavior for Media Check results.
class MediaCheckResultPublicationPlan<T> {
  const MediaCheckResultPublicationPlan();

  /// Runs the host check, then publishes only its successfully returned result.
  ///
  /// The host runs this while [progress] is active. Check execution and result
  /// storage remain host responsibilities. If [checkMedia] throws, its error
  /// propagates and [publishResult] is not called.
  T checkAndPublish({
    required T Function() checkMedia,
    required void Function(T) publishResult,
  }) {
    final result = checkMedia();
    publishResult(result);
    return result;
  }

  /// Progress message selected by AnkiDroid while checking media.
  MediaCheckProgress get progress => MediaCheckProgress.checkingMedia;
}

/// Plans Media Check result publication without depending on its backend type.
MediaCheckResultPublicationPlan<T> planMediaCheckResultPublication<T>() =>
    MediaCheckResultPublicationPlan<T>();
