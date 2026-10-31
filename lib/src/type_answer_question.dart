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
 * Behavioral reference: `TypeAnswer.filterQuestion()` in AnkiDroid 2.25.3.
 */

// Match Java's default Pattern dot behavior, including excluding NEL.
final RegExp _questionTypeAnswerPattern = RegExp(
  r'\[\[type:([^\r\n\u0085\u2028\u2029]+?)]]',
);

/// Replaces question-side type-answer markers with the source prompt or warning.
///
/// The host supplies the values that AnkiDroid's `TypeAnswer` object obtains
/// from preferences, card/note lookup, and rendering state. Replacement strings
/// retain Java `Matcher` `$` and backslash semantics; invalid group references
/// throw [FormatException]. This models the string transform only, not HTML or
/// Android input rendering.
String filterTypeAnswerQuestion(
  String text, {
  required bool useInputTag,
  required bool autoFocus,
  String font = '',
  int size = 0,
  String? warning,
}) {
  if (warning != null) {
    return text.replaceFirstMapped(
      _questionTypeAnswerPattern,
      (match) => _expandJavaMatcherReplacement(warning, match),
    );
  }

  final replacement = useInputTag
      ? _inputPrompt(autoFocus: autoFocus, font: font, size: size)
      : '<span id="typeans" class="typePrompt">........</span>';
  return text.replaceAllMapped(
    _questionTypeAnswerPattern,
    (match) => _expandJavaMatcherReplacement(replacement, match),
  );
}

/// Applies the Template Previewer's question-side `typeAnsFilter` replacement.
///
/// The first matching marker becomes the exact read-only example input;
/// later markers become the supplied warning. The read-only input matches the
/// source literal; the host supplies the localized warning and retains
/// Previewer state and rendering. Replacement strings use Java `Matcher` group
/// and backslash semantics, matching the existing question-side helper.
String filterTemplatePreviewerTypeAnswerQuestion(
  String text, {
  required String warningHtml,
}) {
  var first = true;
  return text.replaceAllMapped(_questionTypeAnswerPattern, (match) {
    final replacement = first
        ? _templatePreviewerExampleInputHtml
        : warningHtml;
    first = false;
    return _expandJavaMatcherReplacement(replacement, match);
  });
}

const String _templatePreviewerExampleInputHtml =
    "<center><input id='typeans' type=text value='example' "
    "readonly='readonly'></center>";

String _inputPrompt({
  required bool autoFocus,
  required String font,
  required int size,
}) {
  final output = StringBuffer()
    ..write('<center>\n')
    ..write('<input type="text" name="typed" id="typeans" ')
    ..write('data-focus="$autoFocus" onfocus="taFocus();" ')
    ..write("oninput='taChange(this);' ")
    ..write('onKeyPress="return taKey(this, event)" ')
    ..write('autocomplete="off" ');
  if (font.isNotEmpty && size > 0) {
    output
      ..write('style="font-family: \'')
      ..write(font)
      ..write("'; font-size: $size")
      ..write('px;" ');
  }
  output.write('>\n</center>\n');
  return output.toString();
}

/// Replaces every Reviewer question marker with its HTML type-answer input.
///
/// The host supplies the resolved font and font size. The Reviewer-specific
/// prompt is interpolated directly into a Java `Matcher` replacement string,
/// preserving its `$` group and backslash behavior. Reviewer dispatch,
/// TypeAnswer lookup/state, and HTML/WebView rendering remain host-side.
String filterReviewerTypeAnswerQuestion(
  String text, {
  required String font,
  required int fontSize,
}) {
  final replacement =
      '<center>\n'
      '<input type="text" id="typeans" '
      'onkeydown="ankidroid.onTypeAnswerKeyDown(event);" \n'
      '   style="font-family: \'$font\'; font-size: ${fontSize}px;">\n'
      '</center>';
  return text.replaceAllMapped(
    _questionTypeAnswerPattern,
    (match) => _expandJavaMatcherReplacement(replacement, match),
  );
}

String _expandJavaMatcherReplacement(String replacement, Match match) {
  final output = StringBuffer();
  var index = 0;
  while (index < replacement.length) {
    final character = replacement[index];
    if (character == r'\') {
      if (index + 1 == replacement.length) {
        throw const FormatException('Trailing backslash in replacement');
      }
      output.write(replacement[index + 1]);
      index += 2;
      continue;
    }
    if (character != r'$') {
      output.write(character);
      index++;
      continue;
    }

    if (index + 1 == replacement.length) {
      throw const FormatException('Dangling dollar in replacement');
    }
    final next = replacement[index + 1];
    if (next == '{') {
      final closingBrace = replacement.indexOf('}', index + 2);
      if (closingBrace == -1) {
        throw const FormatException('Unclosed named group in replacement');
      }
      final groupName = replacement.substring(index + 2, closingBrace);
      throw FormatException('Unknown named group: $groupName');
    }

    var groupIndex = _digitValue(next);
    if (groupIndex < 0) {
      throw const FormatException('Invalid group reference in replacement');
    }
    if (groupIndex > match.groupCount) {
      throw FormatException('Unknown group: $groupIndex');
    }
    index += 2;
    while (index < replacement.length) {
      final nextDigit = _digitValue(replacement[index]);
      if (nextDigit < 0) break;
      final combined = groupIndex * 10 + nextDigit;
      if (combined > match.groupCount) break;
      groupIndex = combined;
      index++;
    }
    output.write(match.group(groupIndex) ?? '');
  }
  return output.toString();
}

int _digitValue(String character) {
  final codeUnit = character.codeUnitAt(0);
  return codeUnit >= 0x30 && codeUnit <= 0x39 ? codeUnit - 0x30 : -1;
}
