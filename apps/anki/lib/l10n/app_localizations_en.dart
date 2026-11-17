// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to Anki';

  @override
  String get welcomeBody =>
      'Set up storage to create your first profile and begin using Anki.';

  @override
  String get setupAnki => 'Set up Anki';

  @override
  String get tryAgain => 'Try again';

  @override
  String get storageSetupFailed => 'Storage setup failed';

  @override
  String get collectionOpenFailed => 'Collection could not be opened';

  @override
  String get collectionDefaultDeck => 'Default';

  @override
  String get collectionBasic => 'Basic';

  @override
  String get collectionBasicTyping => 'Basic (type answer)';

  @override
  String get collectionBasicReversed => 'Basic (and reversed card)';

  @override
  String get collectionBasicOptionalReversed =>
      'Basic (optional reversed card)';

  @override
  String get collectionCloze => 'Cloze';

  @override
  String get collectionFront => 'Front';

  @override
  String get collectionBack => 'Back';

  @override
  String get collectionAddReverse => 'Add Reverse';

  @override
  String get collectionText => 'Text';

  @override
  String get collectionBackExtra => 'Back Extra';

  @override
  String get collectionComments => 'Comments';

  @override
  String get collectionCardOne => 'Card 1';

  @override
  String get collectionCardTwo => 'Card 2';

  @override
  String get collectionImageOcclusion => 'Image Occlusion';

  @override
  String get collectionOcclusions => 'Occlusions';

  @override
  String get collectionImage => 'Image';

  @override
  String get collectionHeader => 'Header';

  @override
  String get collectionToggleMasks => 'Toggle Masks';

  @override
  String get collectionImageOcclusionError => 'Error loading Image Occlusion';

  @override
  String get startupCheckFailed => 'Startup setup status could not be checked';

  @override
  String get profileLoadFailed => 'Profiles could not be loaded';

  @override
  String get homeTitle => 'Anki';

  @override
  String activeProfile(String name) {
    return 'Active profile: $name';
  }

  @override
  String get profiles => 'Profiles';

  @override
  String get switchProfileTitle => 'Switch profile';

  @override
  String get addProfile => 'Add profile';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileNameEmptyError => 'Profile name can’t be empty';

  @override
  String profileNameTooLongError(int limit) {
    return 'Profile name must be $limit characters or fewer';
  }

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get rename => 'Rename';

  @override
  String editProfile(String name) {
    return 'Edit profile $name';
  }

  @override
  String get profileOperationFailed => 'Profile could not be saved';

  @override
  String get profileSwitchFailed => 'Profile could not be switched';

  @override
  String get profileSwitchBlocked =>
      'Profile switching is unavailable while Anki is busy';

  @override
  String get close => 'Close';

  @override
  String get deckPickerTitle => 'Decks';

  @override
  String get openDecks => 'Open decks';

  @override
  String get searchDecks => 'Search decks';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get closeSearch => 'Close search';

  @override
  String get refreshDecks => 'Refresh decks';

  @override
  String get loadingDecks => 'Loading decks…';

  @override
  String get decksUnavailable =>
      'Decks are unavailable until a collection service is connected.';

  @override
  String get deckLoadFailed => 'Decks could not be loaded';

  @override
  String get noDecks => 'No decks yet';

  @override
  String get noDeckMatches => 'No decks match this search';

  @override
  String get study => 'Study';

  @override
  String studyDeck(String name) {
    return 'Study $name';
  }

  @override
  String deckCounts(int newCount, int learningCount, int reviewCount) {
    return '$newCount new • $learningCount learning • $reviewCount due';
  }

  @override
  String get newCards => 'New';

  @override
  String get learningCards => 'Learning';

  @override
  String get reviewCards => 'Due';

  @override
  String deckActions(String name) {
    return 'More actions for $name';
  }

  @override
  String get addSharedDeck => 'Add shared deck';

  @override
  String get createDeck => 'Create deck';

  @override
  String get createFilteredDeck => 'Create filtered deck';

  @override
  String get create => 'Create';

  @override
  String get deckName => 'Deck name';

  @override
  String get deckActionFailed => 'Deck action could not be completed';

  @override
  String get filteredDeckOptions => 'Filtered deck options';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get limitTo => 'Limit to';

  @override
  String get cardsSelectedBy => 'Cards selected by';

  @override
  String get orderAdded => 'Order added';

  @override
  String get orderDue => 'Order due';

  @override
  String get orderRandom => 'Random order';

  @override
  String get enableSecondFilter => 'Enable second filter';

  @override
  String get secondSearch => 'Second search';

  @override
  String get secondLimit => 'Second limit';

  @override
  String get options => 'Options';

  @override
  String get rescheduleCards => 'Reschedule cards based on answers';

  @override
  String get delayAgain => 'Delay for again (seconds)';

  @override
  String get delayHard => 'Delay for hard (seconds)';

  @override
  String get delayGood => 'Delay for good (seconds)';

  @override
  String get createEvenIfEmpty => 'Create this deck even if empty';

  @override
  String get build => 'Build';

  @override
  String get filteredDeckBuildFailed => 'Filtered deck could not be built';

  @override
  String get addCard => 'Add card';

  @override
  String get browseCards => 'Browse cards';

  @override
  String get rebuildFilteredDeck => 'Rebuild filtered deck';

  @override
  String get emptyFilteredDeck => 'Empty filtered deck';

  @override
  String get renameDeck => 'Rename deck';

  @override
  String get createSubdeck => 'Create subdeck';

  @override
  String get deckOptions => 'Deck options';

  @override
  String get customStudy => 'Custom study';

  @override
  String get exportDeck => 'Export deck';

  @override
  String get unbury => 'Unbury cards';

  @override
  String get createShortcut => 'Create shortcut';

  @override
  String get editDeckDescription => 'Edit deck description';

  @override
  String get scheduleReminders => 'Schedule review reminders';

  @override
  String get deleteDeck => 'Delete deck';

  @override
  String expandDeck(String name) {
    return 'Expand $name';
  }

  @override
  String collapseDeck(String name) {
    return 'Collapse $name';
  }

  @override
  String get cardBrowserTitle => 'Browse';

  @override
  String get browserSearchHint => 'Search cards';

  @override
  String get browserSaveSearch => 'Save search';

  @override
  String get browserSavedSearches => 'Saved searches';

  @override
  String get browserSavedSearchName => 'Search name';

  @override
  String get browserSavedSearchDuplicate =>
      'A saved search already has that name';

  @override
  String get browserNoSavedSearches => 'No saved searches';

  @override
  String get browserSubmitSavedSearch => 'Search with this query';

  @override
  String get browserApplySavedSearch => 'Apply query for editing';

  @override
  String get browserNoCards => 'No cards found';

  @override
  String get browserNoNotes => 'No notes found';

  @override
  String get browserMode => 'Browser mode';

  @override
  String get browserModeCards => 'Cards';

  @override
  String get browserModeNotes => 'Notes';

  @override
  String get browserLoadFailed => 'Could not load cards';

  @override
  String get browserActionFailed => 'The browser action could not be completed';

  @override
  String get browserPreview => 'Preview selected';

  @override
  String get browserEdit => 'Edit selected';

  @override
  String get browserBulkActions => 'Actions for selected cards';

  @override
  String get browserSuspend => 'Suspend';

  @override
  String get browserBury => 'Bury';

  @override
  String get browserDelete => 'Delete';

  @override
  String browserSelectRow(String name) {
    return 'Select $name';
  }

  @override
  String get browserLoading => 'Loading cards…';

  @override
  String get browserSort => 'Sort cards';

  @override
  String get browserSortNoOrdering => 'No sorting';
}
