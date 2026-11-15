/*
 * Copyright (c) 2009 Daniel Svärd <daniel.svard@gmail.com>
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Caches host-rendered card output and adapts Card's output accessors.
///
/// The host retains Card, Collection, TemplateManager, and render output
/// implementations. It supplies callbacks for rendering and reading output
/// fields; this wrapper preserves Card's cache and callback behavior.
final class LibAnkiCardRenderOutputCache<TRenderOutput, TAvTag> {
  LibAnkiCardRenderOutputCache({TRenderOutput? renderOutput})
    : cachedOutput = renderOutput;

  /// The cached output that the source `Card.renderOutput` property holds.
  TRenderOutput? cachedOutput;

  /// Returns the cached output or invokes [render] to replace it.
  ///
  /// A failed render leaves [cachedOutput] unchanged and propagates the same
  /// error. [browser] is forwarded only when rendering is required.
  TRenderOutput renderOutput({
    required TRenderOutput Function(bool browser) render,
    bool reload = false,
    bool browser = false,
  }) {
    final output = cachedOutput;
    if (output != null && !reload) return output;

    final renderedOutput = render(browser);
    cachedOutput = renderedOutput;
    return renderedOutput;
  }

  /// Returns the question text from the cached or newly rendered output.
  String question({
    required TRenderOutput Function(bool browser) render,
    required String Function(TRenderOutput output) questionAndStyle,
    bool reload = false,
    bool browser = false,
  }) {
    final output = renderOutput(
      render: render,
      reload: reload,
      browser: browser,
    );
    return questionAndStyle(output);
  }

  /// Returns the answer text from the cached or newly rendered output.
  String answer({
    required TRenderOutput Function(bool browser) render,
    required String Function(TRenderOutput output) answerAndStyle,
  }) => answerAndStyle(renderOutput(render: render));

  /// Returns the question-side AV tags from the cached or newly rendered output.
  List<TAvTag> questionAvTags({
    required TRenderOutput Function(bool browser) render,
    required List<TAvTag> Function(TRenderOutput output) questionAvTags,
  }) => questionAvTags(renderOutput(render: render));

  /// Returns the answer-side AV tags from the cached or newly rendered output.
  List<TAvTag> answerAvTags({
    required TRenderOutput Function(bool browser) render,
    required List<TAvTag> Function(TRenderOutput output) answerAvTags,
  }) => answerAvTags(renderOutput(render: render));
}
