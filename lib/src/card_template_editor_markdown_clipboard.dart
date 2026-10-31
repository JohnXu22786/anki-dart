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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for copying the current card template as Markdown.
///
/// The host supplies the current template and Android context lazily, renders
/// the template, projects the result through its TruncatedString type, and
/// performs the Android clipboard operation. No Android or clipboard types
/// enter Dart.
final class CardTemplateMarkdownClipboardCallbacks<
  TTemplate,
  TContext,
  TTruncatedString
> {
  const CardTemplateMarkdownClipboardCallbacks({
    required this.currentTemplate,
    required this.context,
    required this.toMarkdown,
    required this.truncate,
    required this.copyToClipboard,
  });

  final TTemplate? Function() currentTemplate;
  final TContext? Function() context;
  final String Function(TTemplate template, TContext context) toMarkdown;
  final TTruncatedString Function(String markdown) truncate;
  final void Function(TContext context, TTruncatedString text) copyToClipboard;
}

/// Copies the current template as Markdown, preserving source callback order.
///
/// A missing template returns before reading context; a missing context returns
/// before rendering. Callback failures propagate unchanged and stop later work.
void
copyCardTemplateMarkdownToClipboard<TTemplate, TContext, TTruncatedString>({
  required CardTemplateMarkdownClipboardCallbacks<
    TTemplate,
    TContext,
    TTruncatedString
  >
  callbacks,
}) {
  final template = callbacks.currentTemplate();
  if (template == null) return;

  final context = callbacks.context();
  if (context == null) return;

  final markdown = callbacks.toMarkdown(template, context);
  final truncated = callbacks.truncate(markdown);
  callbacks.copyToClipboard(context, truncated);
}
