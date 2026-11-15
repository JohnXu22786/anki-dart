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
 * Behavioral reference: EmptyCardsViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'dart:async';

/// State values exposed by AnkiDroid's Empty Cards search.
sealed class EmptyCardsUiState {
  const EmptyCardsUiState();
}

/// Initial state while the host performs the search.
final class SearchingForEmptyCards extends EmptyCardsUiState {
  const SearchingForEmptyCards._();

  static const instance = SearchingForEmptyCards._();
}

/// Successful search state carrying the exact host report.
final class EmptyCardsSearchResult<T> extends EmptyCardsUiState {
  const EmptyCardsSearchResult(this.emptyCardsReport);

  final T emptyCardsReport;
}

/// Failure state carrying the exact object thrown by the host query.
final class EmptyCardsSearchFailure extends EmptyCardsUiState {
  const EmptyCardsSearchFailure(this.throwable);

  final Object throwable;
}

/// Source-ordered query and state-publication behavior for Empty Cards search.
final class EmptyCardsSearchPlan<T> {
  const EmptyCardsSearchPlan();

  /// Initial state before the host starts its search.
  EmptyCardsUiState get initialState => SearchingForEmptyCards.instance;

  /// Runs the host query and publishes its source-matching result state.
  ///
  /// Only [getEmptyCards] is caught. Dart has no Kotlin
  /// `CancellationException` type, so [isCancellation] is supplied by the
  /// host. It must recognize host cancellation objects; matching objects are
  /// rethrown unchanged. Other thrown objects are retained unchanged in a
  /// failure state. State publication is outside the query catch and its
  /// errors propagate to the caller.
  Future<void> searchForEmptyCards({
    required FutureOr<T> Function() getEmptyCards,
    required bool Function(Object throwable) isCancellation,
    required FutureOr<void> Function(EmptyCardsUiState state) emit,
  }) async {
    late final T emptyCardsReport;
    try {
      emptyCardsReport = await getEmptyCards();
    } catch (throwable) {
      if (isCancellation(throwable)) rethrow;
      await emit(EmptyCardsSearchFailure(throwable));
      return;
    }

    await emit(EmptyCardsSearchResult(emptyCardsReport));
  }
}

/// Creates a plan for source-ordered Empty Cards query state publication.
EmptyCardsSearchPlan<T> planEmptyCardsSearch<T>() => EmptyCardsSearchPlan<T>();
