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
 * Behavioral reference: WhiteboardViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Source `BrushInfo` value, with the same structural equality as its Kotlin
/// data class.
final class BrushInfo {
  const BrushInfo({required this.color, required this.width});

  final int color;
  final double width;

  BrushInfo copyWith({int? color, double? width}) =>
      BrushInfo(color: color ?? this.color, width: width ?? this.width);

  @override
  bool operator ==(Object other) =>
      other is BrushInfo &&
      other.color == color &&
      _sameFloat(other.width, width);

  @override
  int get hashCode => Object.hash(color, _float32Bits(width));
}

enum WhiteboardEraserMode { ink, stroke }

enum WhiteboardToolbarAlignment { left, right, bottom }

sealed class WhiteboardToolEffect {
  const WhiteboardToolEffect();
}

final class PublishWhiteboardBrushesEffect extends WhiteboardToolEffect {
  PublishWhiteboardBrushesEffect(Iterable<BrushInfo> brushes)
    : brushes = List.unmodifiable(brushes);

  final List<BrushInfo> brushes;
}

final class SaveWhiteboardBrushesEffect extends WhiteboardToolEffect {
  SaveWhiteboardBrushesEffect(Iterable<BrushInfo> brushes, this.isDarkMode)
    : brushes = List.unmodifiable(brushes);

  final List<BrushInfo> brushes;
  final bool isDarkMode;
}

final class PublishWhiteboardActiveBrushIndexEffect
    extends WhiteboardToolEffect {
  const PublishWhiteboardActiveBrushIndexEffect(this.index);

  final int index;
}

final class SaveWhiteboardLastActiveBrushIndexEffect
    extends WhiteboardToolEffect {
  const SaveWhiteboardLastActiveBrushIndexEffect(this.index, this.isDarkMode);

  final int index;
  final bool isDarkMode;
}

final class PublishWhiteboardBrushColorEffect extends WhiteboardToolEffect {
  const PublishWhiteboardBrushColorEffect(this.color);

  final int color;
}

final class PublishWhiteboardActiveStrokeWidthEffect
    extends WhiteboardToolEffect {
  const PublishWhiteboardActiveStrokeWidthEffect(this.width);

  final double width;
}

final class PublishWhiteboardEraserActiveEffect extends WhiteboardToolEffect {
  const PublishWhiteboardEraserActiveEffect(this.isActive);

  final bool isActive;
}

final class PublishWhiteboardEraserModeEffect extends WhiteboardToolEffect {
  const PublishWhiteboardEraserModeEffect(this.mode);

  final WhiteboardEraserMode mode;
}

final class SaveWhiteboardEraserModeEffect extends WhiteboardToolEffect {
  const SaveWhiteboardEraserModeEffect(this.mode);

  final WhiteboardEraserMode mode;
}

final class PublishWhiteboardInkEraserStrokeWidthEffect
    extends WhiteboardToolEffect {
  const PublishWhiteboardInkEraserStrokeWidthEffect(this.width);

  final double width;
}

final class PublishWhiteboardStrokeEraserStrokeWidthEffect
    extends WhiteboardToolEffect {
  const PublishWhiteboardStrokeEraserStrokeWidthEffect(this.width);

  final double width;
}

final class SaveWhiteboardInkEraserWidthEffect extends WhiteboardToolEffect {
  const SaveWhiteboardInkEraserWidthEffect(this.width);

  final double width;
}

final class SaveWhiteboardStrokeEraserWidthEffect extends WhiteboardToolEffect {
  const SaveWhiteboardStrokeEraserWidthEffect(this.width);

  final double width;
}

final class PublishWhiteboardStylusOnlyModeEffect extends WhiteboardToolEffect {
  const PublishWhiteboardStylusOnlyModeEffect(this.isEnabled);

  final bool isEnabled;
}

final class SaveWhiteboardStylusOnlyModeEffect extends WhiteboardToolEffect {
  const SaveWhiteboardStylusOnlyModeEffect(this.isEnabled);

  final bool isEnabled;
}

final class PublishWhiteboardToolbarAlignmentEffect
    extends WhiteboardToolEffect {
  const PublishWhiteboardToolbarAlignmentEffect(this.alignment);

  final WhiteboardToolbarAlignment alignment;
}

final class SaveWhiteboardToolbarAlignmentEffect extends WhiteboardToolEffect {
  const SaveWhiteboardToolbarAlignmentEffect(this.alignment);

  final WhiteboardToolbarAlignment alignment;
}

final class PublishWhiteboardToolbarShownEffect extends WhiteboardToolEffect {
  const PublishWhiteboardToolbarShownEffect(this.isShown);

  final bool isShown;
}

final class SaveWhiteboardToolbarShownEffect extends WhiteboardToolEffect {
  const SaveWhiteboardToolbarShownEffect(this.isShown);

