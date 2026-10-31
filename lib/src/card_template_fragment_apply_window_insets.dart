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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

/// Host operations used by `CardTemplateFragment.onViewCreated()`'s inset
/// listener. Android inset masks and samples, binding values, views, and their
/// padding or visibility mutations remain host-side.
final class CardTemplateFragmentApplyWindowInsetsCallbacks<
  TView,
  TInsets,
  TInsetValues
> {
  const CardTemplateFragmentApplyWindowInsetsCallbacks({
    required this.imeInsets,
    required this.bottomInset,
    required this.minimumHeight,
    required this.setBottomNavigationVisible,
    required this.keyboardInsets,
    required this.setViewBottomPadding,
    required this.isCurrentPage,
    required this.updateDiscardChangesCallback,
    required this.fragmented,
    required this.barsInsets,
    required this.leftInset,
    required this.rightInset,
    required this.setScrollHorizontalPadding,
  });

  /// Reads the IME-masked sample from the delivered insets.
  final TInsetValues Function(TInsets insets) imeInsets;
  final int Function(TInsetValues insets) bottomInset;
  final int Function() minimumHeight;
  final void Function(bool visible) setBottomNavigationVisible;

  /// Reads the system-bars, display-cutout, and IME masked sample.
  final TInsetValues Function(TInsets insets) keyboardInsets;
  final void Function(TView view, int bottom) setViewBottomPadding;

  final bool Function() isCurrentPage;
  final void Function() updateDiscardChangesCallback;
  final bool Function() fragmented;

  /// Reads the system-bars and display-cutout masked sample.
  final TInsetValues Function(TInsets insets) barsInsets;
  final int Function(TInsetValues insets) leftInset;
  final int Function(TInsetValues insets) rightInset;
  final void Function(int left, int right) setScrollHorizontalPadding;
}

/// A deferred `doOnApplyWindowInsets` callback for the host to register.
typedef CardTemplateFragmentWindowInsetsHandler<TView, TInsets, TInitial> =
    void Function(TView view, TInsets insets, TInitial initial);

/// Creates the callback that updates the template editor's inset-dependent UI.
///
/// No host callback runs until the returned handler is invoked. The delivered
/// [insets] are sampled separately at each source point; callback failures
/// propagate and stop subsequent work, and [initial] is ignored.
CardTemplateFragmentWindowInsetsHandler<TView, TInsets, TInitial>
cardTemplateFragmentCreateWindowInsetsHandler<
  TView,
  TInsets,
  TInsetValues,
  TInitial
>({
  required CardTemplateFragmentApplyWindowInsetsCallbacks<
    TView,
    TInsets,
    TInsetValues
  >
  callbacks,
}) => (view, insets, initial) {
  final imeBottom = callbacks.bottomInset(callbacks.imeInsets(insets));
  final softwareKeyboardVisible = imeBottom > callbacks.minimumHeight();
  callbacks.setBottomNavigationVisible(!softwareKeyboardVisible);
  final bottomInset = callbacks.bottomInset(callbacks.keyboardInsets(insets));
  callbacks.setViewBottomPadding(
    view,
    softwareKeyboardVisible ? bottomInset : 0,
  );
  if (callbacks.isCurrentPage()) {
    callbacks.updateDiscardChangesCallback();
  }
  if (!callbacks.fragmented()) {
    final bars = callbacks.barsInsets(insets);
    final left = callbacks.leftInset(bars);
    final right = callbacks.rightInset(bars);
    callbacks.setScrollHorizontalPadding(left, right);
  }
};
