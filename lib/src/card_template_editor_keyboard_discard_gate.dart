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
 * Source-derived from CardTemplateEditor.kt; see ANKIDROID_UPSTREAM.md.
 */

/// Host callbacks needed to preserve the keyboard/discard update sequence.
///
/// The type parameters stand in for Android fragment, view, binding, and bottom
/// navigation objects; those objects and their lifecycle remain host-side.
class CardTemplateEditorKeyboardDiscardCallbacks<
  Fragment,
  View,
  Binding,
  BottomNavigation
> {
  const CardTemplateEditorKeyboardDiscardCallbacks({
    required this.currentFragment,
    required this.fragmentView,
    required this.viewBinding,
    required this.bindingBottomNavigation,
    required this.bottomNavigationIsVisible,
    required this.noteTypeHasChanged,
    required this.setDiscardCallbackEnabled,
  });

  final Fragment? Function() currentFragment;
  final View? Function(Fragment fragment) fragmentView;
  final Binding? Function(View view) viewBinding;
  final BottomNavigation? Function(Binding binding) bindingBottomNavigation;
  final bool? Function(BottomNavigation bottomNavigation)
  bottomNavigationIsVisible;
  final bool Function() noteTypeHasChanged;
  final void Function(bool enabled) setDiscardCallbackEnabled;
}

/// Updates the discard callback enabled state using the source keyboard gate.
///
/// Reads the current fragment once and follows the nullable fragment/view/
/// binding/navigation chain in order. Only an explicit `false` visibility means
/// the keyboard is open; in that case note-type comparison is skipped and the
/// callback is disabled. Otherwise note-type comparison runs once and its
/// result is written once. Callback errors propagate unchanged.
void cardTemplateEditorUpdateDiscardChangesCallback<
  Fragment,
  View,
  Binding,
  BottomNavigation
>({
  required CardTemplateEditorKeyboardDiscardCallbacks<
    Fragment,
    View,
    Binding,
    BottomNavigation
  >
  callbacks,
}) {
  bool? visibility;
  final fragment = callbacks.currentFragment();
  if (fragment != null) {
    final view = callbacks.fragmentView(fragment);
    if (view != null) {
      final binding = callbacks.viewBinding(view);
      if (binding != null) {
        final bottomNavigation = callbacks.bindingBottomNavigation(binding);
        if (bottomNavigation != null) {
          visibility = callbacks.bottomNavigationIsVisible(bottomNavigation);
        }
      }
    }
  }

  final isKeyboardOpen = visibility == false;
  final enabled = !isKeyboardOpen && callbacks.noteTypeHasChanged();
  callbacks.setDiscardCallbackEnabled(enabled);
}
