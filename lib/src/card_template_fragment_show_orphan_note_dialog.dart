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
 * Source-derived from CardTemplateFragment.showOrphanNoteDialog in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.showOrphanNoteDialog`.
///
/// Android context, AlertDialog builder, resource constants, and UI remain
/// host-side. Dart carries opaque handles and sequences callbacks in source
/// order; callback failures propagate immediately.
final class CardTemplateFragmentShowOrphanNoteDialogCallbacks<
  TContext,
  TBuilder,
  TTitleResource,
  TMessageResource,
  TOkResource
> {
  const CardTemplateFragmentShowOrphanNoteDialogCallbacks({
    required this.requireContext,
    required this.createBuilder,
    required this.setTitle,
    required this.setMessage,
    required this.setPositiveButton,
    required this.show,
  });

  final TContext Function() requireContext;
  final TBuilder Function(TContext context) createBuilder;
  final void Function(TBuilder builder, TTitleResource resource) setTitle;
  final void Function(TBuilder builder, TMessageResource resource) setMessage;
  final void Function(
    TBuilder builder,
    TOkResource resource,
    void Function()? listener,
  )
  setPositiveButton;
  final void Function(TBuilder builder) show;
}

/// Projects `CardTemplateFragment.showOrphanNoteDialog` in pinned source order.
///
/// The host supplies its orphan-title, orphan-message, and Android OK resource
/// constants. The same builder is configured and shown; the Android dialog
/// returned by the host builder is intentionally not exposed.
void cardTemplateFragmentShowOrphanNoteDialog<
  TContext,
  TBuilder,
  TTitleResource,
  TMessageResource,
  TOkResource
>({
  required CardTemplateFragmentShowOrphanNoteDialogCallbacks<
    TContext,
    TBuilder,
    TTitleResource,
    TMessageResource,
    TOkResource
  >
  callbacks,
  required TTitleResource titleResource,
  required TMessageResource messageResource,
  required TOkResource okResource,
}) {
  final context = callbacks.requireContext();
  final builder = callbacks.createBuilder(context);
  callbacks.setTitle(builder, titleResource);
  callbacks.setMessage(builder, messageResource);
  callbacks.setPositiveButton(builder, okResource, null);
  callbacks.show(builder);
}
