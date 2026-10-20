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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: PreviewerViewModel.kt and Flag.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Previewer flag values and persisted codes from AnkiDroid's `Flag` enum.
///
/// These are deliberately separate from the browser search backend's flag
/// values, whose semantic mapping belongs to a different adapter boundary.
enum PreviewerFlag {
  none(0),
  red(1),
  orange(2),
  green(3),
  blue(4),
  pink(5),
  turquoise(6),
  purple(7);

  const PreviewerFlag(this.code);

  final int code;
}

/// One ordered effect in the Previewer flag update plan.
sealed class PreviewerFlagEffect {
  const PreviewerFlagEffect();
}

/// Writes [flag] to the single supplied current card.
final class PreviewerSetUserFlagForCardsEffect extends PreviewerFlagEffect {
  PreviewerSetUserFlagForCardsEffect({
    required int cardId,
    required this.flag,
  }) : cardIds = List<int>.unmodifiable([cardId]);

  final List<int> cardIds;
  final PreviewerFlag flag;
}

/// Publishes [flag] only if the immediately preceding collection write succeeds.
///
/// The host executes collection mutation and publication. A failed write must
/// not execute this effect, matching `setFlag()`'s sequential source code.
final class PreviewerPublishFlagOnSuccessEffect extends PreviewerFlagEffect {
  const PreviewerPublishFlagOnSuccessEffect(this.flag);

  final PreviewerFlag flag;
}

/// Projects `PreviewerViewModel.setFlag()` into its ordered host effects.
///
/// The host supplies the current card ID and performs the undoable collection
/// operation. It must apply the publish effect only after that operation
/// succeeds. Current-card lookup, asynchronous failure handling, and StateFlow
/// publication remain outside this model.
List<PreviewerFlagEffect> previewerSetFlagEffects({
  required int cardId,
  required PreviewerFlag flag,
}) =>
    List.unmodifiable([
      PreviewerSetUserFlagForCardsEffect(cardId: cardId, flag: flag),
      PreviewerPublishFlagOnSuccessEffect(flag),
    ]);

/// Projects `PreviewerViewModel.toggleFlag()` and its delegated set operation.
///
/// When the current value equals the requested value, the target is NONE;
/// otherwise the target is [requestedFlag]. In both cases the source delegates
/// to `setFlag()`, so this returns its write-then-publish plan.
List<PreviewerFlagEffect> previewerToggleFlagEffects({
  required int cardId,
  required PreviewerFlag currentFlag,
  required PreviewerFlag requestedFlag,
}) =>
    previewerSetFlagEffects(
      cardId: cardId,
      flag: currentFlag == requestedFlag ? PreviewerFlag.none : requestedFlag,
    );
