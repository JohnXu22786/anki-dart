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

/// Host callbacks for `CardTemplateFragment.setupMenu`.
///
/// Android Activity, MenuHost, MenuProvider, menu/resource, and lifecycle types
/// stay in the host. Provider callbacks are passed through the host factory and
/// remain deferred until Android invokes them.
final class CardTemplateFragmentSetupMenuCallbacks<
  TActivity,
  TMenuHost,
  TMenu,
  TMenuInflater,
  TMenuItem,
  TLifecycleOwner,
  TLifecycleState,
  TMenuResource,
  TMenuProvider
> {
  const CardTemplateFragmentSetupMenuCallbacks({
    required this.requireActivity,
    required this.castMenuHost,
    required this.createMenuProvider,
    required this.addMenuProvider,
    required this.readViewLifecycleOwner,
    required this.readResumedLifecycleState,
    required this.readCardTemplateEditorMenuResource,
    required this.inflateMenu,
    required this.setupCommonMenu,
    required this.handleCommonMenuItemSelected,
  });

  final TActivity Function() requireActivity;
  final TMenuHost Function(TActivity activity) castMenuHost;
  final TMenuProvider Function(
    void Function(TMenu menu, TMenuInflater menuInflater) onCreateMenu,
    bool Function(TMenuItem menuItem) onMenuItemSelected,
  )
  createMenuProvider;
  final void Function(
    TMenuHost menuHost,
    TMenuProvider menuProvider,
    TLifecycleOwner lifecycleOwner,
    TLifecycleState lifecycleState,
  )
  addMenuProvider;
  final TLifecycleOwner Function() readViewLifecycleOwner;
  final TLifecycleState Function() readResumedLifecycleState;
  final TMenuResource Function() readCardTemplateEditorMenuResource;
  final void Function(
    TMenuInflater menuInflater,
    TMenuResource resource,
    TMenu menu,
  )
  inflateMenu;
  final void Function(TMenu menu) setupCommonMenu;
  final bool Function(TMenuItem menuItem) handleCommonMenuItemSelected;
}

/// Registers the source menu provider at the fragment view's RESUMED state.
///
/// The Activity lookup and MenuHost cast happen immediately and in that order.
/// Both provider callbacks remain lazy, with inflation before common-menu setup;
/// callback failures propagate unchanged and stop later work.
void cardTemplateFragmentSetupMenu<
  TActivity,
  TMenuHost,
  TMenu,
  TMenuInflater,
  TMenuItem,
  TLifecycleOwner,
  TLifecycleState,
  TMenuResource,
  TMenuProvider
>({
  required CardTemplateFragmentSetupMenuCallbacks<
    TActivity,
    TMenuHost,
    TMenu,
    TMenuInflater,
    TMenuItem,
    TLifecycleOwner,
    TLifecycleState,
    TMenuResource,
    TMenuProvider
  >
  callbacks,
}) {
  final activity = callbacks.requireActivity();
  final menuHost = callbacks.castMenuHost(activity);
  final menuProvider = callbacks.createMenuProvider((menu, menuInflater) {
    callbacks.inflateMenu(
      menuInflater,
      callbacks.readCardTemplateEditorMenuResource(),
      menu,
    );
    callbacks.setupCommonMenu(menu);
  }, (menuItem) => callbacks.handleCommonMenuItemSelected(menuItem));
  callbacks.addMenuProvider(
    menuHost,
    menuProvider,
    callbacks.readViewLifecycleOwner(),
    callbacks.readResumedLifecycleState(),
  );
}
