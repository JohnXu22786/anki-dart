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
 * Source-derived from CardTemplateFragment.openBrowserAppearance and
 * launchCardBrowserAppearance in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Opens the host browser-appearance editor for the current template.
///
/// [getCurrentTemplate] retains the host's current-index lookup and exception
/// boundary. For a non-null template, the host context is read, used with that
/// exact template to create the host Intent, and launched through the host
/// ActivityResult callback in source order. A null template skips those host
/// callbacks. Callback failures propagate unchanged.
bool openCardTemplateBrowserAppearance<TTemplate, TContext, TIntent>({
  required TTemplate? Function() getCurrentTemplate,
  required TContext Function() readAppContext,
  required TIntent Function(TContext context, TTemplate template) createIntent,
  required void Function(TIntent intent) launchActivityResult,
}) {
  final currentTemplate = getCurrentTemplate();
  if (currentTemplate != null) {
    final context = readAppContext();
    final intent = createIntent(context, currentTemplate);
    launchActivityResult(intent);
  }
  return true;
}
