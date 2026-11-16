/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:math';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart';

import 'l10n/app_localizations.dart';

/// Builds Core-compatible initialization and migration callbacks for the app.
CollectionOpenCallbacks appCollectionOpenCallbacks(
  CollectionSqliteStorage storage,
  AppLocalizations strings,
) {
  final random = Random.secure();
  BigInt randomU64() =>
      (BigInt.from(random.nextInt(1 << 31)) << 33) |
      (BigInt.from(random.nextInt(1 << 31)) << 2) |
      BigInt.from(random.nextInt(1 << 2));

  return CollectionSqliteInitializationCallbacks(
    storage: storage,
    text: _AppCollectionText(strings),
    migrations: CollectionSqliteMigrationCallbacks(
      storage: storage,
      randomU64: randomU64,
    ),
    localMinutesWest: (timestamp) =>
        -timestamp.toLocal().timeZoneOffset.inMinutes,
    randomU64: randomU64,
  );
}

final class _AppCollectionText implements CollectionInitialTextProvider {
  const _AppCollectionText(this.strings);

  final AppLocalizations strings;

  @override
  String get defaultDeckName => strings.collectionDefaultDeck;

  @override
  StockNotetypeNames get stockNotetypeNames => StockNotetypeNames(
    basic: strings.collectionBasic,
    basicTyping: strings.collectionBasicTyping,
    basicReversed: strings.collectionBasicReversed,
    basicOptionalReversed: strings.collectionBasicOptionalReversed,
    cloze: strings.collectionCloze,
    frontField: strings.collectionFront,
    backField: strings.collectionBack,
    addReverseField: strings.collectionAddReverse,
    textField: strings.collectionText,
    backExtraField: strings.collectionBackExtra,
    commentsField: strings.collectionComments,
    cardOne: strings.collectionCardOne,
    cardTwo: strings.collectionCardTwo,
    imageOcclusion: strings.collectionImageOcclusion,
    occlusionsField: strings.collectionOcclusions,
    imageField: strings.collectionImage,
    headerField: strings.collectionHeader,
    toggleMasks: strings.collectionToggleMasks,
    errorLoadingImageOcclusion: strings.collectionImageOcclusionError,
  );
}
