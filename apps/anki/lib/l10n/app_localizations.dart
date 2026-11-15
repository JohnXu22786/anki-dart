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
