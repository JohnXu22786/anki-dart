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
}
