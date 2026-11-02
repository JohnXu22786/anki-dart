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
 * List cases are adapted from AddonModelTest.kt and test-js-addon.json in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('getAddonModelListFromAddonData', () {
    test('keeps valid and invalid fixture results and callbacks in order', () {
      final callbackErrors = <List<String>>[];
      final result = getAddonModelListFromAddonData(
        [
          _progressBarAddon,
          _data(
            addonType: 'invalid-type',
            keywords: ['other'],
            ankidroidJsApi: '0.0.2',
          ),
          _validAddon,
          _data(name: null),
        ],
        lowercase: (value) => value.toLowerCase(),
        urlEncode: (value) => value,
        logInfo: (_) {},
        logInvalidAddon: callbackErrors.add,
      );

      expect(result.addonModels.map((addon) => addon.name), [
        'ankidroid-js-addon-progress-bar',
        'valid-ankidroid-js-addon-test',
      ]);
      expect(result.addonModels.map((addon) => addon.dist!.tarball), [
        'https://registry.npmjs.org/ankidroid-js-addon-progress-bar/-/ankidroid-js-addon-progress-bar-1.1.1.tgz',
        'https://registry.npmjs.org/valid-ankidroid-js-addon-test/-/valid-ankidroid-js-addon-test-1.0.1.tgz',
      ]);
      const firstErrors = [
        "Invalid addon package: invalid-type is not valid addon type, package.json must have 'addonType' fields of 'reviewer' or 'note-editor'",
        "Invalid addon package: package.json does not have 'ankidroid-js-addon' in [other] keywords",
        'Invalid addon package: supplied js api version 0.0.2 must be equal to current js api version 0.0.3',
      ];
      const secondErrors = [
        'Invalid addon package: fields in package.json are empty or null',
      ];
      expect(result.errors, [...firstErrors, ...secondErrors]);
      expect(callbackErrors, [firstErrors, secondErrors]);
    });

    test('returns empty lists and does not log for empty input', () {
      final callbackErrors = <List<String>>[];
      final result = getAddonModelListFromAddonData(
        const <AddonData>[],
        lowercase: (value) => value.toLowerCase(),
        urlEncode: (value) => value,
        logInfo: (_) {},
        logInvalidAddon: callbackErrors.add,
      );

      expect(result.addonModels, isEmpty);
      expect(result.errors, isEmpty);
      expect(callbackErrors, isEmpty);
    });

    test('propagates a list logging callback exception unchanged', () {
      final failure = StateError('list logging failed');
      expect(
        () => getAddonModelListFromAddonData(
          [_data(name: null), _validAddon],
          lowercase: (value) => value.toLowerCase(),
          urlEncode: (value) => value,
          logInfo: (_) {},
          logInvalidAddon: (_) => throw failure,
        ),
        throwsA(same(failure)),
      );
    });
  });
}

const _progressBarAddon = AddonData(
  name: 'ankidroid-js-addon-progress-bar',
  addonTitle: 'Progress Bar',
  version: '1.1.1',
  description:
      'Show progress bar in AnkiDroid, this package may not be used in node_modules. For using this addon view. https://github.com/ankidroid/Anki-Android/pull/9232',
  main: 'index.js',
  ankidroidJsApi: '0.0.3',
  addonType: reviewerAddon,
  keywords: ['ankidroid-js-addon'],
  author: {
    'name': 'krmanik',
    'email': 'infinyte01@gmail.com',
    'url': 'https://krmanik.github.io',
  },
  license: 'MIT',
  homepage: 'https://github.com/krmanik/Anki-Custom-Card-Layout#readme',
  dist: DistInfo(
    'https://registry.npmjs.org/ankidroid-js-addon-progress-bar/-/ankidroid-js-addon-progress-bar-1.1.1.tgz',
  ),
);

const _validAddon = AddonData(
  name: 'valid-ankidroid-js-addon-test',
  addonTitle: 'Valid AnkiDroid JS Addon',
  version: '1.0.1',
  description:
      'This addon will listed in Addon Browser. Also AddonInfo.isValidAnkiDroidAddon return true for this package. For more view. https://github.com/ankidroid/Anki-Android/pull/9232',
  main: 'index.js',
  ankidroidJsApi: '0.0.3',
  addonType: reviewerAddon,
  keywords: ['ankidroid-js-addon'],
  author: {
    'name': 'krmanik',
    'email': 'infinyte01@gmail.com',
    'url': 'https://krmanik.github.io',
  },
  license: 'MIT',
  homepage: 'https://github.com/ankidroid/ankidroid-js-addon#readme',
  dist: DistInfo(
    'https://registry.npmjs.org/valid-ankidroid-js-addon-test/-/valid-ankidroid-js-addon-test-1.0.1.tgz',
  ),
);

AddonData _data({
  String? name = 'valid-ankidroid-js-addon-test',
  String? addonType = reviewerAddon,
  List<String>? keywords = const ['ankidroid-js-addon'],
  String? ankidroidJsApi = '0.0.3',
}) => AddonData(
  name: name,
  addonTitle: 'Valid AnkiDroid JS Addon',
  icon: '',
  version: '1.0.0',
  description: 'A test addon',
  main: 'index.js',
  ankidroidJsApi: ankidroidJsApi,
  addonType: addonType,
  keywords: keywords,
  author: const {'name': 'AnkiDroid'},
  license: 'MIT',
  homepage: 'https://example.com',
  dist: const DistInfo('https://example.com/addon.tgz'),
);
