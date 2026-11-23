// SPDX-License-Identifier: AGPL-3.0-or-later
import 'deck_config.dart';
import 'deck.dart' show DeckId;
import 'easy_day_load.dart';
import 'ids.dart';
import 'load_balancer_day.dart';

/// One row supplied to Core's initial load-balancer cache construction.
typedef LoadBalancerHistoryCard = (CardId, NoteId, DeckId);

/// The per-preset card history and easy-day settings used by load balancing.
///
/// The database query and deck-to-config mapping are supplied by the caller;
/// this pure projection groups the ordered 99-day history into Core's caches.
final class LoadBalancerCache {
  LoadBalancerCache._({
    required this.daysByPreset,
    required this.easyDaysByPreset,
  });

  /// Builds the initial load-balancer caches from Core's ordered day buckets.
  ///
  /// Cards whose deck is absent from [deckConfigByDeck] are ignored, matching
  /// Core's `filter_map()` behavior. Only presets with at least one mapped card
  /// receive day buckets; easy-day settings are projected for every config.
  factory LoadBalancerCache.fromHistory({
    required List<List<LoadBalancerHistoryCard>> cardsByDay,
    required Map<DeckId, DeckConfigId> deckConfigByDeck,
    required Map<DeckConfigId, DeckConfig> configs,
  }) {
    if (cardsByDay.length != 99) {
      throw ArgumentError.value(
        cardsByDay.length,
        'cardsByDay length',
        'expected exactly 99 day buckets',
      );
    }

    final daysByPreset = <DeckConfigId, List<LoadBalancerDay>>{};
    for (var dayIndex = 0; dayIndex < cardsByDay.length; dayIndex++) {
      for (final (cardId, noteId, deckId) in cardsByDay[dayIndex]) {
        final configId = deckConfigByDeck[deckId];
        if (configId == null) continue;

        final days = daysByPreset.putIfAbsent(
          configId,
          () => List<LoadBalancerDay>.generate(
            99,
            (_) => LoadBalancerDay(),
            growable: false,
          ),
        );
        days[dayIndex].add(cardId, noteId);
      }
    }

    final frozenDays = <DeckConfigId, List<LoadBalancerDay>>{
      for (final entry in daysByPreset.entries)
        entry.key: List<LoadBalancerDay>.unmodifiable(entry.value),
    };
    final easyDays = buildEasyDaysPercentages(configs);
    return LoadBalancerCache._(
      daysByPreset: Map<DeckConfigId, List<LoadBalancerDay>>.unmodifiable(
        frozenDays,
      ),
      easyDaysByPreset: Map<DeckConfigId, List<EasyDay>>.unmodifiable({
        for (final entry in easyDays.entries)
          entry.key: List<EasyDay>.unmodifiable(entry.value),
      }),
    );
  }

  /// Cached cards grouped by deck-config preset, retaining day indices.
  final Map<DeckConfigId, List<LoadBalancerDay>> daysByPreset;

  /// Parsed seven-day easy-day settings for each stored config.
  final Map<DeckConfigId, List<EasyDay>> easyDaysByPreset;

  /// Adds a card to its preset's cached day when both indices exist.
  ///
  /// Unknown presets and intervals outside the 99-day cache are ignored, as
  /// in Core's `LoadBalancer::add_card()`.
  void addCard(
    CardId cardId,
    NoteId noteId,
    DeckConfigId configId,
    int interval,
  ) {
    final days = daysByPreset[configId];
    if (days == null || interval < 0 || interval >= days.length) return;
    days[interval].add(cardId, noteId);
  }

  /// Removes the first matching card from every cached preset/day bucket.
  ///
  /// Note membership remains on a day while any other cached card there has
  /// the same note ID, matching `LoadBalancerDay.remove()`.
  void removeCard(CardId cardId) {
    for (final days in daysByPreset.values) {
      for (final day in days) {
        day.remove(cardId);
      }
    }
  }
}
