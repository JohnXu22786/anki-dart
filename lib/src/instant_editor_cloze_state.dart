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
 * Behavioral reference: InstantEditorViewModel.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Numbering behavior used by AnkiDroid's Instant Note Editor.
enum ClozeNumberMode { increment, noIncrement }

/// Portable state and text decisions for AnkiDroid's Instant Editor clozes.
///
/// Note and collection mutations, editor selection, UI, and Android flow
/// delivery remain with the host.
final class InstantEditorClozeState {
  static final RegExp _clozePattern = RegExp(
    r'([\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]+)?'
    r'\{\{c([0-9]+)::([^}]+?)\}\}'
    r'([\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]+)?',
  );

  static final RegExp _clozeBuilderPattern = RegExp(
    r'([\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]*)'
    r'((?:[A-Za-z0-9_]|\p{Pd}|\p{Pc}|\x27|(\([A-Za-z0-9_]+\)))+)'
    r'([\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]*)',
    unicode: true,
  );

  final List<int> _clozeOrdinals = [];
  int _currentClozeNumber = 1;
  ClozeNumberMode _currentClozeMode = ClozeNumberMode.increment;
  String? _actualClozeFieldText;

  /// Current ordinal selected by the source's cloze numbering rules.
  int get currentClozeNumber => _currentClozeNumber;

  /// Current numbering mode.
  ClozeNumberMode get currentClozeMode => _currentClozeMode;

  /// Last nullable field value supplied by the host.
  String? get actualClozeFieldText => _actualClozeFieldText;

  /// Parsed ordinals in source order, including duplicate values.
  List<int> get clozeOrdinals => List.unmodifiable(_clozeOrdinals);

  /// Number of cloze matches recorded in the source list.
  int get clozeDeletionCount => _clozeOrdinals.length;

  /// Stores nullable field text and replaces the ordinal list from its matches.
  void setClozeFieldText(String? text) {
    _actualClozeFieldText = text;
    _clozeOrdinals
      ..clear()
      ..addAll(_getClozeOrdinals(text ?? ''));
    final maximum = _clozeOrdinals.isEmpty ? null : _clozeOrdinals.reduce(_max);
    _currentClozeNumber = switch (_currentClozeMode) {
      ClozeNumberMode.increment => _int32((maximum ?? 0) + 1),
      ClozeNumberMode.noIncrement => maximum ?? 1,
    };
  }

  /// Switches mode, adjusting the counter only while clozes are recorded.
  void toggleClozeMode() {
    switch (_currentClozeMode) {
      case ClozeNumberMode.increment:
        if (_clozeOrdinals.isNotEmpty) _decrementClozeNumber();
        _currentClozeMode = ClozeNumberMode.noIncrement;
      case ClozeNumberMode.noIncrement:
        if (_clozeOrdinals.isNotEmpty) _incrementClozeNumber();
        _currentClozeMode = ClozeNumberMode.increment;
    }
  }

  /// Adds a cloze around the first source-regex word, or removes an existing
  /// cloze using the source's match and counter/list update order.
  String buildClozeText(String text) {
    final undone = _processClozeUndo(text);
    if (undone != null) return undone;

    final matcher = _clozeBuilderPattern.firstMatch(text);
    final clozeNumber = _currentClozeNumber;
    if (_currentClozeMode == ClozeNumberMode.increment) {
      _incrementClozeNumber();
    }
    _clozeOrdinals.add(clozeNumber);

    final punctuationAtStart = matcher?.group(1);
    final capturedWord = matcher?.group(2);
    final punctuationAtEnd = matcher?.group(4);
    return '$punctuationAtStart{{c$clozeNumber::$capturedWord}}$punctuationAtEnd';
  }

  List<int> _getClozeOrdinals(String text) {
    final ordinals = <int>[];
    for (final match in _clozePattern.allMatches(text)) {
      final ordinal = _toIntOrNull(match.group(2)!);
      if (ordinal != null) ordinals.add(ordinal);
    }
    return ordinals;
  }

  String? _processClozeUndo(String text) {
    final match = _clozePattern.firstMatch(text);
    final capturedNumber = match?.group(2);
    if (capturedNumber != null) {
      final number = _toInt(capturedNumber);
      if (_int32(_currentClozeNumber - number) == 1) {
        _decrementClozeNumber();
      }
    }

    if (match == null) return null;

    final parsedNumber = _toInt(match.group(2)!);
    _shouldResetClozeNumber(parsedNumber);
    final punctuationAtStart = match.group(1) ?? '';
    final capturedWord = match.group(3) ?? '';
    final punctuationAtEnd = match.group(4) ?? '';
    return '$punctuationAtStart$capturedWord$punctuationAtEnd';
  }

  void _shouldResetClozeNumber(int number) {
    _clozeOrdinals.remove(number);
    if (_clozeOrdinals.isEmpty) {
      _currentClozeNumber = 1;
    } else if (_currentClozeMode == ClozeNumberMode.increment) {
      final maximum = _clozeOrdinals.reduce(_max);
      _currentClozeNumber = _int32(maximum + 1);
    }
  }

  void _incrementClozeNumber() {
    _currentClozeNumber = _int32(_currentClozeNumber + 1);
  }

  void _decrementClozeNumber() {
    _currentClozeNumber = _max(1, _int32(_currentClozeNumber - 1));
  }

  static int _toInt(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < -0x80000000 || parsed > 0x7fffffff) {
      throw FormatException('Invalid int: $value');
    }
    return parsed;
  }

  static int? _toIntOrNull(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < -0x80000000 || parsed > 0x7fffffff) {
      return null;
    }
    return parsed;
  }

  static int _int32(int value) =>
      ((value + 0x80000000) & 0xffffffff) - 0x80000000;

  static int _max(int left, int right) => left > right ? left : right;
}
