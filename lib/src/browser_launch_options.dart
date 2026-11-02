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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardBrowserLaunchOptions.kt in AnkiDroid 2.25.3;
 * see ANKIIDROID_UPSTREAM.md. Android Intent/extras/action and navigation
 * remain host-side; [browserLaunchOptionFromUriString] projects URI search.
 */

/// One source-equivalent way to open AnkiDroid's Card Browser.
sealed class BrowserLaunchOption {
  const BrowserLaunchOption();
}

/// Opens the browser with the `search` query parameter from a deep link.
final class BrowserLaunchDeepLink extends BrowserLaunchOption {
  const BrowserLaunchDeepLink(this.search);

  final String search;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchDeepLink && other.search == search;

  @override
  int get hashCode => search.hashCode;
}

/// Opens the browser with the search supplied by the JavaScript API.
final class BrowserLaunchSearchQueryJs extends BrowserLaunchOption {
  const BrowserLaunchSearchQueryJs(this.search, {required this.allDecks});

  final String search;
  final bool allDecks;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchSearchQueryJs &&
      other.search == search &&
      other.allDecks == allDecks;

  @override
  int get hashCode => Object.hash(search, allDecks);
}

/// Opens the browser scrolled to the host-resolved card ID.
final class BrowserLaunchScrollToCard extends BrowserLaunchOption {
  const BrowserLaunchScrollToCard(this.cardId);

  final int cardId;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchScrollToCard && other.cardId == cardId;

  @override
  int get hashCode => cardId.hashCode;
}

/// Opens the browser with text passed through the system process-text action.
final class BrowserLaunchSystemContextMenu extends BrowserLaunchOption {
  const BrowserLaunchSystemContextMenu(this.search);

  final String search;

  @override
  bool operator ==(Object other) =>
      other is BrowserLaunchSystemContextMenu && other.search == search;

  @override
  int get hashCode => search.hashCode;
}

/// Projects host-decoded intent fields to the source launch option.
///
/// Arguments are already extracted by the host from Android `Intent` and `Uri`
/// APIs. Their order here matches `toCardBrowserLaunchOptions()`: deep-link
/// search, JavaScript search, card ID, then non-empty process text for the
/// process-text action. A null search means absent; an empty deep-link or
/// JavaScript search is still present. Missing `all_decks` is represented by
/// [allDecks]'s false default. [cardId] is an already decoded signed 64-bit ID
/// on Android hosts; this platform-independent API does not inspect extras.
BrowserLaunchOption? browserLaunchOptionFromInput({
  String? deepLinkSearch,
  String? searchQueryJs,
  bool allDecks = false,
  int? cardId,
  bool actionIsProcessText = false,
  String? processTextSearch,
}) {
  if (deepLinkSearch != null) {
    return BrowserLaunchDeepLink(deepLinkSearch);
  }

  if (searchQueryJs != null) {
    return BrowserLaunchSearchQueryJs(searchQueryJs, allDecks: allDecks);
  }

  if (cardId != null) {
    return BrowserLaunchScrollToCard(cardId);
  }

  if (actionIsProcessText &&
      processTextSearch != null &&
      processTextSearch.isNotEmpty) {
    return BrowserLaunchSystemContextMenu(processTextSearch);
  }

  return null;
}

/// Extracts Android's Card Browser `search` deep-link value from a raw URI.
///
/// The raw string is required because Dart's [Uri] canonicalizes escaped
/// unreserved query-key characters, while Android compares the encoded key
/// literally. This matches Android for hierarchical URIs whose encoded search
/// value is well-formed UTF-8. Opaque URIs throw [UnsupportedError], like
/// `android.net.Uri.getQueryParameter`; malformed percent escapes and invalid
/// UTF-8 throw [FormatException] instead of being normalized. Android replaces
/// malformed input with U+FFFD, so that malformed-input domain is intentionally
/// outside this helper's equivalence guarantee.
String? browserDeepLinkSearchFromUriString(String uriString) {
  Uri.parse(uriString);
  final scheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').firstMatch(uriString);
  if (scheme != null && !uriString.substring(scheme.end).startsWith('/')) {
    throw UnsupportedError('This is not a hierarchical URI.');
  }

  final queryStart = uriString.indexOf('?');
  final fragmentStart = uriString.indexOf('#');
  if (queryStart == -1 || (fragmentStart != -1 && fragmentStart < queryStart)) {
    return null;
  }

  final queryEnd = fragmentStart == -1 ? uriString.length : fragmentStart;
  final query = uriString.substring(queryStart + 1, queryEnd);
  var start = 0;
  while (start <= query.length) {
    final ampersand = query.indexOf('&', start);
    final end = ampersand == -1 ? query.length : ampersand;
    final equals = query.indexOf('=', start);
    final nameEnd = equals == -1 || equals > end ? end : equals;

    if (query.substring(start, nameEnd) == 'search') {
      if (nameEnd == end) {
        return '';
      }
      final encodedValue = query.substring(nameEnd + 1, end);
      try {
        return Uri.decodeQueryComponent(encodedValue);
      } on ArgumentError {
        throw FormatException('Invalid encoded search value.', uriString);
      }
    }

    if (ampersand == -1) {
      return null;
    }
    start = ampersand + 1;
  }

  return null;
}

/// Projects a raw deep-link URI and host-extracted fields in source order.
///
/// The URI is only used for the source's `search` query extraction. Android
/// `Intent`, extras, process-text action and navigation remain host-owned.
BrowserLaunchOption? browserLaunchOptionFromUriString({
  String? deepLinkUri,
  String? searchQueryJs,
  bool allDecks = false,
  int? cardId,
  bool actionIsProcessText = false,
  String? processTextSearch,
}) => browserLaunchOptionFromInput(
  deepLinkSearch: deepLinkUri == null
      ? null
      : browserDeepLinkSearchFromUriString(deepLinkUri),
  searchQueryJs: searchQueryJs,
  allDecks: allDecks,
  cardId: cardId,
  actionIsProcessText: actionIsProcessText,
  processTextSearch: processTextSearch,
);
