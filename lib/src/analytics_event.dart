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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from AnalyticsEvent.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The closed set of events AnkiDroid reports to analytics.
///
/// Category and action strings are version-stable analytics values.
sealed class AnalyticsEvent {
  /// Creates an event with its fixed analytics projection.
  const AnalyticsEvent({
    required this.category,
    required this.action,
    this.label,
    this.value,
  });

  /// The event category reported to analytics.
  final String category;

  /// The event action reported to analytics.
  final String action;

  /// Optional event label.
  final String? label;

  /// Optional numeric event value.
  final int? value;
}

/// Everything reported under the `LinkClicked` category.
///
/// These action strings are compared between AnkiDroid versions and must not
/// change. The import entries intentionally remain under `LinkClicked`.
enum LinkAction {
  openedHelpDialog('Opened HelpDialogBox'),
  openedUsingAnkiDroid('Opened Using AnkiDroid'),
  openedGetHelp('Opened Get Help'),
  openedSupportAnkiDroid('Opened Support AnkiDroid'),
  openedCommunity('Opened Community'),
  openedPrivacy('Opened Privacy'),
  openedAnkiWebTermsAndConditions('Opened AnkiWeb Terms and Conditions'),
  openedAnkiDroidPrivacyPolicy('Opened AnkiDroid Privacy Policy'),
  openedAnkiWebPrivacyPolicy('Opened AnkiWeb Privacy Policy'),
  openedAnkiDroidManual('Opened AnkiDroid Manual'),
  openedAnkiManual('Opened Anki Manual'),
  openedAnkiDroidFaq('Opened AnkiDroid FAQ'),
  openedMailingList('Opened Mailing List'),
  openedReportBug('Opened Report a Bug'),
  openedDonate('Opened Donate'),
  openedTranslate('Opened Translate'),
  openedDevelop('Opened Develop'),
  openedRate('Opened Rate'),
  openedOther('Opened Other'),
  openedSendFeedback('Opened Send Feedback'),
  openedAnkiForums('Opened Anki Forums'),
  openedReddit('Opened Reddit'),
  openedDiscord('Opened Discord'),
  openedFacebook('Opened Facebook'),
  openedTwitter('Opened Twitter'),
  exceptionReport('Exception Report'),
  importApkgFile('Import APKG'),
  importColpkgFile('Import COLPKG'),
  importCsvFile('Import CSV');

  const LinkAction(this.action);

  /// The exact action string reported to analytics.
  final String action;
}

/// The user followed a link or menu entry, for example in the help dialog.
final class LinkClicked extends AnalyticsEvent {
  /// Creates a link-click event.
  LinkClicked(this.link) : super(category: 'LinkClicked', action: link.action);

  /// Link action whose pinned string is reported as this event's action.
  final LinkAction link;

  @override
  bool operator ==(Object other) => other is LinkClicked && other.link == link;

  @override
  int get hashCode => Object.hash(runtimeType, link);
}

/// A settings row was tapped. [key] is null for preferences without one.
final class SettingTapped extends AnalyticsEvent {
  /// Creates a settings-row tap event.
  const SettingTapped(this.key)
    : super(category: 'Setting', action: 'Tapped setting', label: key);

  /// Preference key, when the tapped row has one.
  final String? key;

  @override
  bool operator ==(Object other) => other is SettingTapped && other.key == key;

  @override
  int get hashCode => Object.hash(runtimeType, key);
}

/// A reportable preference changed. [newValue] is null when it is not numeric.
final class SettingChanged extends AnalyticsEvent {
  /// Creates a settings-change event.
  const SettingChanged(this.key, this.newValue)
    : super(
        category: 'Setting',
        action: 'Changed setting',
        label: key,
        value: newValue,
      );

  /// Preference key.
  final String key;

  /// Numeric preference value, when available.
  final int? newValue;

  @override
  bool operator ==(Object other) =>
      other is SettingChanged && other.key == key && other.newValue == newValue;

  @override
  int get hashCode => Object.hash(runtimeType, key, newValue);
}

/// ACRA handled a crash. [installId] matches this hit to the ACRA report.
final class CrashReported extends AnalyticsEvent {
  /// Creates a crash-report event.
  const CrashReported(this.installId)
    : super(
        category: 'ACRA Crash Handler',
        action: 'Crash reported',
        label: installId,
      );

  /// Install ID used to match this hit to the ACRA report.
  final String installId;

  @override
  bool operator ==(Object other) =>
      other is CrashReported && other.installId == installId;

  @override
  int get hashCode => Object.hash(runtimeType, installId);
}

/// A home-screen widget was added. [widgetName] is the provider class name.
final class WidgetEnabled extends AnalyticsEvent {
  /// Creates a widget-enabled event.
  const WidgetEnabled(this.widgetName)
    : super(category: 'Widget', action: 'enabled', label: widgetName);

  /// Widget provider class name.
  final String widgetName;

  @override
  bool operator ==(Object other) =>
      other is WidgetEnabled && other.widgetName == widgetName;

  @override
  int get hashCode => Object.hash(runtimeType, widgetName);
}

/// The last instance of a home-screen widget was removed.
final class WidgetDisabled extends AnalyticsEvent {
  /// Creates a widget-disabled event.
  const WidgetDisabled(this.widgetName)
    : super(category: 'Widget', action: 'disabled', label: widgetName);

  /// Widget provider class name.
  final String widgetName;

  @override
  bool operator ==(Object other) =>
      other is WidgetDisabled && other.widgetName == widgetName;

  @override
  int get hashCode => Object.hash(runtimeType, widgetName);
}
