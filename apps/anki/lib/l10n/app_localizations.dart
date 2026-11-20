// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Anki'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Set up storage to create your first profile and begin using Anki.'**
  String get welcomeBody;

  /// No description provided for @setupAnki.
  ///
  /// In en, this message translates to:
  /// **'Set up Anki'**
  String get setupAnki;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @storageSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Storage setup failed'**
  String get storageSetupFailed;

  /// No description provided for @collectionOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Collection could not be opened'**
  String get collectionOpenFailed;

  /// No description provided for @collectionDefaultDeck.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get collectionDefaultDeck;

  /// No description provided for @collectionBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get collectionBasic;

  /// No description provided for @collectionBasicTyping.
  ///
  /// In en, this message translates to:
  /// **'Basic (type answer)'**
  String get collectionBasicTyping;

  /// No description provided for @collectionBasicReversed.
  ///
  /// In en, this message translates to:
  /// **'Basic (and reversed card)'**
  String get collectionBasicReversed;

  /// No description provided for @collectionBasicOptionalReversed.
  ///
  /// In en, this message translates to:
  /// **'Basic (optional reversed card)'**
  String get collectionBasicOptionalReversed;

  /// No description provided for @collectionCloze.
  ///
  /// In en, this message translates to:
  /// **'Cloze'**
  String get collectionCloze;

  /// No description provided for @collectionFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get collectionFront;

  /// No description provided for @collectionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get collectionBack;

  /// No description provided for @collectionAddReverse.
  ///
  /// In en, this message translates to:
  /// **'Add Reverse'**
  String get collectionAddReverse;

  /// No description provided for @collectionText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get collectionText;

  /// No description provided for @collectionBackExtra.
  ///
  /// In en, this message translates to:
  /// **'Back Extra'**
  String get collectionBackExtra;

  /// No description provided for @collectionComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get collectionComments;

  /// No description provided for @collectionCardOne.
  ///
  /// In en, this message translates to:
  /// **'Card 1'**
  String get collectionCardOne;

  /// No description provided for @collectionCardTwo.
  ///
  /// In en, this message translates to:
  /// **'Card 2'**
  String get collectionCardTwo;

  /// No description provided for @collectionImageOcclusion.
  ///
  /// In en, this message translates to:
  /// **'Image Occlusion'**
  String get collectionImageOcclusion;

  /// No description provided for @collectionOcclusions.
  ///
  /// In en, this message translates to:
  /// **'Occlusions'**
  String get collectionOcclusions;

  /// No description provided for @collectionImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get collectionImage;

  /// No description provided for @collectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get collectionHeader;

  /// No description provided for @collectionToggleMasks.
  ///
  /// In en, this message translates to:
  /// **'Toggle Masks'**
  String get collectionToggleMasks;

  /// No description provided for @collectionImageOcclusionError.
  ///
  /// In en, this message translates to:
  /// **'Error loading Image Occlusion'**
  String get collectionImageOcclusionError;

  /// No description provided for @startupCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Startup setup status could not be checked'**
  String get startupCheckFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Profiles could not be loaded'**
  String get profileLoadFailed;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Anki'**
  String get homeTitle;

  /// No description provided for @activeProfile.
  ///
  /// In en, this message translates to:
  /// **'Active profile: {name}'**
  String activeProfile(String name);

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @switchProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchProfileTitle;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get addProfile;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @profileNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Profile name can’t be empty'**
  String get profileNameEmptyError;

  /// No description provided for @profileNameTooLongError.
  ///
  /// In en, this message translates to:
  /// **'Profile name must be {limit} characters or fewer'**
  String profileNameTooLongError(int limit);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile {name}'**
  String editProfile(String name);

  /// No description provided for @profileOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be saved'**
  String get profileOperationFailed;

  /// No description provided for @profileSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be switched'**
  String get profileSwitchFailed;

  /// No description provided for @profileSwitchBlocked.
  ///
  /// In en, this message translates to:
  /// **'Profile switching is unavailable while Anki is busy'**
  String get profileSwitchBlocked;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deckPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get deckPickerTitle;

  /// No description provided for @openDecks.
  ///
  /// In en, this message translates to:
  /// **'Open decks'**
  String get openDecks;

  /// No description provided for @searchDecks.
  ///
  /// In en, this message translates to:
  /// **'Search decks'**
  String get searchDecks;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @refreshDecks.
  ///
  /// In en, this message translates to:
  /// **'Refresh decks'**
  String get refreshDecks;

  /// No description provided for @loadingDecks.
  ///
  /// In en, this message translates to:
  /// **'Loading decks…'**
  String get loadingDecks;

  /// No description provided for @decksUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Decks are unavailable until a collection service is connected.'**
  String get decksUnavailable;

  /// No description provided for @browserDatabaseCheckRequired.
  ///
  /// In en, this message translates to:
  /// **'Please use the Check Database action, then try again.'**
  String get browserDatabaseCheckRequired;

  /// No description provided for @deckLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Decks could not be loaded'**
  String get deckLoadFailed;

  /// No description provided for @noDecks.
  ///
  /// In en, this message translates to:
  /// **'No decks yet'**
  String get noDecks;

  /// No description provided for @noDeckMatches.
  ///
  /// In en, this message translates to:
  /// **'No decks match this search'**
  String get noDeckMatches;

  /// No description provided for @study.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// No description provided for @studyDeck.
  ///
  /// In en, this message translates to:
  /// **'Study {name}'**
  String studyDeck(String name);

  /// No description provided for @deckCounts.
  ///
  /// In en, this message translates to:
  /// **'{newCount} new • {learningCount} learning • {reviewCount} due'**
  String deckCounts(int newCount, int learningCount, int reviewCount);

  /// No description provided for @newCards.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCards;

  /// No description provided for @learningCards.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningCards;

  /// No description provided for @reviewCards.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get reviewCards;

  /// No description provided for @deckActions.
  ///
  /// In en, this message translates to:
  /// **'More actions for {name}'**
  String deckActions(String name);

  /// No description provided for @addSharedDeck.
  ///
  /// In en, this message translates to:
  /// **'Add shared deck'**
  String get addSharedDeck;

  /// No description provided for @createDeck.
  ///
  /// In en, this message translates to:
  /// **'Create deck'**
  String get createDeck;

  /// No description provided for @createFilteredDeck.
  ///
  /// In en, this message translates to:
  /// **'Create filtered deck'**
  String get createFilteredDeck;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deckName.
  ///
  /// In en, this message translates to:
  /// **'Deck name'**
  String get deckName;

  /// No description provided for @newDeckName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newDeckName;

  /// No description provided for @deckNameExists.
  ///
  /// In en, this message translates to:
  /// **'A deck with this name already exists'**
  String get deckNameExists;

  /// No description provided for @deckActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Deck action could not be completed'**
  String get deckActionFailed;

  /// No description provided for @filteredDeckOptions.
  ///
  /// In en, this message translates to:
  /// **'Filtered deck options'**
  String get filteredDeckOptions;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @limitTo.
  ///
  /// In en, this message translates to:
  /// **'Limit to'**
  String get limitTo;

  /// No description provided for @cardsSelectedBy.
  ///
  /// In en, this message translates to:
  /// **'Cards selected by'**
  String get cardsSelectedBy;

  /// No description provided for @orderAdded.
  ///
  /// In en, this message translates to:
  /// **'Order added'**
  String get orderAdded;

  /// No description provided for @orderDue.
  ///
  /// In en, this message translates to:
  /// **'Order due'**
  String get orderDue;

  /// No description provided for @orderRandom.
  ///
  /// In en, this message translates to:
  /// **'Random order'**
  String get orderRandom;

  /// No description provided for @enableSecondFilter.
  ///
  /// In en, this message translates to:
  /// **'Enable second filter'**
  String get enableSecondFilter;

  /// No description provided for @secondSearch.
  ///
  /// In en, this message translates to:
  /// **'Second search'**
  String get secondSearch;

  /// No description provided for @secondLimit.
  ///
  /// In en, this message translates to:
  /// **'Second limit'**
  String get secondLimit;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @rescheduleCards.
  ///
  /// In en, this message translates to:
  /// **'Reschedule cards based on answers'**
  String get rescheduleCards;

  /// No description provided for @delayAgain.
  ///
  /// In en, this message translates to:
  /// **'Delay for again (seconds)'**
  String get delayAgain;

  /// No description provided for @delayHard.
  ///
  /// In en, this message translates to:
  /// **'Delay for hard (seconds)'**
  String get delayHard;

  /// No description provided for @delayGood.
  ///
  /// In en, this message translates to:
  /// **'Delay for good (seconds)'**
  String get delayGood;

  /// No description provided for @createEvenIfEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create this deck even if empty'**
  String get createEvenIfEmpty;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @filteredDeckBuildFailed.
  ///
  /// In en, this message translates to:
  /// **'Filtered deck could not be built'**
  String get filteredDeckBuildFailed;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @browseCards.
  ///
  /// In en, this message translates to:
  /// **'Browse cards'**
  String get browseCards;

  /// No description provided for @rebuildFilteredDeck.
  ///
  /// In en, this message translates to:
  /// **'Rebuild filtered deck'**
  String get rebuildFilteredDeck;

  /// No description provided for @emptyFilteredDeck.
  ///
  /// In en, this message translates to:
  /// **'Empty filtered deck'**
  String get emptyFilteredDeck;

  /// No description provided for @renameDeck.
  ///
  /// In en, this message translates to:
  /// **'Rename deck'**
  String get renameDeck;

  /// No description provided for @createSubdeck.
  ///
  /// In en, this message translates to:
  /// **'Create subdeck'**
  String get createSubdeck;

  /// No description provided for @deckOptions.
  ///
  /// In en, this message translates to:
  /// **'Deck options'**
  String get deckOptions;

  /// No description provided for @deckOptionsNewLimit.
  ///
  /// In en, this message translates to:
  /// **'New cards per day'**
  String get deckOptionsNewLimit;

  /// No description provided for @deckOptionsReviewLimit.
  ///
  /// In en, this message translates to:
  /// **'Review cards per day'**
  String get deckOptionsReviewLimit;

  /// No description provided for @deckOptionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Deck options saved'**
  String get deckOptionsSaved;

  /// No description provided for @deckOptionsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save deck options.'**
  String get deckOptionsSaveFailed;

  /// No description provided for @deckOptionsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter whole numbers between 0 and 9999.'**
  String get deckOptionsInvalid;

  /// No description provided for @deckOptionsDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get deckOptionsDiscardTitle;

  /// No description provided for @deckOptionsDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your deck option changes have not been saved.'**
  String get deckOptionsDiscardMessage;

  /// No description provided for @deckOptionsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get deckOptionsDiscard;

  /// No description provided for @customStudy.
  ///
  /// In en, this message translates to:
  /// **'Custom study'**
  String get customStudy;

  /// No description provided for @exportDeck.
  ///
  /// In en, this message translates to:
  /// **'Export deck'**
  String get exportDeck;

  /// No description provided for @unbury.
  ///
  /// In en, this message translates to:
  /// **'Unbury cards'**
  String get unbury;

  /// No description provided for @createShortcut.
  ///
  /// In en, this message translates to:
  /// **'Create shortcut'**
  String get createShortcut;

  /// No description provided for @editDeckDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit deck description'**
  String get editDeckDescription;

  /// No description provided for @deckDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get deckDescriptionLabel;

  /// No description provided for @deckDescriptionMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Format as Markdown'**
  String get deckDescriptionMarkdown;

  /// No description provided for @deckDescriptionSaved.
  ///
  /// In en, this message translates to:
  /// **'Deck description saved'**
  String get deckDescriptionSaved;

  /// No description provided for @deckDescriptionDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get deckDescriptionDiscardTitle;

  /// No description provided for @deckDescriptionDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved description changes will be lost.'**
  String get deckDescriptionDiscardMessage;

  /// No description provided for @deckDescriptionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get deckDescriptionDiscard;

  /// No description provided for @deckDescriptionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Deck description could not be saved'**
  String get deckDescriptionSaveFailed;

  /// No description provided for @scheduleReminders.
  ///
  /// In en, this message translates to:
  /// **'Schedule review reminders'**
  String get scheduleReminders;

  /// No description provided for @deleteDeck.
  ///
  /// In en, this message translates to:
  /// **'Delete deck'**
  String get deleteDeck;

  /// No description provided for @expandDeck.
  ///
  /// In en, this message translates to:
  /// **'Expand {name}'**
  String expandDeck(String name);

  /// No description provided for @collapseDeck.
  ///
  /// In en, this message translates to:
  /// **'Collapse {name}'**
  String collapseDeck(String name);

  /// No description provided for @cardBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get cardBrowserTitle;

  /// No description provided for @browserSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cards'**
  String get browserSearchHint;

  /// No description provided for @browserHistoryAllCards.
  ///
  /// In en, this message translates to:
  /// **'All cards'**
  String get browserHistoryAllCards;

  /// No description provided for @browserHistoryFiltered.
  ///
  /// In en, this message translates to:
  /// **'Filtered search'**
  String get browserHistoryFiltered;

  /// No description provided for @browserHistoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit search'**
  String get browserHistoryEdit;

  /// No description provided for @browserHistoryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get browserHistoryRemove;

  /// No description provided for @browserHistoryShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get browserHistoryShowMore;

  /// No description provided for @browserHistoryShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get browserHistoryShowLess;

  /// No description provided for @browserHistoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get browserHistoryClear;

  /// No description provided for @browserFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get browserFilters;

  /// No description provided for @browserAllDecks.
  ///
  /// In en, this message translates to:
  /// **'All decks'**
  String get browserAllDecks;

  /// No description provided for @browserSelectedDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck: {name}'**
  String browserSelectedDeck(String name);

  /// No description provided for @browserFilterDecks.
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get browserFilterDecks;

  /// No description provided for @browserFilterNoteTypes.
  ///
  /// In en, this message translates to:
  /// **'Note types'**
  String get browserFilterNoteTypes;

  /// No description provided for @browserFilterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get browserFilterTags;

  /// No description provided for @browserFilterFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get browserFilterFlags;

  /// No description provided for @browserFilterCardStates.
  ///
  /// In en, this message translates to:
  /// **'Card states'**
  String get browserFilterCardStates;

  /// No description provided for @browserSaveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save search'**
  String get browserSaveSearch;

  /// No description provided for @browserSavedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get browserSavedSearches;

  /// No description provided for @browserSavedSearchName.
  ///
  /// In en, this message translates to:
  /// **'Search name'**
  String get browserSavedSearchName;

  /// No description provided for @browserSavedSearchDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A saved search already has that name'**
  String get browserSavedSearchDuplicate;

  /// No description provided for @browserNoSavedSearches.
  ///
  /// In en, this message translates to:
  /// **'No saved searches'**
  String get browserNoSavedSearches;

  /// No description provided for @browserSubmitSavedSearch.
  ///
  /// In en, this message translates to:
  /// **'Search with this query'**
  String get browserSubmitSavedSearch;

  /// No description provided for @browserApplySavedSearch.
  ///
  /// In en, this message translates to:
  /// **'Apply query for editing'**
  String get browserApplySavedSearch;

  /// No description provided for @browserNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards found'**
  String get browserNoCards;

  /// No description provided for @browserColumnDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get browserColumnDue;

  /// No description provided for @browserColumnEase.
  ///
  /// In en, this message translates to:
  /// **'Ease'**
  String get browserColumnEase;

  /// No description provided for @browserColumnAverageEase.
  ///
  /// In en, this message translates to:
  /// **'Average ease'**
  String get browserColumnAverageEase;

  /// No description provided for @browserColumnCardModified.
  ///
  /// In en, this message translates to:
  /// **'Card modified'**
  String get browserColumnCardModified;

  /// No description provided for @browserColumnCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get browserColumnCreated;

  /// No description provided for @browserColumnNoteModified.
  ///
  /// In en, this message translates to:
  /// **'Note modified'**
  String get browserColumnNoteModified;

  /// No description provided for @browserColumnInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get browserColumnInterval;

  /// No description provided for @browserColumnAverageInterval.
  ///
  /// In en, this message translates to:
  /// **'Average interval'**
  String get browserColumnAverageInterval;

  /// No description provided for @browserColumnLapses.
  ///
  /// In en, this message translates to:
  /// **'Lapses'**
  String get browserColumnLapses;

  /// No description provided for @browserColumnReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get browserColumnReviews;

  /// No description provided for @browserColumnFsrsDifficulty.
  ///
  /// In en, this message translates to:
  /// **'FSRS difficulty'**
  String get browserColumnFsrsDifficulty;

  /// No description provided for @browserColumnFsrsRetrievability.
  ///
  /// In en, this message translates to:
  /// **'FSRS retrievability'**
  String get browserColumnFsrsRetrievability;

  /// No description provided for @browserColumnFsrsStability.
  ///
  /// In en, this message translates to:
  /// **'FSRS stability'**
  String get browserColumnFsrsStability;

  /// No description provided for @browserColumnOriginalPosition.
  ///
  /// In en, this message translates to:
  /// **'New card position'**
  String get browserColumnOriginalPosition;

  /// No description provided for @browserDueFiltered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get browserDueFiltered;

  /// No description provided for @browserNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get browserNew;

  /// No description provided for @browserDueNew.
  ///
  /// In en, this message translates to:
  /// **'New {count}'**
  String browserDueNew(int count);

  /// No description provided for @browserLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get browserLearning;

  /// No description provided for @browserTimespanSecond.
  ///
  /// In en, this message translates to:
  /// **'1 second'**
  String get browserTimespanSecond;

  /// No description provided for @browserTimespanSeconds.
  ///
  /// In en, this message translates to:
  /// **'{amount} seconds'**
  String browserTimespanSeconds(String amount);

  /// No description provided for @browserTimespanMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get browserTimespanMinute;

  /// No description provided for @browserTimespanMinutes.
  ///
  /// In en, this message translates to:
  /// **'{amount} minutes'**
  String browserTimespanMinutes(String amount);

  /// No description provided for @browserTimespanHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get browserTimespanHour;

  /// No description provided for @browserTimespanHours.
  ///
  /// In en, this message translates to:
  /// **'{amount} hours'**
  String browserTimespanHours(String amount);

  /// No description provided for @browserTimespanDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get browserTimespanDay;

  /// No description provided for @browserTimespanDays.
  ///
  /// In en, this message translates to:
  /// **'{amount} days'**
  String browserTimespanDays(String amount);

  /// No description provided for @browserTimespanMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get browserTimespanMonth;

  /// No description provided for @browserTimespanMonths.
  ///
  /// In en, this message translates to:
  /// **'{amount} months'**
  String browserTimespanMonths(String amount);

  /// No description provided for @browserTimespanYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get browserTimespanYear;

  /// No description provided for @browserTimespanYears.
  ///
  /// In en, this message translates to:
  /// **'{amount} years'**
  String browserTimespanYears(String amount);

  /// No description provided for @browserNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get browserNoNotes;

  /// No description provided for @browserMode.
  ///
  /// In en, this message translates to:
  /// **'Browser mode'**
  String get browserMode;

  /// No description provided for @browserModeCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get browserModeCards;

  /// No description provided for @browserModeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get browserModeNotes;

  /// No description provided for @browserLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load cards'**
  String get browserLoadFailed;

  /// No description provided for @browserActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The browser action could not be completed'**
  String get browserActionFailed;

  /// No description provided for @browserPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Preview'**
  String get browserPreviewTitle;

  /// No description provided for @browserPreviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This preview could not be loaded. The card or collection may have changed.'**
  String get browserPreviewLoadFailed;

  /// No description provided for @browserPreviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get browserPreviewRetry;

  /// No description provided for @browserPreviewPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous card'**
  String get browserPreviewPrevious;

  /// No description provided for @browserPreviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get browserPreviewNext;

  /// No description provided for @browserPreviewShowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get browserPreviewShowAnswer;

  /// No description provided for @browserPreviewBackSideOnly.
  ///
  /// In en, this message translates to:
  /// **'Show answers only'**
  String get browserPreviewBackSideOnly;

  /// No description provided for @browserPreviewProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String browserPreviewProgress(int current, int total);

  /// No description provided for @browserPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get browserPreview;

  /// No description provided for @browserEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit selected'**
  String get browserEdit;

  /// No description provided for @browserBulkActions.
  ///
  /// In en, this message translates to:
  /// **'Actions for selected cards'**
  String get browserBulkActions;

  /// No description provided for @browserBulkActionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Browser action completed'**
  String get browserBulkActionCompleted;

  /// No description provided for @browserBulkActionUndone.
  ///
  /// In en, this message translates to:
  /// **'Browser action undone'**
  String get browserBulkActionUndone;

  /// No description provided for @browserUndoBulkAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get browserUndoBulkAction;

  /// No description provided for @browserRedoBulkAction.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get browserRedoBulkAction;

  /// No description provided for @browserSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get browserSuspend;

  /// No description provided for @browserBury.
  ///
  /// In en, this message translates to:
  /// **'Bury'**
  String get browserBury;

  /// No description provided for @browserDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get browserDelete;

  /// No description provided for @browserSelectRow.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String browserSelectRow(String name);

  /// No description provided for @browserLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading cards…'**
  String get browserLoading;

  /// No description provided for @browserSort.
  ///
  /// In en, this message translates to:
  /// **'Sort cards'**
  String get browserSort;

  /// No description provided for @browserSortNoOrdering.
  ///
  /// In en, this message translates to:
  /// **'No sorting'**
  String get browserSortNoOrdering;

  /// No description provided for @browserSortActiveSection.
  ///
  /// In en, this message translates to:
  /// **'Active columns'**
  String get browserSortActiveSection;

  /// No description provided for @browserSortOtherSection.
  ///
  /// In en, this message translates to:
  /// **'Other sortable columns'**
  String get browserSortOtherSection;

  /// No description provided for @browserSortUnavailableSection.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get browserSortUnavailableSection;

  /// No description provided for @browserSortUseField.
  ///
  /// In en, this message translates to:
  /// **'Use Sort Field instead'**
  String get browserSortUseField;

  /// No description provided for @browserSortCardsOnly.
  ///
  /// In en, this message translates to:
  /// **'Available in Cards mode only'**
  String get browserSortCardsOnly;

  /// No description provided for @browserSortTextAscending.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get browserSortTextAscending;

  /// No description provided for @browserSortTextDescending.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get browserSortTextDescending;

  /// No description provided for @browserSortNumericAscending.
  ///
  /// In en, this message translates to:
  /// **'Low to high'**
  String get browserSortNumericAscending;

  /// No description provided for @browserSortNumericDescending.
  ///
  /// In en, this message translates to:
  /// **'High to low'**
  String get browserSortNumericDescending;

  /// No description provided for @browserSortDateAscending.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get browserSortDateAscending;

  /// No description provided for @browserSortDateDescending.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get browserSortDateDescending;

  /// No description provided for @noteEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditorTitle;

  /// No description provided for @noteEditorAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get noteEditorAddTitle;

  /// No description provided for @noteEditorLoadError.
  ///
  /// In en, this message translates to:
  /// **'This note could not be loaded from the active collection.'**
  String get noteEditorLoadError;

  /// No description provided for @noteEditorSaveError.
  ///
  /// In en, this message translates to:
  /// **'Changes could not be saved. Try again.'**
  String get noteEditorSaveError;

  /// No description provided for @noteEditorCommittedRetryError.
  ///
  /// In en, this message translates to:
  /// **'The note was added, but saving it to storage failed. Retry Save before leaving.'**
  String get noteEditorCommittedRetryError;

  /// No description provided for @noteEditorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get noteEditorSaving;

  /// No description provided for @noteEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get noteEditorSaved;

  /// No description provided for @noteEditorTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get noteEditorTags;

  /// No description provided for @noteEditorEditTags.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get noteEditorEditTags;

  /// No description provided for @noteEditorAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get noteEditorAddTag;

  /// No description provided for @noteEditorTagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get noteEditorTagName;

  /// No description provided for @noteEditorDuplicateTag.
  ///
  /// In en, this message translates to:
  /// **'This tag already exists'**
  String get noteEditorDuplicateTag;

  /// No description provided for @noteEditorEmptyTag.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag name'**
  String get noteEditorEmptyTag;

  /// No description provided for @noteEditorFilterTags.
  ///
  /// In en, this message translates to:
  /// **'Filter tags'**
  String get noteEditorFilterTags;

  /// No description provided for @noteEditorDeck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get noteEditorDeck;

  /// No description provided for @noteEditorNoteType.
  ///
  /// In en, this message translates to:
  /// **'Note type'**
  String get noteEditorNoteType;

  /// No description provided for @noteEditorChooseDeck.
  ///
  /// In en, this message translates to:
  /// **'Choose deck'**
  String get noteEditorChooseDeck;

  /// No description provided for @noteEditorFilterDecks.
  ///
  /// In en, this message translates to:
  /// **'Filter decks'**
  String get noteEditorFilterDecks;

  /// No description provided for @noteEditorDeckLoadError.
  ///
  /// In en, this message translates to:
  /// **'Decks could not be loaded.'**
  String get noteEditorDeckLoadError;

  /// No description provided for @noteEditorNoDecks.
  ///
  /// In en, this message translates to:
  /// **'No selectable decks are available.'**
  String get noteEditorNoDecks;

  /// No description provided for @noteEditorNoDeckMatches.
  ///
  /// In en, this message translates to:
  /// **'No decks match your search.'**
  String get noteEditorNoDeckMatches;

  /// No description provided for @noteEditorValidationError.
  ///
  /// In en, this message translates to:
  /// **'The note fields are invalid.'**
  String get noteEditorValidationError;

  /// No description provided for @noteEditorFirstFieldEmpty.
  ///
  /// In en, this message translates to:
  /// **'The first field is empty.'**
  String get noteEditorFirstFieldEmpty;

  /// No description provided for @noteEditorMissingCloze.
  ///
  /// In en, this message translates to:
  /// **'A cloze deletion is required.'**
  String get noteEditorMissingCloze;

  /// No description provided for @noteEditorNoteTypeNotCloze.
  ///
  /// In en, this message translates to:
  /// **'Cloze deletions require a Cloze note type.'**
  String get noteEditorNoteTypeNotCloze;

  /// No description provided for @noteEditorFieldNotCloze.
  ///
  /// In en, this message translates to:
  /// **'Cloze deletions must be in a Cloze field.'**
  String get noteEditorFieldNotCloze;

  /// No description provided for @noteEditorAddedCards.
  ///
  /// In en, this message translates to:
  /// **'Added note. Cards created: {count}'**
  String noteEditorAddedCards(int count);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @browserUndoNoteEdit.
  ///
  /// In en, this message translates to:
  /// **'Undo note edit'**
  String get browserUndoNoteEdit;

  /// No description provided for @deletingDeck.
  ///
  /// In en, this message translates to:
  /// **'Deleting deck…'**
  String get deletingDeck;

  /// No description provided for @deckDeletionResult.
  ///
  /// In en, this message translates to:
  /// **'Cards deleted from {deckName}: {cardsDeleted}'**
  String deckDeletionResult(int cardsDeleted, String deckName);

  /// No description provided for @deckDeletionUndone.
  ///
  /// In en, this message translates to:
  /// **'Deck deletion undone'**
  String get deckDeletionUndone;

  /// No description provided for @deckDeletionRedone.
  ///
  /// In en, this message translates to:
  /// **'Deck deletion redone'**
  String get deckDeletionRedone;

  /// No description provided for @deckDeletionFlushWarning.
  ///
  /// In en, this message translates to:
  /// **'Storage could not be synced.'**
  String get deckDeletionFlushWarning;

  /// No description provided for @undoDeckDeletion.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoDeckDeletion;

  /// No description provided for @redoDeckDeletion.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoDeckDeletion;

  /// No description provided for @unburyingDeck.
  ///
  /// In en, this message translates to:
  /// **'Unburying cards…'**
  String get unburyingDeck;

  /// No description provided for @deckUnburiedResult.
  ///
  /// In en, this message translates to:
  /// **'Cards unburied from {deckName}: {cardsUnburied}'**
  String deckUnburiedResult(int cardsUnburied, String deckName);

  /// No description provided for @deckUnburyUndone.
  ///
  /// In en, this message translates to:
  /// **'Deck unbury undone'**
  String get deckUnburyUndone;

  /// No description provided for @deckUnburyRedone.
  ///
  /// In en, this message translates to:
  /// **'Deck unbury redone'**
  String get deckUnburyRedone;

  /// No description provided for @undoDeckUnbury.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoDeckUnbury;

  /// No description provided for @redoDeckUnbury.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoDeckUnbury;

  /// No description provided for @customStudyCardStateOrTag.
  ///
  /// In en, this message translates to:
  /// **'Study by card state or tag'**
  String get customStudyCardStateOrTag;

  /// No description provided for @customStudyNewCardsOnly.
  ///
  /// In en, this message translates to:
  /// **'New cards only'**
  String get customStudyNewCardsOnly;

  /// No description provided for @customStudyDueCardsOnly.
  ///
  /// In en, this message translates to:
  /// **'Due cards only'**
  String get customStudyDueCardsOnly;

  /// No description provided for @customStudyReviewCardsRandom.
  ///
  /// In en, this message translates to:
  /// **'All review cards in random order'**
  String get customStudyReviewCardsRandom;

  /// No description provided for @customStudyAllCardsRandom.
  ///
  /// In en, this message translates to:
  /// **'All cards in random order'**
  String get customStudyAllCardsRandom;

  /// No description provided for @customStudyCardsToStudy.
  ///
  /// In en, this message translates to:
  /// **'Cards to study'**
  String get customStudyCardsToStudy;

  /// No description provided for @customStudyIncludeTag.
  ///
  /// In en, this message translates to:
  /// **'Include {tag}'**
  String customStudyIncludeTag(Object tag);

  /// No description provided for @customStudyExcludeTag.
  ///
  /// In en, this message translates to:
  /// **'Exclude {tag}'**
  String customStudyExcludeTag(Object tag);

  /// No description provided for @customStudyTooManyTags.
  ///
  /// In en, this message translates to:
  /// **'Select no more than 100 tags.'**
  String get customStudyTooManyTags;

  /// No description provided for @customStudyPositiveCount.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive card count.'**
  String get customStudyPositiveCount;

  /// No description provided for @customStudyInclude.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get customStudyInclude;

  /// No description provided for @customStudyExclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get customStudyExclude;

  /// No description provided for @reviewAhead.
  ///
  /// In en, this message translates to:
  /// **'Review ahead'**
  String get reviewAhead;

  /// No description provided for @reviewAheadDays.
  ///
  /// In en, this message translates to:
  /// **'Days to review ahead'**
  String get reviewAheadDays;

  /// No description provided for @reviewAheadMinimumDays.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 1 day.'**
  String get reviewAheadMinimumDays;

  /// No description provided for @forgottenCards.
  ///
  /// In en, this message translates to:
  /// **'Review forgotten cards'**
  String get forgottenCards;

  /// No description provided for @forgottenCardsDays.
  ///
  /// In en, this message translates to:
  /// **'Days to look back'**
  String get forgottenCardsDays;

  /// No description provided for @previewNewCards.
  ///
  /// In en, this message translates to:
  /// **'Preview new cards'**
  String get previewNewCards;

  /// No description provided for @previewNewCardsDays.
  ///
  /// In en, this message translates to:
  /// **'Days since added'**
  String get previewNewCardsDays;

  /// No description provided for @customStudyNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards matched the criteria you provided.'**
  String get customStudyNoCards;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
