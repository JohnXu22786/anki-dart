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
 * Behavioral reference: TtsParser.kt in AnkiDroid 2.25.3.
 */

/// Host-provided DOM facts used by the portable TTS selection traversal.
///
/// [text] is the element's already-computed Jsoup-equivalent `.text()` value;
/// this type does not parse HTML or derive text from descendants.
final class TtsDomNode {
  const TtsDomNode({
    required this.tagName,
    this.service = '',
    this.voice = '',
    this.text = '',
    this.children = const [],
  });

  final String tagName;
  final String service;
  final String voice;
  final String text;
  final List<TtsDomNode> children;
}

/// Text and locale selected for host-side TTSTag construction.
final class TtsTextLocale {
  const TtsTextLocale(this.text, this.locale);

  final String text;
  final String locale;

  @override
  bool operator ==(Object other) =>
      other is TtsTextLocale && other.text == text && other.locale == locale;

  @override
  int get hashCode => Object.hash(text, locale);
}

/// Selects TTS text from a host-provided DOM projection in source order.
///
/// Matching `<tts service="android">` nodes contribute their supplied text
/// and voice and stop traversal at that node. If none match, a single item is
/// made from the host-supplied parsed body text with an empty locale. The host
/// owns HTML parsing, element text semantics, TTSTag construction, and playback.
List<TtsTextLocale> selectTtsText({
  required TtsDomNode root,
  required String bodyText,
  required String clozeReplacement,
}) {
  final selected = <TtsTextLocale>[];
  void visit(TtsDomNode node) {
    if (node.tagName.toLowerCase() == 'tts' &&
        node.service.toLowerCase() == 'android') {
      selected.add(
        TtsTextLocale(
          node.text.replaceAll('[...]', clozeReplacement),
          node.voice,
        ),
      );
      return;
    }
    for (final child in node.children) {
      visit(child);
    }
  }

  visit(root);
  if (selected.isEmpty) {
    selected.add(
      TtsTextLocale(bodyText.replaceAll('[...]', clozeReplacement), ''),
    );
  }
  return List.unmodifiable(selected);
}
