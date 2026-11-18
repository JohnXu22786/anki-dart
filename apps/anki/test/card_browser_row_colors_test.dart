/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/card_browser_row_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'light and dark palettes map each semantic row color to source values',
    () {
      const expected = {
        CardBrowserRowColor.defaultColor: (0xffffffff, 0xff303030),
        CardBrowserRowColor.unknown: (0xffffffff, 0xff303030),
        CardBrowserRowColor.marked: (0xffd9b2e9, 0xff7e57c2),
        CardBrowserRowColor.suspended: (0xffff_ffb2, 0xff616161),
        CardBrowserRowColor.buried: (0xffffce7c, 0xff612b09),
        CardBrowserRowColor.flagRed: (0xffff4747, 0xffd32525),
        CardBrowserRowColor.flagOrange: (0xffffb647, 0xffbb7a17),
        CardBrowserRowColor.flagGreen: (0xff6ff06f, 0xff057a05),
        CardBrowserRowColor.flagBlue: (0xff5289ff, 0xff1a4fc2),
        CardBrowserRowColor.flagPink: (0xffff99f1, 0xffa70d64),
        CardBrowserRowColor.flagTurquoise: (0xff85ffef, 0xff138072),
        CardBrowserRowColor.flagPurple: (0xffc398ec, 0xff6320a0),
      };

      for (final entry in expected.entries) {
        expect(
          resolveCardBrowserRowColor(
            entry.key,
            _theme(Brightness.light),
          ).toARGB32(),
          entry.value.$1,
          reason: '${entry.key} light palette',
        );
        expect(
          resolveCardBrowserRowColor(
            entry.key,
            _theme(Brightness.dark),
          ).toARGB32(),
          entry.value.$2,
          reason: '${entry.key} dark palette',
        );
      }
    },
  );

  test(
    'explicit black and e-ink palettes map source colors and focus overrides',
    () {
      const black = CardBrowserPaletteTheme(CardBrowserPalette.black);
      const eink = CardBrowserPaletteTheme(CardBrowserPalette.eink);
      const expected = {
        CardBrowserRowColor.defaultColor: (0xff000000, 0xffffffff),
        CardBrowserRowColor.unknown: (0xff000000, 0xffffffff),
        CardBrowserRowColor.marked: (0xff391080, 0xffd9b2e9),
        CardBrowserRowColor.suspended: (0xffa8a634, 0xffffffb2),
        CardBrowserRowColor.buried: (0xff612b09, 0xffffce7c),
        CardBrowserRowColor.flagRed: (0xffd32525, 0xffff4747),
        CardBrowserRowColor.flagOrange: (0xffbb7a17, 0xffffb647),
        CardBrowserRowColor.flagGreen: (0xff057a05, 0xff6ff06f),
        CardBrowserRowColor.flagBlue: (0xff1a4fc2, 0xff5289ff),
        CardBrowserRowColor.flagPink: (0xffa70d64, 0xffff99f1),
        CardBrowserRowColor.flagTurquoise: (0xff138072, 0xff85ffef),
        CardBrowserRowColor.flagPurple: (0xff6320a0, 0xffc398ec),
      };
      for (final entry in expected.entries) {
        expect(
          resolveCardBrowserRowColor(
            entry.key,
            _theme(Brightness.dark, black),
          ).toARGB32(),
          entry.value.$1,
          reason: '${entry.key} black palette',
        );
        expect(
          resolveCardBrowserRowColor(
            entry.key,
            _theme(Brightness.light, eink),
          ).toARGB32(),
          entry.value.$2,
          reason: '${entry.key} e-ink palette',
        );
      }
      expect(
        resolveCardBrowserRowColor(
          CardBrowserRowColor.marked,
          _theme(Brightness.dark, black),
          focused: true,
        ).toARGB32(),
        0xff1a1a1a,
      );
      expect(
        resolveCardBrowserRowColor(
          CardBrowserRowColor.marked,
          _theme(Brightness.light, eink),
          focused: true,
        ).toARGB32(),
        0xffe0e0e0,
      );
      expect(
        resolveCardBrowserRowColor(
          CardBrowserRowColor.marked,
          _theme(Brightness.dark, black),
          focused: true,
          deleted: true,
        ).toARGB32(),
        0xff000000,
      );
    },
  );

  test('palette theme interpolation reaches the target discrete palette', () {
    const dark = CardBrowserPaletteTheme(CardBrowserPalette.dark);
    const black = CardBrowserPaletteTheme(CardBrowserPalette.black);

    expect(dark.lerp(black, 0.25).palette, CardBrowserPalette.dark);
    expect(dark.lerp(black, 0.75).palette, CardBrowserPalette.black);
    expect(dark.lerp(black, 1).palette, CardBrowserPalette.black);
  });

  test('default and unknown follow theme surface as brightness changes', () {
    final light = _theme(Brightness.light);
    final dark = _theme(Brightness.dark);
    for (final rowColor in [
      CardBrowserRowColor.defaultColor,
      CardBrowserRowColor.unknown,
    ]) {
      expect(
        resolveCardBrowserRowColor(rowColor, light),
        const Color(0xffffffff),
      );
      expect(
        resolveCardBrowserRowColor(rowColor, dark),
        const Color(0xff303030),
      );
    }
  });

  test('row foreground keeps at least 4.5:1 contrast with row backgrounds', () {
    const black = CardBrowserPaletteTheme(CardBrowserPalette.black);
    const eink = CardBrowserPaletteTheme(CardBrowserPalette.eink);
    final themes = [
      _theme(Brightness.light),
      _theme(Brightness.dark),
      _theme(Brightness.dark, black),
      _theme(Brightness.light, eink),
    ];
    for (final theme in themes) {
      for (final rowColor in CardBrowserRowColor.values) {
        final background = resolveCardBrowserRowColor(rowColor, theme);
        final text = resolveCardBrowserRowForegroundColor(rowColor, theme);
        expect(
          _contrast(text, background),
          greaterThanOrEqualTo(4.5),
          reason: '${rowColor.name} with ${theme.brightness} brightness',
        );
      }
    }
  });
}

ThemeData _theme(Brightness brightness, [CardBrowserPaletteTheme? palette]) =>
    ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xffffffff)
          : const Color(0xff303030),
      extensions: [?palette],
    );

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
