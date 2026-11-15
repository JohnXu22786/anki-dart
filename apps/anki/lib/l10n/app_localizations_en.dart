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
  String get close => 'Close';
}
