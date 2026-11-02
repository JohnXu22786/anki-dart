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

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('pins each event type and its exact analytics projection', () {
      final events = <AnalyticsEvent>[
        LinkClicked(LinkAction.openedDonate),
        SettingTapped('prefKey'),
        SettingChanged('prefKey', 3),
        CrashReported('installId'),
        WidgetEnabled('SomeWidget'),
        WidgetDisabled('SomeWidget'),
      ];

      expect(events.map(_eventType).toList(), [
        LinkClicked,
        SettingTapped,
        SettingChanged,
        CrashReported,
        WidgetEnabled,
        WidgetDisabled,
      ]);
      expect(
        events
            .map(
              (event) => [
                event.category,
                event.action,
                event.label,
                event.value,
              ],
            )
            .toList(),
        [
          ['LinkClicked', 'Opened Donate', null, null],
          ['Setting', 'Tapped setting', 'prefKey', null],
          ['Setting', 'Changed setting', 'prefKey', 3],
          ['ACRA Crash Handler', 'Crash reported', 'installId', null],
          ['Widget', 'enabled', 'SomeWidget', null],
          ['Widget', 'disabled', 'SomeWidget', null],
        ],
      );
    });

    test('runtime data never changes category or action', () {
      final variants = <(AnalyticsEvent, AnalyticsEvent)>[
        (SettingTapped('a'), SettingTapped('b')),
        (SettingChanged('a', 1), SettingChanged('b', 2)),
        (CrashReported('a'), CrashReported('b')),
        (WidgetEnabled('a'), WidgetEnabled('b')),
        (WidgetDisabled('a'), WidgetDisabled('b')),
      ];

      for (final (first, second) in variants) {
        expect(first.category, second.category);
        expect(first.action, second.action);
      }
    });

    test('preserves value equality and hash behavior of each data event', () {
      final pairs = <(AnalyticsEvent, AnalyticsEvent)>[
        (
          LinkClicked(LinkAction.openedDonate),
          LinkClicked(LinkAction.openedDonate),
        ),
        (SettingTapped('key'), SettingTapped('key')),
        (SettingChanged('key', 3), SettingChanged('key', 3)),
        (CrashReported('install'), CrashReported('install')),
        (WidgetEnabled('widget'), WidgetEnabled('widget')),
        (WidgetDisabled('widget'), WidgetDisabled('widget')),
      ];

      for (final (first, second) in pairs) {
        expect(first, second);
        expect(first.hashCode, second.hashCode);
      }
      expect(SettingTapped('a'), isNot(SettingTapped('b')));
      expect(SettingChanged('key', 1), isNot(SettingChanged('key', 2)));
      expect(
        LinkClicked(LinkAction.openedDonate),
        isNot(LinkClicked(LinkAction.openedHelpDialog)),
      );
    });

    test('retains null defaults and nullable setting data', () {
      final tapped = SettingTapped(null);
      final changed = SettingChanged('key', null);

      expect([tapped.label, tapped.value], [null, null]);
      expect([changed.label, changed.value], ['key', null]);
    });
  });

  test('pins every LinkAction name and exact action string', () {
    const expected = <LinkAction, String>{
      LinkAction.openedHelpDialog: 'Opened HelpDialogBox',
      LinkAction.openedUsingAnkiDroid: 'Opened Using AnkiDroid',
      LinkAction.openedGetHelp: 'Opened Get Help',
      LinkAction.openedSupportAnkiDroid: 'Opened Support AnkiDroid',
      LinkAction.openedCommunity: 'Opened Community',
      LinkAction.openedPrivacy: 'Opened Privacy',
      LinkAction.openedAnkiWebTermsAndConditions:
          'Opened AnkiWeb Terms and Conditions',
      LinkAction.openedAnkiDroidPrivacyPolicy:
          'Opened AnkiDroid Privacy Policy',
      LinkAction.openedAnkiWebPrivacyPolicy: 'Opened AnkiWeb Privacy Policy',
      LinkAction.openedAnkiDroidManual: 'Opened AnkiDroid Manual',
      LinkAction.openedAnkiManual: 'Opened Anki Manual',
      LinkAction.openedAnkiDroidFaq: 'Opened AnkiDroid FAQ',
      LinkAction.openedMailingList: 'Opened Mailing List',
      LinkAction.openedReportBug: 'Opened Report a Bug',
      LinkAction.openedDonate: 'Opened Donate',
      LinkAction.openedTranslate: 'Opened Translate',
      LinkAction.openedDevelop: 'Opened Develop',
      LinkAction.openedRate: 'Opened Rate',
      LinkAction.openedOther: 'Opened Other',
      LinkAction.openedSendFeedback: 'Opened Send Feedback',
      LinkAction.openedAnkiForums: 'Opened Anki Forums',
      LinkAction.openedReddit: 'Opened Reddit',
      LinkAction.openedDiscord: 'Opened Discord',
      LinkAction.openedFacebook: 'Opened Facebook',
      LinkAction.openedTwitter: 'Opened Twitter',
      LinkAction.exceptionReport: 'Exception Report',
      LinkAction.importApkgFile: 'Import APKG',
      LinkAction.importColpkgFile: 'Import COLPKG',
      LinkAction.importCsvFile: 'Import CSV',
    };

    expect(LinkAction.values.length, 29);
    expect({
      for (final action in LinkAction.values) action: action.action,
    }, expected);
  });
}

Type _eventType(AnalyticsEvent event) => switch (event) {
  LinkClicked() => LinkClicked,
  SettingTapped() => SettingTapped,
  SettingChanged() => SettingChanged,
  CrashReported() => CrashReported,
  WidgetEnabled() => WidgetEnabled,
  WidgetDisabled() => WidgetDisabled,
};
