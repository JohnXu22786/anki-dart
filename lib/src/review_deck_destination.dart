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
 * Source-derived from ReviewDeckDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Host operations used by the source `ReviewDeckDestination.toIntent()`.
///
/// The host supplies Android Context and Intent behavior, including the
/// `IntentHandler` component, action token, and extra key.
class ReviewDeckDestinationIntentCallbacks<
  TContext,
  TIntent,
  TTarget,
  TAction
> {
  const ReviewDeckDestinationIntentCallbacks({
    required this.getReviewerIntent,
    required this.createIntent,
    required this.setAction,
    required this.putLongExtra,
  });

  final TIntent Function(TContext context) getReviewerIntent;
  final TIntent Function(TContext context, TTarget target) createIntent;
  final void Function(TIntent intent, TAction action) setAction;
  final void Function(TIntent intent, String key, int value) putLongExtra;
}

/// The two host-facing review deck launch choices from AnkiDroid.
sealed class ReviewDeckDestination {
  const ReviewDeckDestination();

  /// The source singleton that delegates to the host Reviewer's Intent.
  static const ReviewDeckDestination currentDeck = ReviewDeckCurrentDeck._();

  /// Opens the host Intent handler with the exact supplied deck ID.
  static ReviewDeckExternalLaunch externalLaunch(int deckId) =>
      ReviewDeckExternalLaunch(deckId);

  /// Adapts `ReviewDeckDestination.toIntent(context)`.
  ///
  /// [currentDeck] calls [callbacks.getReviewerIntent] once and returns its
  /// exact result. An external launch creates one host Intent, sets
  /// [viewAction], writes [deckIdExtraKey] with its exact deck ID, then returns
  /// that same Intent. Host callback failures propagate unchanged and stop
  /// later operations. Android screen selection, preferences, Activity choice,
  /// and Intent semantics remain host-side.
  TIntent toIntent<TContext, TIntent, TTarget, TAction>({
    required TContext context,
    required TTarget target,
    required TAction viewAction,
    required String deckIdExtraKey,
    required ReviewDeckDestinationIntentCallbacks<
      TContext,
      TIntent,
      TTarget,
      TAction
    >
    callbacks,
  }) {
    switch (this) {
      case ReviewDeckCurrentDeck():
        return callbacks.getReviewerIntent(context);
      case ReviewDeckExternalLaunch(:final deckId):
        final intent = callbacks.createIntent(context, target);
        callbacks.setAction(intent, viewAction);
        callbacks.putLongExtra(intent, deckIdExtraKey, deckId);
        return intent;
    }
  }
}

/// Source `CurrentDeck` singleton; the Reviewer chooses its screen and
/// settings.
final class ReviewDeckCurrentDeck extends ReviewDeckDestination {
  const ReviewDeckCurrentDeck._();
}

/// Source `ExternalLaunch(deckId)` variant, preserving the exact DeckId value.
final class ReviewDeckExternalLaunch extends ReviewDeckDestination {
  const ReviewDeckExternalLaunch(this.deckId);

  final int deckId;

  @override
  bool operator ==(Object other) =>
      other is ReviewDeckExternalLaunch && other.deckId == deckId;

  @override
  int get hashCode => Object.hash(ReviewDeckExternalLaunch, deckId);
}