  final bool isShown;
}

/// State decisions and ordered host effects for brush and eraser tools.
///
/// The host supplies loaded preferences and applies repository effects. This
/// class excludes Android flows, ViewModel lifecycle, repository IO and UI.
final class WhiteboardToolState {
  WhiteboardToolState({
    required Iterable<BrushInfo> brushes,
    int activeBrushIndex = 0,
    int brushColor = -16777216,
    double activeStrokeWidth = defaultStrokeWidth,
    bool isEraserActive = false,
    WhiteboardEraserMode eraserMode = WhiteboardEraserMode.ink,
    double inkEraserStrokeWidth = defaultEraserWidth,
    double strokeEraserStrokeWidth = defaultEraserWidth,
    bool isStylusOnlyMode = false,
    WhiteboardToolbarAlignment toolbarAlignment =
        WhiteboardToolbarAlignment.bottom,
    bool isToolbarShown = true,
    this.isDarkMode = false,
  }) : _brushes = List.unmodifiable(
         brushes.map((brush) => brush.copyWith(width: _float32(brush.width))),
       ),
       _activeBrushIndex = activeBrushIndex,
       _brushColor = brushColor,
       _activeStrokeWidth = _float32(activeStrokeWidth),
       _isEraserActive = isEraserActive,
       _eraserMode = eraserMode,
       _inkEraserStrokeWidth = _float32(inkEraserStrokeWidth),
       _strokeEraserStrokeWidth = _float32(strokeEraserStrokeWidth),
       _isStylusOnlyMode = isStylusOnlyMode,
       _toolbarAlignment = toolbarAlignment,
       _isToolbarShown = isToolbarShown;

  static const double defaultStrokeWidth = 10;
  static const double defaultEraserWidth = 30;

  List<BrushInfo> _brushes;
  List<BrushInfo> get brushes => _brushes;

  int _activeBrushIndex;
  int get activeBrushIndex => _activeBrushIndex;

  int _brushColor;
  int get brushColor => _brushColor;

  double _activeStrokeWidth;
  double get activeStrokeWidth => _activeStrokeWidth;

  bool _isEraserActive;
  bool get isEraserActive => _isEraserActive;

  WhiteboardEraserMode _eraserMode;
  WhiteboardEraserMode get eraserMode => _eraserMode;

  double _inkEraserStrokeWidth;
  double get inkEraserStrokeWidth => _inkEraserStrokeWidth;

  double _strokeEraserStrokeWidth;
  double get strokeEraserStrokeWidth => _strokeEraserStrokeWidth;

  bool _isStylusOnlyMode;
  bool get isStylusOnlyMode => _isStylusOnlyMode;

  WhiteboardToolbarAlignment _toolbarAlignment;
  WhiteboardToolbarAlignment get toolbarAlignment => _toolbarAlignment;

  bool _isToolbarShown;
  bool get isToolbarShown => _isToolbarShown;
  final bool isDarkMode;

  List<WhiteboardToolEffect> setActiveBrush(int index) {
    if (index < 0 || index >= _brushes.length) return const [];
    final brush = _brushes[index];
    _isEraserActive = false;
    _activeBrushIndex = index;
    _brushColor = brush.color;
    _activeStrokeWidth = brush.width;
    return List.unmodifiable([
      const PublishWhiteboardEraserActiveEffect(false),
      PublishWhiteboardActiveBrushIndexEffect(index),
      SaveWhiteboardLastActiveBrushIndexEffect(index, isDarkMode),
      PublishWhiteboardBrushColorEffect(brush.color),
      PublishWhiteboardActiveStrokeWidthEffect(brush.width),
    ]);
  }

  List<WhiteboardToolEffect> enableEraser({required double displayWidth}) {
    final width = _float32(displayWidth);
    _isEraserActive = true;
    _activeStrokeWidth = width;
    return List.unmodifiable([
      const PublishWhiteboardEraserActiveEffect(true),
      PublishWhiteboardActiveStrokeWidthEffect(width),
    ]);
  }

  List<WhiteboardToolEffect> toggleEraser({required double displayWidth}) =>
      _isEraserActive
      ? setActiveBrush(_activeBrushIndex)
      : enableEraser(displayWidth: displayWidth);

  List<WhiteboardToolEffect> setEraserMode(WhiteboardEraserMode mode) {
    _eraserMode = mode;
    final effects = <WhiteboardToolEffect>[
      PublishWhiteboardEraserModeEffect(mode),
      SaveWhiteboardEraserModeEffect(mode),
    ];
    if (_isEraserActive) {
      _activeStrokeWidth = mode == WhiteboardEraserMode.ink
          ? _inkEraserStrokeWidth
          : _strokeEraserStrokeWidth;
      effects.add(PublishWhiteboardActiveStrokeWidthEffect(_activeStrokeWidth));
    }
    return List.unmodifiable(effects);
  }

