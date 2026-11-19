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
  String get browserDatabaseCheckRequired =>
      'Please use the Check Database action, then try again.';

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
  String get browserHistoryAllCards => 'All cards';

  @override
  String get browserHistoryFiltered => 'Filtered search';

  @override
  String get browserHistoryEdit => 'Edit search';

  @override
  String get browserHistoryRemove => 'Remove from history';

  @override
  String get browserHistoryShowMore => 'Show more';

  @override
  String get browserHistoryShowLess => 'Show less';

  @override
  String get browserHistoryClear => 'Clear history';

  @override
  String get browserFilters => 'Filters';

  @override
  String get browserFilterDecks => 'Decks';

  @override
  String get browserFilterNoteTypes => 'Note types';

  @override
  String get browserFilterTags => 'Tags';

  @override
  String get browserFilterFlags => 'Flags';

  @override
  String get browserFilterCardStates => 'Card states';

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
  String get browserColumnDue => 'Due';

  @override
  String get browserColumnEase => 'Ease';

  @override
  String get browserColumnAverageEase => 'Average ease';

  @override
  String get browserColumnCardModified => 'Card modified';

  @override
  String get browserColumnCreated => 'Created';

  @override
  String get browserColumnNoteModified => 'Note modified';

  @override
  String get browserColumnInterval => 'Interval';

  @override
  String get browserColumnAverageInterval => 'Average interval';

  @override
  String get browserColumnLapses => 'Lapses';

  @override
  String get browserColumnReviews => 'Reviews';

  @override
  String get browserColumnFsrsDifficulty => 'FSRS difficulty';

  @override
  String get browserColumnFsrsRetrievability => 'FSRS retrievability';

  @override
  String get browserColumnFsrsStability => 'FSRS stability';

  @override
  String get browserColumnOriginalPosition => 'New card position';

  @override
  String get browserDueFiltered => 'Filtered';

  @override
  String get browserNew => 'New';

  @override
  String browserDueNew(int count) {
    return 'New $count';
  }

  @override
  String get browserLearning => 'Learning';

  @override
  String get browserTimespanSecond => '1 second';

  @override
  String browserTimespanSeconds(String amount) {
    return '$amount seconds';
  }

  @override
  String get browserTimespanMinute => '1 minute';

  @override
  String browserTimespanMinutes(String amount) {
    return '$amount minutes';
  }

  @override
  String get browserTimespanHour => '1 hour';

  @override
  String browserTimespanHours(String amount) {
    return '$amount hours';
  }

  @override
  String get browserTimespanDay => '1 day';

  @override
  String browserTimespanDays(String amount) {
    return '$amount days';
  }

  @override
  String get browserTimespanMonth => '1 month';

  @override
  String browserTimespanMonths(String amount) {
    return '$amount months';
  }

  @override
  String get browserTimespanYear => '1 year';

  @override
  String browserTimespanYears(String amount) {
    return '$amount years';
  }

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
  String get browserPreviewTitle => 'Card Preview';

  @override
  String get browserPreviewLoadFailed =>
      'This preview could not be loaded. The card or collection may have changed.';

  @override
  String get browserPreviewRetry => 'Try again';

  @override
  String get browserPreviewPrevious => 'Previous card';

  @override
  String get browserPreviewNext => 'Next card';

  @override
  String get browserPreviewShowAnswer => 'Show answer';

  @override
  String get browserPreviewBackSideOnly => 'Show answers only';

  @override
  String browserPreviewProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get browserPreview => 'Preview';

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

  @override
  String get browserSortActiveSection => 'Active columns';

  @override
  String get browserSortOtherSection => 'Other sortable columns';

  @override
  String get browserSortUnavailableSection => 'Unavailable';

  @override
  String get browserSortUseField => 'Use Sort Field instead';

  @override
  String get browserSortCardsOnly => 'Available in Cards mode only';

  @override
  String get browserSortTextAscending => 'A to Z';

  @override
  String get browserSortTextDescending => 'Z to A';

  @override
  String get browserSortNumericAscending => 'Low to high';

  @override
  String get browserSortNumericDescending => 'High to low';

  @override
  String get browserSortDateAscending => 'Oldest first';

  @override
  String get browserSortDateDescending => 'Newest first';

  @override
  String get noteEditorTitle => 'Edit note';

  @override
  String get noteEditorAddTitle => 'Add note';

  @override
  String get noteEditorLoadError =>
      'This note could not be loaded from the active collection.';

  @override
  String get noteEditorSaveError => 'Changes could not be saved. Try again.';

  @override
  String get noteEditorCommittedRetryError =>
      'The note was added, but saving it to storage failed. Retry Save before leaving.';

  @override
  String get noteEditorSaving => 'Saving…';

  @override
  String get noteEditorSaved => 'Saved';

  @override
  String get noteEditorTags => 'Tags';

  @override
  String get noteEditorEditTags => 'Edit tags';

  @override
  String get noteEditorAddTag => 'Add tag';

  @override
  String get noteEditorTagName => 'Tag name';

  @override
  String get noteEditorDuplicateTag => 'This tag already exists';

  @override
  String get noteEditorEmptyTag => 'Enter a tag name';

  @override
  String get noteEditorFilterTags => 'Filter tags';

  @override
  String get noteEditorValidationError => 'The note fields are invalid.';

  @override
  String get noteEditorFirstFieldEmpty => 'The first field is empty.';

  @override
  String get noteEditorMissingCloze => 'A cloze deletion is required.';

  @override
  String get noteEditorNoteTypeNotCloze =>
      'Cloze deletions require a Cloze note type.';

  @override
  String get noteEditorFieldNotCloze =>
      'Cloze deletions must be in a Cloze field.';

  @override
  String noteEditorAddedCards(int count) {
    return 'Added note. Cards created: $count';
  }

  @override
  String get done => 'Done';

  @override
  String get browserUndoNoteEdit => 'Undo note edit';
}
