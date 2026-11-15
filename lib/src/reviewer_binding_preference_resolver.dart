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
 * Behavioral reference: ReviewerBinding.kt, MappableBinding.kt, and
 * ViewerCommand.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';
import 'reviewer_binding_codec.dart';
import 'reviewer_command_defaults.dart';

/// Resolves one command's bindings from an optional host-read preference value.
///
/// An absent value selects `ViewerCommand.defaultValue`. Any present string
/// replaces that list and is decoded as-is, including empty or unsupported
/// versions. Preference lookup and persistence remain with the host.
abstract final class ReviewerBindingPreferenceResolver {
  /// Resolves the source preference/default choice for [command].
  ///
  /// [androidKeyCodes] is used only when [preferenceValue] is null. The host
  /// supplies Android key-code numbers by their source symbolic names; if a
  /// required name is missing on the default path, the default resolver throws.
  static List<ReviewerBindingValue> resolve(
    ViewerCommand command, {
    String? preferenceValue,
    Map<String, int>? androidKeyCodes,
  }) {
    if (preferenceValue != null) {
      return const ReviewerBindingCodec().decode(preferenceValue);
    }

    return ReviewerDefaultBindings.resolve(
      command,
      androidKeyCodes: androidKeyCodes ?? const {},
    );
  }
}
