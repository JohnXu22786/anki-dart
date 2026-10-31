/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

/// Projects card template strings to the exact Markdown built by AnkiDroid.
///
/// The host supplies the three localized headings; Android [Context], generated
/// localization, and rendering remain host-side. Content and headings are
/// interpolated unchanged, including their line endings and Markdown syntax.
String cardTemplateToMarkdown({
  required String front,
  required String back,
  required String style,
  required String frontTemplateHeading,
  required String backTemplateHeading,
  required String templateStylingHeading,
}) =>
    '**$frontTemplateHeading**\n\n'
    '```html\n$front\n```\n\n'
    '**$backTemplateHeading**\n\n'
    '```html\n$back\n```\n\n'
    '**$templateStylingHeading**\n\n'
    '```css\n$style\n```';
