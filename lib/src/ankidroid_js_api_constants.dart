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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Adapted from AnkiDroidJsAPIConstants.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'gesture_command_router.dart';

const ANKI_JS_ERROR_CODE_ERROR = -1;
const ANKI_JS_ERROR_CODE_DEFAULT = 0;
const ANKI_JS_ERROR_CODE_MARK_CARD = 1;
const ANKI_JS_ERROR_CODE_FLAG_CARD = 2;
const ANKI_JS_ERROR_CODE_BURY_CARD = 3;
const ANKI_JS_ERROR_CODE_SUSPEND_CARD = 4;
const ANKI_JS_ERROR_CODE_BURT_NOTE = 5;
const ANKI_JS_ERROR_CODE_SUSPEND_NOTE = 6;
const ANKI_JS_ERROR_CODE_SET_DUE = 7;
const ANKI_JS_ERROR_CODE_SEARCH_CARD = 8;

const currentJsApiVersion = '0.0.3';
const minimumJsApiVersion = '0.0.3';
const VALUE_KEY = 'value';
const SUCCESS_KEY = 'success';

/// Maps the JS API flag names to source-identical reviewer command values.
const flagCommands = <String, ViewerCommand>{
  'none': ViewerCommand.UNSET_FLAG,
  'red': ViewerCommand.TOGGLE_FLAG_RED,
  'orange': ViewerCommand.TOGGLE_FLAG_ORANGE,
  'green': ViewerCommand.TOGGLE_FLAG_GREEN,
  'blue': ViewerCommand.TOGGLE_FLAG_BLUE,
  'pink': ViewerCommand.TOGGLE_FLAG_PINK,
  'turquoise': ViewerCommand.TOGGLE_FLAG_TURQUOISE,
  'purple': ViewerCommand.TOGGLE_FLAG_PURPLE,
};
