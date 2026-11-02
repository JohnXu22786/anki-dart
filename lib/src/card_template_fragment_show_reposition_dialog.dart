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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks for `CardTemplateFragment.showRepositionDialog`.
///
/// Android Context, pager adapter/dialog construction, lifecycle, and Timber
/// remain host-side. The callbacks expose their source-ordered reads and defer
/// the confirmation effects until the host invokes [onConfirm].
final class CardTemplateFragmentShowRepositionDialogCallbacks<
  TContext,
  TAdapter
> {
  const CardTemplateFragmentShowRepositionDialogCallbacks({
    required this.requireContext,
    required this.readPagerAdapter,
    required this.readAdapterItemCount,
    required this.showRepositionDialog,
    required this.readOrdinal,
    required this.warn,
  });

  final TContext Function() requireContext;
  final TAdapter? Function() readPagerAdapter;
  final int Function(TAdapter adapter) readAdapterItemCount;
  final void Function({
    required TContext context,
    required int itemCount,
    required void Function(int newPosition) onConfirm,
  })
  showRepositionDialog;
  final int Function() readOrdinal;
  final void Function(String format, int currentPosition, int newPosition) warn;
}

/// Projects `CardTemplateFragment.showRepositionDialog` in pinned source order.
///
/// The source confirmation callback intentionally ends in an unimplemented
/// TODO after warning. It does not perform card-template repositioning.
void cardTemplateFragmentShowRepositionDialog<TContext, TAdapter>({
  required CardTemplateFragmentShowRepositionDialogCallbacks<TContext, TAdapter>
  callbacks,
}) {
  final context = callbacks.requireContext();
  final adapter = callbacks.readPagerAdapter()!;
  final itemCount = callbacks.readAdapterItemCount(adapter);

  callbacks.showRepositionDialog(
    context: context,
    itemCount: itemCount,
    onConfirm: (newPosition) {
      final currentPosition = callbacks.readOrdinal();
      callbacks.warn(
        'moving card template %d to %d',
        currentPosition,
        newPosition,
      );
      throw UnimplementedError(
        'CardTemplateNotetype is a complex class and requires significant testing',
      );
    },
  );
}
