/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';

/// Semantic colors projected by Anki Core's Card Browser rows.
enum CardBrowserRowColor {
  defaultColor,
  unknown,
  marked,
  suspended,
  buried,
  flagRed,
  flagOrange,
  flagGreen,
  flagBlue,
  flagPink,
  flagTurquoise,
  flagPurple,
}

/// The native AnkiDroid palettes that can be projected into Flutter themes.
///
/// Brightness alone selects light or dark. Black and e-ink are opt-in because
/// Flutter has no standard way to distinguish them from dark or light themes.
enum CardBrowserPalette { light, dark, black, eink }

/// Theme configuration for matching AnkiDroid's optional palettes.
final class CardBrowserPaletteTheme
    extends ThemeExtension<CardBrowserPaletteTheme> {
  const CardBrowserPaletteTheme(this.palette);

  final CardBrowserPalette palette;

  @override
  CardBrowserPaletteTheme copyWith({CardBrowserPalette? palette}) =>
      CardBrowserPaletteTheme(palette ?? this.palette);

  @override
  CardBrowserPaletteTheme lerp(
    covariant ThemeExtension<CardBrowserPaletteTheme>? other,
    double t,
  ) => other is CardBrowserPaletteTheme && t >= 0.5 ? other : this;
}

/// Resolves AnkiDroid 2.25.3's row colors for the given Flutter theme.
///
/// [focused] represents AnkiDroid's focused pane row, which takes precedence
/// over backend semantic color. Deleted rows are rendered as unknown/default.
Color resolveCardBrowserRowColor(
  CardBrowserRowColor rowColor,
  ThemeData theme, {
  bool focused = false,
  bool deleted = false,
}) {
  final palette =
      theme.extension<CardBrowserPaletteTheme>()?.palette ??
      (theme.brightness == Brightness.dark
          ? CardBrowserPalette.dark
          : CardBrowserPalette.light);
  if (deleted) return _backgroundColor(palette);
  if (focused) return _focusedColor(palette);
  if (rowColor == CardBrowserRowColor.defaultColor ||
      rowColor == CardBrowserRowColor.unknown) {
    return _backgroundColor(palette);
  }

  return switch (rowColor) {
    CardBrowserRowColor.defaultColor ||
    CardBrowserRowColor.unknown => _backgroundColor(palette),
    CardBrowserRowColor.marked => switch (palette) {
      CardBrowserPalette.light ||
      CardBrowserPalette.eink => const Color(0xffd9b2e9),
      CardBrowserPalette.dark => const Color(0xff7e57c2),
      CardBrowserPalette.black => const Color(0xff391080),
    },
    CardBrowserRowColor.suspended => switch (palette) {
      CardBrowserPalette.light ||
      CardBrowserPalette.eink => const Color(0xffffffb2),
      CardBrowserPalette.dark => const Color(0xff616161),
      CardBrowserPalette.black => const Color(0xffa8a634),
    },
    CardBrowserRowColor.buried => switch (palette) {
      CardBrowserPalette.light ||
      CardBrowserPalette.eink => const Color(0xffffce7c),
      CardBrowserPalette.dark => const Color(0xff612b09),
      CardBrowserPalette.black => const Color(0xff612b09),
    },
    CardBrowserRowColor.flagRed => _flagColor(palette, 0xffff4747, 0xffd32525),
    CardBrowserRowColor.flagOrange => _flagColor(
      palette,
      0xffffb647,
      0xffbb7a17,
    ),
    CardBrowserRowColor.flagGreen => _flagColor(
      palette,
      0xff6ff06f,
      0xff057a05,
    ),
    CardBrowserRowColor.flagBlue => _flagColor(palette, 0xff5289ff, 0xff1a4fc2),
    CardBrowserRowColor.flagPink => _flagColor(palette, 0xffff99f1, 0xffa70d64),
    CardBrowserRowColor.flagTurquoise => _flagColor(
      palette,
      0xff85ffef,
      0xff138072,
    ),
    CardBrowserRowColor.flagPurple => _flagColor(
      palette,
      0xffc398ec,
      0xff6320a0,
    ),
  };
}

/// Chooses readable row text while keeping source background colors unchanged.
Color resolveCardBrowserRowForegroundColor(
  CardBrowserRowColor rowColor,
  ThemeData theme, {
  bool focused = false,
  bool deleted = false,
}) {
  if (focused ||
      deleted ||
      rowColor == CardBrowserRowColor.defaultColor ||
      rowColor == CardBrowserRowColor.unknown) {
    return theme.colorScheme.onSurface;
  }
  final background = resolveCardBrowserRowColor(
    rowColor,
    theme,
    focused: focused,
    deleted: deleted,
  );
  final blackContrast = _contrast(Colors.black, background);
  final whiteContrast = _contrast(Colors.white, background);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

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

Color _flagColor(CardBrowserPalette palette, int light, int dark) =>
    Color(switch (palette) {
      CardBrowserPalette.light || CardBrowserPalette.eink => light,
      CardBrowserPalette.dark || CardBrowserPalette.black => dark,
    });

Color _backgroundColor(CardBrowserPalette palette) => switch (palette) {
  CardBrowserPalette.light => const Color(0xffffffff),
  CardBrowserPalette.dark => const Color(0xff303030),
  CardBrowserPalette.black => const Color(0xff000000),
  CardBrowserPalette.eink => const Color(0xffffffff),
};

Color _focusedColor(CardBrowserPalette palette) => switch (palette) {
  CardBrowserPalette.light => const Color(0xffececec),
  CardBrowserPalette.dark => const Color(0xff393939),
  CardBrowserPalette.black => const Color(0xff1a1a1a),
  CardBrowserPalette.eink => const Color(0xffe0e0e0),
};
