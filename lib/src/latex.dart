/*
 * Copyright (c) 2009 Edu Zamora <edu.zasu@gmail.com>
 * Copyright (c) 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2015 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Edu Zamora <edu.zasu@gmail.com>
 * SPDX-FileCopyrightText: 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * SPDX-FileCopyrightText: 2015 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source mapping: `LaTeX.kt` in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// One LaTeX image reference extracted by the host backend.
final class ExtractedLatex {
  const ExtractedLatex({required this.fileName, required this.latexBody});

  final String fileName;
  final String latexBody;

  @override
  bool operator ==(Object other) =>
      other is ExtractedLatex &&
      other.fileName == fileName &&
      other.latexBody == latexBody;

  @override
  int get hashCode => Object.hash(fileName, latexBody);
}

/// Host-independent equivalent of the extracted backend response.
final class ExtractedLatexOutput {
  const ExtractedLatexOutput({required this.html, required this.latex});

  /// Maps fields exposed by a host adapter for the generated response proto.
  factory ExtractedLatexOutput.fromProtoLike({
    required String text,
    required Iterable<({String filename, String latexBody})> latexList,
  }) => ExtractedLatexOutput(
    html: text,
    latex: latexList
        .map(
          (entry) => ExtractedLatex(
            fileName: entry.filename,
            latexBody: entry.latexBody,
          ),
        )
        .toList(),
  );

  final String html;
  final List<ExtractedLatex> latex;
}

/// The note type's LaTeX fields read by the source rendering path.
final class LatexModelSettings {
  const LatexModelSettings({
    required this.svg,
    required this.header,
    required this.footer,
  });

  final bool svg;
  final String header;
  final String footer;
}

/// Output fields updated by the source's card-render callback.
final class LatexCardRenderOutput {
  LatexCardRenderOutput({required this.questionText, required this.answerText});

  String questionText;
  String answerText;
}

typedef LatexBackendExtraction =
    ExtractedLatexOutput Function({
      required String text,
      required bool svg,
      required bool expandClozes,
    });
typedef LatexRenderConfigRead = bool Function();
typedef LatexMediaLookup = bool Function(String fileName);
typedef LatexDisabledMessage = String Function();
typedef LatexNoteTypeRead = LatexModelSettings Function();

/// Adapts `onCardDidRender` while leaving card context and backend objects host-side.
LatexCardRenderOutput onCardDidRender({
  required LatexCardRenderOutput output,
  required LatexNoteTypeRead noteType,
  required LatexBackendExtraction extractLatex,
  required LatexRenderConfigRead renderLatexEnabled,
  required LatexMediaLookup haveMedia,
  required LatexDisabledMessage latexGenerationDisabledMessage,
}) {
  output.questionText = renderLatex(
    output.questionText,
    noteType(),
    extractLatex: extractLatex,
    renderLatexEnabled: renderLatexEnabled,
    haveMedia: haveMedia,
    latexGenerationDisabledMessage: latexGenerationDisabledMessage,
  );
  output.answerText = renderLatex(
    output.answerText,
    noteType(),
    extractLatex: extractLatex,
    renderLatexEnabled: renderLatexEnabled,
    haveMedia: haveMedia,
    latexGenerationDisabledMessage: latexGenerationDisabledMessage,
  );
  return output;
}

/// Appends any errors after the extracted HTML, matching the source's builder.
String renderLatex(
  String html,
  LatexModelSettings model, {
  required LatexBackendExtraction extractLatex,
  required LatexRenderConfigRead renderLatexEnabled,
  required LatexMediaLookup haveMedia,
  required LatexDisabledMessage latexGenerationDisabledMessage,
  bool expandClozes = false,
}) {
  final result = renderLatexRetuningErrors(
    html,
    model,
    extractLatex: extractLatex,
    renderLatexEnabled: renderLatexEnabled,
    haveMedia: haveMedia,
    latexGenerationDisabledMessage: latexGenerationDisabledMessage,
    expandClozes: expandClozes,
  );
  return result.html + result.errors.join('\n');
}

/// Extracts LaTeX, then applies AnkiDroid's media/config error policy.
({String html, List<String> errors}) renderLatexRetuningErrors(
  String html,
  LatexModelSettings model, {
  required LatexBackendExtraction extractLatex,
  required LatexRenderConfigRead renderLatexEnabled,
  required LatexMediaLookup haveMedia,
  required LatexDisabledMessage latexGenerationDisabledMessage,
  bool expandClozes = false,
}) {
  final output = extractLatex(
    text: html,
    svg: model.svg,
    expandClozes: expandClozes,
  );
  final renderingEnabled = renderLatexEnabled();
  final errors = <String>[];

  for (final latex in output.latex) {
    if (haveMedia(latex.fileName)) continue;
    if (!renderingEnabled) {
      errors.add(latexGenerationDisabledMessage());
      return (html: output.html, errors: errors);
    }

    // AnkiDroid's saveLatexImage deliberately returns null on this platform.
    _saveLatexImage();
  }
  return (html: output.html, errors: errors);
}

String? _saveLatexImage() => null;
