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
 * Behavioral reference: SortType.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The source collection sort mode selected for Card Browser queries.
enum BrowserSortOrder { noOrdering, useCollectionOrdering }

/// The two collection-config keys resolved by the host for the active mode.
///
/// AnkiDroid resolves these through `BrowserConfig` after reading Cards/Notes
/// mode. The host supplies them here so this model does not copy that config.
final class BrowserSortConfigKeys {
  const BrowserSortConfigKeys({
    required this.columnKey,
    required this.reverseKey,
  });

  final String columnKey;
  final String reverseKey;
}

/// A source-equivalent Card Browser sort choice.
sealed class BrowserSortType {
  const BrowserSortType();
}

/// No ordering, corresponding to AnkiDroid's `SortType.NoOrdering`.
final class BrowserSortNoOrdering extends BrowserSortType {
  const BrowserSortNoOrdering();

  @override
  bool operator ==(Object other) => other is BrowserSortNoOrdering;

  @override
  int get hashCode => 0;
}

/// Uses the collection-config browser column ordering.
final class BrowserSortCollectionOrdering extends BrowserSortType {
  const BrowserSortCollectionOrdering({
    required this.key,
    required this.reverse,
  });

  final String key;
  final bool reverse;

  @override
  bool operator ==(Object other) =>
      other is BrowserSortCollectionOrdering &&
      other.key == key &&
      other.reverse == reverse;

  @override
  int get hashCode => Object.hash(key, reverse);
}

/// Resolves the active mode's stored sort choice without reading storage.
///
/// The source uses one shared no-sorting preference. If sorting is enabled, a
/// missing column key defaults to `noteFld`; the backend column list decides
/// whether that key (or a stored key) is recognized. Missing reverse config is
/// `false`. A corrupt key produces no ordering.
BrowserSortType resolveBrowserSortType({
  required bool noSorting,
  required Map<String, Object?> config,
  required BrowserSortConfigKeys configKeys,
  required Iterable<String> availableColumnKeys,
}) {
  if (noSorting) return const BrowserSortNoOrdering();

  final storedKey = config[configKeys.columnKey];
  final key = storedKey is String ? storedKey : 'noteFld';
  if (!availableColumnKeys.contains(key)) {
    return const BrowserSortNoOrdering();
  }

  final storedReverse = config[configKeys.reverseKey];
  final reverse = storedReverse is bool ? storedReverse : false;
  return BrowserSortCollectionOrdering(key: key, reverse: reverse);
}

/// Maps AnkiDroid's shared no-sorting preference to the collection query mode.
BrowserSortOrder browserSortOrder({required bool noSorting}) => noSorting
    ? BrowserSortOrder.noOrdering
    : BrowserSortOrder.useCollectionOrdering;

/// One ordered write to the active Cards/Notes collection sort config.
final class BrowserSortConfigWrite {
  const BrowserSortConfigWrite({required this.key, required this.value});

  final String key;
  final Object value;

  @override
  bool operator ==(Object other) =>
      other is BrowserSortConfigWrite &&
      other.key == key &&
      other.value == value;

  @override
  int get hashCode => Object.hash(key, value);
}

/// Adapter instructions for persisting a selected sort type.
///
/// Hosts apply [collectionConfigWrites] in order, then store
/// [cardBrowserNoSorting]. The no-ordering path changes only that shared flag,
/// matching the source behavior across Cards and Notes modes.
final class BrowserSortSavePlan {
  const BrowserSortSavePlan({
    required this.cardBrowserNoSorting,
    required this.collectionConfigWrites,
  });

  const BrowserSortSavePlan.noOrdering()
      : cardBrowserNoSorting = true,
        collectionConfigWrites = const [];

  final bool cardBrowserNoSorting;
  final List<BrowserSortConfigWrite> collectionConfigWrites;
}

/// Builds the ordered storage writes without accessing Android or collection IO.
BrowserSortSavePlan buildBrowserSortSavePlan({
  required BrowserSortType sortType,
  required BrowserSortConfigKeys configKeys,
}) =>
    switch (sortType) {
      BrowserSortNoOrdering() => const BrowserSortSavePlan.noOrdering(),
      BrowserSortCollectionOrdering(:final key, :final reverse) =>
        BrowserSortSavePlan(
          cardBrowserNoSorting: false,
          collectionConfigWrites: [
            BrowserSortConfigWrite(key: configKeys.columnKey, value: key),
            BrowserSortConfigWrite(key: configKeys.reverseKey, value: reverse),
          ],
        ),
    };