  List<WhiteboardToolEffect> setActiveStrokeWidth(double newWidth) {
    final width = _float32(newWidth);
    final effects = <WhiteboardToolEffect>[];
    if (_isEraserActive) {
      if (_eraserMode == WhiteboardEraserMode.ink) {
        _inkEraserStrokeWidth = width;
        effects.add(PublishWhiteboardInkEraserStrokeWidthEffect(width));
        effects.add(SaveWhiteboardInkEraserWidthEffect(width));
      } else {
        _strokeEraserStrokeWidth = width;
        effects.add(PublishWhiteboardStrokeEraserStrokeWidthEffect(width));
        effects.add(SaveWhiteboardStrokeEraserWidthEffect(width));
      }
    } else {
      _brushes = List.unmodifiable([
        for (var index = 0; index < _brushes.length; index++)
          if (index == _activeBrushIndex)
            _brushes[index].copyWith(width: width)
          else
            _brushes[index],
      ]);
      effects.add(PublishWhiteboardBrushesEffect(_brushes));
      effects.add(SaveWhiteboardBrushesEffect(_brushes, isDarkMode));
    }
    _activeStrokeWidth = width;
    effects.add(PublishWhiteboardActiveStrokeWidthEffect(width));
    return List.unmodifiable(effects);
  }

  List<WhiteboardToolEffect> updateBrushColor(int newColor) {
    _brushes = List.unmodifiable([
      for (var index = 0; index < _brushes.length; index++)
        if (index == activeBrushIndex)
          _brushes[index].copyWith(color: newColor)
        else
          _brushes[index],
    ]);
    _brushColor = newColor;
    return List.unmodifiable([
      PublishWhiteboardBrushesEffect(_brushes),
      SaveWhiteboardBrushesEffect(_brushes, isDarkMode),
      PublishWhiteboardBrushColorEffect(newColor),
    ]);
  }

  List<WhiteboardToolEffect> addBrush(int color) {
    _brushes = List.unmodifiable([
      ..._brushes,
      BrushInfo(color: color, width: defaultStrokeWidth),
    ]);
    return List.unmodifiable([
      PublishWhiteboardBrushesEffect(_brushes),
      SaveWhiteboardBrushesEffect(_brushes, isDarkMode),
      ...setActiveBrush(_brushes.length - 1),
    ]);
  }

  List<WhiteboardToolEffect> removeBrush(int indexToRemove) {
    if (_brushes.length <= 1) return const [];
    final oldActiveIndex = _activeBrushIndex;
    _brushes = List.unmodifiable([
      for (var index = 0; index < _brushes.length; index++)
        if (index != indexToRemove) _brushes[index],
    ]);
    final effects = <WhiteboardToolEffect>[
      PublishWhiteboardBrushesEffect(_brushes),
      SaveWhiteboardBrushesEffect(_brushes, isDarkMode),
    ];
    if (oldActiveIndex == indexToRemove) {
      effects.addAll(
        setActiveBrush(oldActiveIndex > 0 ? oldActiveIndex - 1 : 0),
      );
    } else if (oldActiveIndex > indexToRemove) {
      effects.addAll(setActiveBrush(oldActiveIndex - 1));
    }
    return List.unmodifiable(effects);
  }

  List<WhiteboardToolEffect> toggleStylusOnlyMode() {
    _isStylusOnlyMode = !_isStylusOnlyMode;
    return List.unmodifiable([
      PublishWhiteboardStylusOnlyModeEffect(_isStylusOnlyMode),
      SaveWhiteboardStylusOnlyModeEffect(_isStylusOnlyMode),
    ]);
  }

  List<WhiteboardToolEffect> setToolbarAlignment(
    WhiteboardToolbarAlignment alignment,
  ) {
    if (_toolbarAlignment == alignment) return const [];
    _toolbarAlignment = alignment;
    return List.unmodifiable([
      PublishWhiteboardToolbarAlignmentEffect(alignment),
      SaveWhiteboardToolbarAlignmentEffect(alignment),
    ]);
  }

  List<WhiteboardToolEffect> setIsToolbarShown(bool isShown) {
    if (_isToolbarShown == isShown) return const [];
    _isToolbarShown = isShown;
    return List.unmodifiable([
      PublishWhiteboardToolbarShownEffect(isShown),
      SaveWhiteboardToolbarShownEffect(isShown),
    ]);
  }
}

double _float32(double value) => Float32List.fromList([value])[0];

int _float32Bits(double value) =>
    (ByteData(4)..setFloat32(0, _float32(value), Endian.big)).getUint32(0);

bool _sameFloat(double first, double second) => first.isNaN && second.isNaN
    ? true
    : _float32Bits(first) == _float32Bits(second);
