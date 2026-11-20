/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';
import 'package:anki_collection_sqlite/anki_collection_sqlite.dart'
    show CollectionTextExportResult;
import 'package:anki_dart/anki_dart.dart'
    show BrowserColumn, BrowserRowId, BrowserSavedSearch, BrowserSortType;
import 'package:anki_dart/deck_picker.dart'
    show DeckPickerExportDeckRequest, DeckPickerExportFormat;

import 'app_contracts.dart';
import 'card_browser_screen.dart';
import 'collection_card_browser_controller.dart';
import 'collection_runtime.dart';
import 'deck_picker_screen.dart';
import 'deck_picker_repository.dart';
import 'collection_text_export.dart';
import 'profile_manager.dart';
import 'text_export_delivery.dart';

export 'app_contracts.dart';

/// Startup and profile boundaries implemented by the platform/backend host.
///
/// Storage selection, persistence, collection opening, and profile switching
/// lifecycle remain behind these injected interfaces.
final class AppServices {
  AppServices({
    required this.startup,
    required this.profiles,
    CollectionRuntime? collections,
    DeckPickerRepository? deckPicker,
    Future<TextExportArtifact> Function(DeckPickerExportDeckRequest request)?
    exportDeck,
    TextExportDelivery? exportDelivery,
    CardBrowserController? cardBrowser,
    ProfileId Function()? generateProfileId,
  }) : collectionRuntimeConfigured = collections != null,
       collections = collections ?? _unconfiguredCollections,
       deckPicker =
           deckPicker ??
           (collections == null
               ? const UnavailableDeckPickerRepository()
               : CollectionDeckPickerRepository(
                   collections,
                   exportDeckHandler:
                       exportDeck ??
                       ((request) => _generateTextExport(collections, request)),
                 )),
       cardBrowser =
           cardBrowser ??
           (collections == null
               ? const UnavailableCardBrowserController()
               : CollectionCardBrowserController(collections)),
       profileManager = ProfileManager(
         profiles,
         generateProfileId: generateProfileId,
         profileSwitch: collections?.switchProfile,
       ),
       exportDelivery = exportDelivery ?? const PlatformTextExportDelivery();

  final StartupService startup;
  final ProfileRepository profiles;
  final bool collectionRuntimeConfigured;
  final CollectionRuntime collections;
  final DeckPickerRepository deckPicker;
  final TextExportDelivery exportDelivery;
  final CardBrowserController cardBrowser;
  final ProfileManager profileManager;
}

Future<TextExportArtifact> _generateTextExport(
  CollectionRuntime collections,
  DeckPickerExportDeckRequest request,
) async {
  if (request.format != DeckPickerExportFormat.notes &&
      request.format != DeckPickerExportFormat.cards) {
    throw UnsupportedError('This export format is not supported yet.');
  }
  final storage = collections.storage;
  if (storage == null || !collections.isInitialized) {
    throw StateError('The active profile collection is not open.');
  }
  final CollectionTextExportResult result = await generateDeckPickerTextExport(
    storage,
    request,
  );
  return createDeckPickerTextExportArtifact(request, result);
}

/// Explicit failure boundary until a collection-backed browser controller is
/// connected; opening the route never presents placeholder rows.
final class UnavailableCardBrowserController implements CardBrowserController {
  const UnavailableCardBrowserController();

  UnsupportedError get _unavailable =>
      UnsupportedError('Card Browser collection services are not configured.');

  @override
  Future<CardBrowserSnapshot> load() => Future.error(_unavailable);

  @override
  Future<CardBrowserSnapshot> search(String query) =>
      Future.error(_unavailable);

  @override
  Future<List<BrowserSavedSearch>> loadSavedSearches() =>
      Future.error(_unavailable);

  @override
  Future<(bool, List<BrowserSavedSearch>)> addSavedSearch(
    BrowserSavedSearch savedSearch,
  ) => Future.error(_unavailable);

  @override
  Future<(bool, List<BrowserSavedSearch>)> deleteSavedSearch(String name) =>
      Future.error(_unavailable);

  @override
  Future<CardBrowserSnapshot> updateSort(BrowserSortType sortType) =>
      Future.error(_unavailable);

  @override
  Future<void> openColumnOptions(BrowserColumn column) =>
      Future.error(_unavailable);

  @override
  Future<void> manageColumns() => Future.error(_unavailable);

  @override
  Future<void> saveColumns(List<BrowserColumn> columns) =>
      Future.error(_unavailable);

  @override
  Future<void> updateSelection(List<BrowserRowId> selectedRows) =>
      Future.error(_unavailable);

  @override
  Future<void> preview(BrowserRowId rowId) => Future.error(_unavailable);

  @override
  Future<void> edit(BrowserRowId rowId) => Future.error(_unavailable);

  @override
  Future<void> performBulkAction(
    CardBrowserBulkAction action,
    List<BrowserRowId> selectedRows,
  ) => Future.error(_unavailable);
}

final _unconfiguredCollections = CollectionRuntime(
  locationForProfile: (_) => Future.error(
    UnsupportedError('Collection storage adapter is not configured.'),
  ),
  createDriver: () => Future.error(
    UnsupportedError('Collection storage adapter is not configured.'),
  ),
);

/// Default host boundary until platform storage and backend adapters are wired.
final class UnconfiguredAppServices
    implements StartupService, ProfileRepository {
  const UnconfiguredAppServices();

  @override
  Future<bool> isFirstRun() async => true;

  @override
  Future<void> completeOnboarding() => Future.error(
    UnsupportedError('Platform storage adapter is not configured.'),
  );

  @override
  Future<ProfileSnapshot> load() => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> create(
    ProfileId id,
    ProfileName name, {
    bool isActive = false,
  }) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> rename(ProfileId id, ProfileName name) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Future<void> persistActiveProfile(ProfileId id) => Future.error(
    UnsupportedError('Profile storage adapter is not configured.'),
  );

  @override
  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks => const [];
}
