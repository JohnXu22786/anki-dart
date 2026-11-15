/*
 * Copyright (c) 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * Copyright (c) 2012 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2022 Ankitects Pty Ltd <http://apps.ankiweb.net>
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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2012 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'dart:typed_data';

/// Forwards `Collection.evaluateParamsLegacyRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionEvaluateParamsLegacyRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) evaluateParamsLegacyRaw,
}) => evaluateParamsLegacyRaw(input);

/// Forwards `Collection.congratsInfoRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionCongratsInfoRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) congratsInfoRaw,
}) => congratsInfoRaw(input);

/// Forwards `Collection.getChangeNotetypeInfoRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionGetChangeNotetypeInfoRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) getChangeNotetypeInfoRaw,
}) => getChangeNotetypeInfoRaw(input);

/// Forwards `Collection.changeNotetypeRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionChangeNotetypeRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) changeNotetypeRaw,
}) => changeNotetypeRaw(input);

/// Forwards `Collection.importJsonStringRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionImportJsonStringRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) importJsonStringRaw,
}) => importJsonStringRaw(input);

/// Forwards `Collection.importJsonFileRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionImportJsonFileRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) importJsonFileRaw,
}) => importJsonFileRaw(input);

/// Forwards `Collection.getIgnoredBeforeCountRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionGetIgnoredBeforeCountRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) getIgnoredBeforeCountRaw,
}) => getIgnoredBeforeCountRaw(input);

/// Forwards `Collection.getRetentionWorkloadRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionGetRetentionWorkloadRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) getRetentionWorkloadRaw,
}) => getRetentionWorkloadRaw(input);

/// Forwards `Collection.simulateFsrsWorkloadRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionSimulateFsrsWorkloadRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) simulateFsrsWorkloadRaw,
}) => simulateFsrsWorkloadRaw(input);

/// Forwards `Collection.getCustomColoursRaw(input)` to the host unchanged.
///
/// The host owns request and response serialization and backend behavior.
/// Callback failures propagate unchanged.
Uint8List collectionGetCustomColoursRaw(
  Uint8List input, {
  required Uint8List Function(Uint8List input) getCustomColoursRaw,
}) => getCustomColoursRaw(input);
