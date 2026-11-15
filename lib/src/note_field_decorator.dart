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
 * Source-derived from NoteFieldDecorator.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

/// Compares two strings with Kotlin/JVM `String.equals(ignoreCase = true)`.
///
/// The host supplies JVM-compatible case folding; Dart's own case folding does
/// not define the source platform's comparison behavior.
typedef NoteFieldEqualsIgnoreCase =
    bool Function(String option, String? transformedField);

/// Selects an index below [exclusiveUpperBound], as `Random.nextInt` does.
///
/// The host owns random generation and must return a value in the requested
/// range. This adapter does not add its own randomness or seed behavior.
typedef NoteFieldNextRandomIndex = int Function(int exclusiveUpperBound);

const _huevoDecorations = <String>[
  '\u{1F48C}',
  '\u{1F63B}',
  '\u{1F496}',
  '\u{1F497}',
  '\u{1F493}',
  '\u{1F49E}',
  '\u{1F495}',
  '\u{1F49F}',
  '\u{1F4AF}',
  '\u{1F603}',
  '\u{1F60D}',
];

const _huevoOpciones = <String>[
  'qnr',
  'gvzenr',
  'aboantb',
  'avpbynf-enbhy',
  'Neguhe-Zvypuvbe',
  'zvxruneql',
  'qnivq-nyyvfba',
  'vavwh',
  'uffz',
  'syreqn',
  'rqh-mnzben',
  'ntehraroret',
  'bfcnyu',
  'znaqer',
  'qnavry-fineq',
  'vasvalgr7',
  'Oynvfbeoynqr',
  'genfuphggre',
  'qzvgel-gvzbsrri',
  'inabfgra',
  'unacvatpuvarfr',
  'jro5atnl',
  'FuevquneTbry',
  'Nxfunl0701',
  'ivpvbhfNrtvf',
  'gurqebvqqvi',
  'OenlnaQFB',
  'pevgvpnyNL',
  'fnawnlfnetnz',
  'krabaaa4j',
  'revpyv3690',
  'Unm3-wbyg',
  'fabjgvzrtynff',
  'hfre1823',
  'MbeaUnqAbPubvpr',
];

/// Applies the source's NoteFieldDecorator easter-egg behavior.
///
/// The field text is ROT13-transformed and compared against the source's
/// ordered encoded names. The host supplies Kotlin/JVM-compatible equality and
/// the bounded random index callback; either callback's error propagates
/// unchanged. The exact matched field text is retained in the decoration.
String? aplicaHuevo(
  String? fieldText, {
  required NoteFieldEqualsIgnoreCase equalsIgnoreCase,
  required NoteFieldNextRandomIndex nextRandomIndex,
}) {
  final transformedField = _huevoRevuelto(fieldText);
  for (final option in _huevoOpciones) {
    if (equalsIgnoreCase(option, transformedField)) {
      final decoration =
          _huevoDecorations[nextRandomIndex(_huevoDecorations.length)];
      return '$decoration$decoration $fieldText $decoration$decoration';
    }
  }
  return fieldText;
}

String? _huevoRevuelto(String? huevo) {
  if (huevo == null || huevo.isEmpty) return huevo;
  final result = StringBuffer();
  for (final codeUnit in huevo.codeUnits) {
    var transformed = codeUnit;
    if (transformed >= 0x61 && transformed <= 0x6d ||
        transformed >= 0x41 && transformed <= 0x4d) {
      transformed += 13;
    } else if (transformed >= 0x6e && transformed <= 0x7a ||
        transformed >= 0x4e && transformed <= 0x5a) {
      transformed -= 13;
    }
    result.writeCharCode(transformed);
  }
  return result.toString();
}
