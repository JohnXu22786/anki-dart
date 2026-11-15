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
 * Behavioral reference: HttpFetcher.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('HttpFetcher request configuration', () {
    test(
      'uses the source timeout value and seconds unit for every timeout',
      () {
        final configuration = httpFetcherRequestConfiguration(
          fakeUserAgent: true,
          packageVersionName: 'host-version',
        );

        expect(configuration.connectTimeout.value, 30000);
        expect(
          configuration.connectTimeout.unit,
          HttpFetcherTimeoutUnit.seconds,
        );
        expect(configuration.writeTimeout.value, 30000);
        expect(configuration.writeTimeout.unit, HttpFetcherTimeoutUnit.seconds);
        expect(configuration.readTimeout.value, 30000);
        expect(configuration.readTimeout.unit, HttpFetcherTimeoutUnit.seconds);
      },
    );

    test('keeps fake user-agent headers in source order and exact text', () {
      final configuration = httpFetcherRequestConfiguration(
        fakeUserAgent: true,
        packageVersionName: 'host-version',
      );

      expect(configuration.headers, [
        (name: 'Referer', value: 'com.ichi2.anki'),
        (name: 'User-Agent', value: 'Mozilla/5.0 ( compatible ) '),
        (name: 'Accept', value: '*/*'),
      ]);
    });

    test(
      'uses only the host-version User-Agent when fake mode is disabled',
      () {
        final configuration = httpFetcherRequestConfiguration(
          fakeUserAgent: false,
          packageVersionName: '8.2.1',
        );

        expect(configuration.headers, [
          (name: 'User-Agent', value: 'AnkiDroid-8.2.1'),
        ]);
      },
    );
  });
}
