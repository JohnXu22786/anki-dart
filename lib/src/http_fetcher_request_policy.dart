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

/// Time units used by AnkiDroid's OkHttp builder configuration.
enum HttpFetcherTimeoutUnit { seconds }

/// A timeout value and the unit supplied to the OkHttp builder.
class HttpFetcherTimeout {
  const HttpFetcherTimeout({required this.value, required this.unit});

  final int value;
  final HttpFetcherTimeoutUnit unit;
}

/// A request header retained with its insertion order.
typedef HttpFetcherRequestHeader = ({String name, String value});

/// The portable timeout and ordered-header projection of HttpFetcher.
class HttpFetcherRequestConfiguration {
  HttpFetcherRequestConfiguration({
    required this.connectTimeout,
    required this.writeTimeout,
    required this.readTimeout,
    required List<HttpFetcherRequestHeader> headers,
  }) : headers = List.unmodifiable(headers);

  final HttpFetcherTimeout connectTimeout;
  final HttpFetcherTimeout writeTimeout;
  final HttpFetcherTimeout readTimeout;
  final List<HttpFetcherRequestHeader> headers;
}

/// Projects HttpFetcher builder settings without constructing an HTTP client.
///
/// [packageVersionName] is supplied by the host where AnkiDroid reads its
/// package version. The source passes numeric timeout value 30000 to the
/// connect, write, and read timeout methods with the seconds unit.
HttpFetcherRequestConfiguration httpFetcherRequestConfiguration({
  required bool fakeUserAgent,
  required String packageVersionName,
}) {
  const timeout = HttpFetcherTimeout(
    value: 30000,
    unit: HttpFetcherTimeoutUnit.seconds,
  );
  final headers = fakeUserAgent
      ? <HttpFetcherRequestHeader>[
          (name: 'Referer', value: 'com.ichi2.anki'),
          (name: 'User-Agent', value: 'Mozilla/5.0 ( compatible ) '),
          (name: 'Accept', value: '*/*'),
        ]
      : <HttpFetcherRequestHeader>[
          (name: 'User-Agent', value: 'AnkiDroid-$packageVersionName'),
        ];

  return HttpFetcherRequestConfiguration(
    connectTimeout: timeout,
    writeTimeout: timeout,
    readTimeout: timeout,
    headers: headers,
  );
}
