/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardInfoDestination.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

/// Where Card Info was opened from; selects its backend title and sentence case.
enum CardInfoDestinationEntryPoint {
  CURRENT_CARD_STUDY,
  CURRENT_CARD_BROWSE,
  PREVIOUS_CARD_STUDY,
}

/// The source Card Info destination, retaining the exact card ID and entry point.
class CardInfoDestination {
  const CardInfoDestination({required this.cardId, required this.entryPoint});

  static const keyTitle = 'title';
  static const keyCardId = 'cardId';

  final int cardId;
  final CardInfoDestinationEntryPoint entryPoint;

  /// Resolves the entry point's title, applies source sentence-case fallback,
  /// then builds the host Bundle and delegates CardInfoFragment Intent creation.
  ///
  /// The host owns translations, sentence-case resources, Android Bundle and
  /// Intent behavior, Context, and the CardInfoFragment token. Callback errors
  /// propagate unchanged and stop later operations.
  TIntent toIntent<TContext, TBundle, TIntent>({
    required TContext context,
    required Object cardInfoFragment,
    required CardInfoDestinationIntentCallbacks<TContext, TBundle, TIntent>
    callbacks,
  }) {
    final title = callbacks.resolveBackendTitle(entryPoint);
    final simplifiedTitle = _withoutUnicodeIsolation(title);
    final sentenceCasedTitle = callbacks.sentenceCaseTitle(
      entryPoint,
      simplifiedTitle,
    );
    final finalTitle = sentenceCasedTitle != simplifiedTitle
        ? sentenceCasedTitle
        : title;

    final arguments = callbacks.createBundle();
    callbacks.putString(arguments, keyTitle, finalTitle);
    callbacks.putLong(arguments, keyCardId, cardId);
    return callbacks.getIntent(context, cardInfoFragment, arguments);
  }
}

/// Host operations needed to adapt `CardInfoDestination.toIntent(context)`.
///
/// Title callbacks receive the source entry point so the host can invoke its
/// corresponding translation and sentence-case resource callbacks.
class CardInfoDestinationIntentCallbacks<TContext, TBundle, TIntent> {
  const CardInfoDestinationIntentCallbacks({
    required this.resolveBackendTitle,
    required this.sentenceCaseTitle,
    required this.createBundle,
    required this.putString,
    required this.putLong,
    required this.getIntent,
  });

  final String Function(CardInfoDestinationEntryPoint entryPoint)
  resolveBackendTitle;
  final String Function(
    CardInfoDestinationEntryPoint entryPoint,
    String simplifiedTitle,
  )
  sentenceCaseTitle;
  final TBundle Function() createBundle;
  final void Function(TBundle bundle, String key, String value) putString;
  final void Function(TBundle bundle, String key, int value) putLong;
  final TIntent Function(
    TContext context,
    Object cardInfoFragment,
    TBundle bundle,
  )
  getIntent;
}

String _withoutUnicodeIsolation(String value) =>
    value.replaceAll('\u2068', '').replaceAll('\u2069', '');
