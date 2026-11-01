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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Direct pure cases adapted from AddonModelTest.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md. Host file/JSON/network cases remain host-side.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('getAddonModelFromAddonData', () {
    test('projects reviewer values and defaults optional metadata', () {
      final result = _project(
        _data(description: null, author: null, license: null),
      );
      expect(result, isA<AddonValidationResultValid>());
      final addon = (result as AddonValidationResultValid).addonModel;
      expect(addon.name, 'valid-ankidroid-js-addon-test');
      expect(addon.addonTitle, 'Valid AnkiDroid JS Addon');
      expect(addon.icon, '');
      expect(addon.version, '1.0.0');
      expect(addon.main, 'index.js');
      expect(addon.ankidroidJsApi, currentJsApiVersion);
      expect(addon.addonType, reviewerAddon);
      expect(addon.keywords, ['ankidroid-js-addon']);
      expect(addon.description, '');
      expect(addon.author, isEmpty);
      expect(addon.license, '');
      expect(addon.homepage, 'https://example.com');
      expect(addon.dist, const DistInfo('https://example.com/addon.tgz'));
    });

    test('projects note-editor icon and nullable registry dist', () {
      final result = _project(
        _data(icon: '✎', addonType: noteEditorAddon, dist: null),
      );
      expect(result, isA<AddonValidationResultValid>());
      final addon = (result as AddonValidationResultValid).addonModel;
      expect(addon.icon, '✎');
      expect(addon.dist, isNull);
    });

    test(
      'returns one early error for absent or Kotlin-blank required data',
      () {
        for (final data in [
          _data(name: null),
          _data(name: ' \u00a0\u2007'),
          _data(addonTitle: ' \u2007'),
          _data(main: ' \u00a0'),
          _data(version: '\u2007'),
          _data(ankidroidJsApi: ' \u2007'),
          _data(addonType: '\u2007'),
          _data(homepage: '\u00a0'),
          _data(addonTitle: null),
          _data(main: null),
          _data(version: null),
          _data(ankidroidJsApi: null),
          _data(addonType: null),
          _data(homepage: null),
          _data(keywords: null),
          _data(keywords: []),
        ]) {
          var callbackCalled = false;
          final result = getAddonModelFromAddonData(
            data,
            lowercase: (value) {
              callbackCalled = true;
              return value;
            },
            urlEncode: (value) => value,
            logInfo: (_) {},
          );
          expect(
            result,
            const AddonValidationResultInvalid([
              'Invalid addon package: fields in package.json are empty or null',
            ]),
          );
          expect(callbackCalled, isFalse);
        }
      },
    );

    test('accumulates post-guard validation errors in source order', () {
      final logs = <String>[];
      final result = _project(
        _data(
          name: 'BadName',
          addonType: 'invalid-type',
          keywords: ['other'],
          ankidroidJsApi: '0.0.2',
        ),
        logInfo: logs.add,
      );
      expect(
        result,
        const AddonValidationResultInvalid([
          'Invalid addon package: package name failed validation',
          "Invalid addon package: invalid-type is not valid addon type, package.json must have 'addonType' fields of 'reviewer' or 'note-editor'",
          "Invalid addon package: package.json does not have 'ankidroid-js-addon' in [other] keywords",
          'Invalid addon package: supplied js api version 0.0.2 must be equal to current js api version 0.0.3',
        ]),
      );
      expect(logs, ['Invalid package name: only small letters allowed']);
    });

    test(
      'requires a nonblank icon for note-editor and forwards callback errors',
      () {
        final result = _project(
          _data(icon: '\u2007', addonType: noteEditorAddon),
        );
        expect(
          result,
          const AddonValidationResultInvalid([
            "Invalid addon package: note editor addon must have 'icon' fields in package.json",
          ]),
        );

        final failure = StateError('lowercase failed');
        expect(
          () => getAddonModelFromAddonData(
            _data(),
            lowercase: (_) => throw failure,
            urlEncode: (value) => value,
            logInfo: (_) {},
          ),
          throwsA(same(failure)),
        );
      },
    );
  });

  test(
    'models and result variants retain Kotlin data-class value semantics',
    () {
      const dist = DistInfo('https://example.com/addon.tgz');
      const sameDist = DistInfo('https://example.com/addon.tgz');
      expect(dist, sameDist);
      expect(dist.hashCode, sameDist.hashCode);

      final first = _project(
        _data(keywords: ['ankidroid-js-addon'], author: {'name': 'AnkiDroid'}),
      );
      final second = _project(
        _data(keywords: ['ankidroid-js-addon'], author: {'name': 'AnkiDroid'}),
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);

      const invalid = AddonValidationResultInvalid(['reason']);
      const sameInvalid = AddonValidationResultInvalid(['reason']);
      expect(invalid, sameInvalid);
      expect(invalid.hashCode, sameInvalid.hashCode);
    },
  );
}

AddonValidationResult _project(
  AddonData data, {
  void Function(String message) logInfo = _ignoreLog,
}) => getAddonModelFromAddonData(
  data,
  lowercase: (value) => value.toLowerCase(),
  urlEncode: (value) => value,
  logInfo: logInfo,
);

void _ignoreLog(String _) {}

AddonData _data({
  String? name = 'valid-ankidroid-js-addon-test',
  String? addonTitle = 'Valid AnkiDroid JS Addon',
  String? icon = '',
  String? version = '1.0.0',
  String? description = 'A test addon',
  String? main = 'index.js',
  String? ankidroidJsApi = currentJsApiVersion,
  String? addonType = reviewerAddon,
  List<String>? keywords = const ['ankidroid-js-addon'],
  Map<String, String>? author = const {'name': 'AnkiDroid'},
  String? license = 'MIT',
  String? homepage = 'https://example.com',
  DistInfo? dist = const DistInfo('https://example.com/addon.tgz'),
}) => AddonData(
  name: name,
  addonTitle: addonTitle,
  icon: icon,
  version: version,
  description: description,
  main: main,
  ankidroidJsApi: ankidroidJsApi,
  addonType: addonType,
  keywords: keywords,
  author: author,
  license: license,
  homepage: homepage,
  dist: dist,
);
