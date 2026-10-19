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
 * Behavioral reference: CardAppearance.appendCssStyle(), getCssClasses(), and
 * getCardClass() in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'java_float_format.dart';

/// Host projection of the theme predicates used by `CardAppearance`.
///
/// This records only which CSS suffix applies, not AnkiDroid's theme catalog or
/// selection state. The host maps any non-PLAIN day theme to [dayOther], exact
/// DayTheme.PLAIN to [dayPlain], any non-DARK night theme to [nightOther], and
/// exact NightTheme.DARK to [nightDark].
enum CardAppearanceThemeProjection { dayOther, dayPlain, nightOther, nightDark }

/// Appends AnkiDroid's font, card, and image zoom rules to [style].
///
/// The host supplies Android's font scale and the two preference values. Custom
/// fonts, theme classes, card rendering, and WebView integration stay outside
/// this CSS projection.
String appendCardAppearanceCss(
  String style, {
  required double fontScale,
  required int cardZoom,
  required int imageZoom,
}) {
  final css = StringBuffer(style);
  final fontScaleText = javaFloatToString(fontScale);
  if (fontScaleText != '1.0') {
    css.write('html { zoom: $fontScaleText }\n');
  }

  if (cardZoom != 100) {
    css.write('body { zoom: ${_javaPercentDouble(cardZoom)} }\n');
  }

  if (imageZoom != 100) {
    css.write('img { zoom: ${_javaPercentDouble(imageZoom)} }\n');
  }

  return css.toString();
}

/// Returns the exact theme and vertical-centering class suffix from
/// `CardAppearance.getCssClasses()`.
///
/// [centerVertically] is host-supplied preference state. Class names and
/// leading spaces are kept verbatim from the source.
String cardAppearanceCssClasses({
  required CardAppearanceThemeProjection theme,
  required bool centerVertically,
}) {
  final cssClasses = StringBuffer();
  if (centerVertically) {
    cssClasses.write(' vertically_centered');
  }

  switch (theme) {
    case CardAppearanceThemeProjection.dayOther:
      break;
    case CardAppearanceThemeProjection.dayPlain:
      cssClasses.write(' ankidroid_plain_mode');
    case CardAppearanceThemeProjection.nightOther:
      cssClasses.write(' night_mode nightMode');
    case CardAppearanceThemeProjection.nightDark:
      cssClasses.write(' night_mode nightMode ankidroid_dark_mode');
  }
  return cssClasses.toString();
}

/// Returns `card card{oneBasedCardOrdinal}` followed by the source CSS classes.
///
/// The ordinal is concatenated as supplied, matching `getCardClass()` without
/// validation. Android's render context appends MathJax classes separately.
String cardAppearanceClassName(
  int oneBasedCardOrdinal, {
  required CardAppearanceThemeProjection theme,
  required bool centerVertically,
}) =>
    'card card$oneBasedCardOrdinal'
    '${cardAppearanceCssClasses(theme: theme, centerVertically: centerVertically)}';

/// Formats the source's `Int / 100.0` result using Java Double notation.
String _javaPercentDouble(int percent) {
  final value = percent / 100.0;
  if (value.abs() < 10000000.0) return value.toString();

  final exponential = value.toStringAsExponential();
  final exponentIndex = exponential.indexOf('e');
  final significand = exponential.substring(0, exponentIndex);
  final javaSignificand =
      significand.contains('.') ? significand : '$significand.0';
  final exponent = int.parse(exponential.substring(exponentIndex + 1));
  return '${javaSignificand}E$exponent';
}
