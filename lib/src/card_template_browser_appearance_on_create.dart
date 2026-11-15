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
 * Source-derived from CardTemplateBrowserAppearanceEditor.kt in AnkiDroid
 * 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Projects the source-ordered host callbacks from Browser Appearance onCreate.
///
/// The host owns Android lifecycle, insets, Bundle/Intent, toast, Activity
/// result, and listener registration. Saved-state and intent-extras values stay
/// opaque; the intent callback is read only when [savedInstanceState] is null.
/// Callback failures propagate and prevent later source-ordered work.
void createBrowserAppearanceEditor<Bundle>({
  required bool Function(Bundle?) showedActivityFailedScreen,
  required void Function(Bundle?) superOnCreate,
  required void Function() enableEdgeToEdge,
  required void Function() installToolbarInsetsListener,
  required void Function() installContentInsetsListener,
  required Bundle? savedInstanceState,
  required Bundle? Function() readIntentExtras,
  required void Function() showThemedErrorToast,
  required void Function() finish,
  required void Function(Bundle) initializeFromBundle,
  required void Function() setResultCanceled,
  required void Function() registerBackCallback,
  required void Function(void Function(Object?) listener)
  addQuestionTextListener,
  required void Function(void Function(Object?) listener) addAnswerTextListener,
  required bool Function() hasChanges,
  required void Function(bool enabled) setDiscardCallbackEnabled,
}) {
  if (showedActivityFailedScreen(savedInstanceState)) return;

  superOnCreate(savedInstanceState);
  enableEdgeToEdge();
  installToolbarInsetsListener();
  installContentInsetsListener();

  final bundle = savedInstanceState ?? readIntentExtras();
  if (bundle == null) {
    showThemedErrorToast();
    finish();
    return;
  }

  initializeFromBundle(bundle);
  setResultCanceled();
  registerBackCallback();
  addQuestionTextListener((_) {
    setDiscardCallbackEnabled(hasChanges());
  });
  addAnswerTextListener((_) {
    setDiscardCallbackEnabled(hasChanges());
  });
}
