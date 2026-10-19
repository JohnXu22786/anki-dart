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
 * Behavioral reference: CardTemplate.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The rendered HTML value returned by AnkiDroid's CardTemplate projection.
final class RenderedCard {
  const RenderedCard(this.html);

  final String html;

  @override
  bool operator ==(Object other) => other is RenderedCard && other.html == html;

  @override
  int get hashCode => html.hashCode;
}

/// Caches the source template's five regions around its first section markers.
///
/// The host supplies the template string and replacement values. Loading the
/// Android asset, rendering card content, and WebView integration remain
/// outside this model.
final class CardTemplate {
  factory CardTemplate(String template) {
    const styleDelimiter = '::style::';
    const scriptDelimiter = '::script::';
    const classDelimiter = '::class::';
    const contentDelimiter = '::content::';

    final styleIndex = template.indexOf(styleDelimiter);
    final scriptIndex = template.indexOf(scriptDelimiter);
    final classIndex = template.indexOf(classDelimiter);
    final contentIndex = template.indexOf(contentDelimiter);

    // Kotlin's String.take(-1) throws IllegalArgumentException before entering
    // the later substring catch. ArgumentError preserves that failure boundary.
    if (styleIndex < 0) {
      throw ArgumentError.value(styleIndex, 'styleIndex');
    }

    final preStyle = template.substring(0, styleIndex);
    try {
      return CardTemplate._(
        preStyle: preStyle,
        preScript: template.substring(
          styleIndex + styleDelimiter.length,
          scriptIndex,
        ),
        preClass: template.substring(
          scriptIndex + scriptDelimiter.length,
          classIndex,
        ),
        preContent: template.substring(
          classIndex + classDelimiter.length,
          contentIndex,
        ),
        postContent: template.substring(contentIndex + contentDelimiter.length),
      );
    } on RangeError {
      // Kotlin wraps StringIndexOutOfBoundsException from these substrings.
      throw StateError(
        'The card template had replacement string order, or content changed',
      );
    }
  }

  const CardTemplate._({
    required String preStyle,
    required String preScript,
    required String preClass,
    required String preContent,
    required String postContent,
  })  : _preStyle = preStyle,
        _preScript = preScript,
        _preClass = preClass,
        _preContent = preContent,
        _postContent = postContent;

  final String _preStyle;
  final String _preScript;
  final String _preClass;
  final String _preContent;
  final String _postContent;

  /// Inserts section values into the cached source-order segments.
  RenderedCard render({
    required String content,
    required String style,
    required String script,
    required String cardClass,
  }) =>
      RenderedCard(
        '$_preStyle$style$_preScript$script$_preClass$cardClass'
        '$_preContent$content$_postContent',
      );
}
