// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/generic.pb.dart' as generic;

import 'base91.dart';
import 'card.dart' show InvalidModelValue;

/// A note field's ordinal, name and official backend configuration.
class NoteField {
  NoteField({int? ord, this.name = '', required this.config})
      : ord = ord?.toUnsigned(32);

  final int? ord;
  String name;
  final proto.Notetype_Field_Config config;

  /// Create a field with the defaults from Anki Core's `NoteField::new()`.
  factory NoteField.newField(
    String name, {
    required BigInt Function() randomU64,
  }) =>
      NoteField(
        name: name,
        config: proto.Notetype_Field_Config(
          id: int64FromRandomU64(randomU64()),
          fontName: 'Arial',
          fontSize: 20,
        ),
      );

  factory NoteField.fromProto(proto.Notetype_Field value) => NoteField(
        ord: value.hasOrd() ? value.ord.val : null,
        name: value.name,
        config:
            value.hasConfig() ? value.config : proto.Notetype_Field_Config(),
      );

  /// Apply the field-name cleanup rules from Anki Core before saving.
  void fixName() {
    if (name.isEmpty) throw const InvalidModelValue('Empty field name');
    name = name.replaceAll(RegExp(r'[:{}"]'), '');
    final trimmedWhitespace = _trimRustWhitespace(name);
    final runes = trimmedWhitespace.runes.toList(growable: false);
    var start = 0;
    while (start < runes.length &&
        (runes[start] == 0x23 ||
            runes[start] == 0x2f ||
            runes[start] == 0x5e ||
            _isRustCharWhitespace(runes[start]))) {
      start++;
    }
    final trimmed = String.fromCharCodes(runes.skip(start));
    if (trimmed.isEmpty) {
      throw InvalidModelValue('Field name: $name');
    }
    if (trimmed.length != name.length) name = trimmed;
  }

  String _trimRustWhitespace(String value) {
    final runes = value.runes.toList(growable: false);
    var start = 0;
    var end = runes.length;
    while (start < end && _isRustCharWhitespace(runes[start])) {
      start++;
    }
    while (end > start && _isRustCharWhitespace(runes[end - 1])) {
      end--;
    }
    return String.fromCharCodes(runes.sublist(start, end));
  }

  bool _isRustCharWhitespace(int rune) =>
      (rune >= 0x9 && rune <= 0xd) ||
      rune == 0x20 ||
      rune == 0x85 ||
      rune == 0xa0 ||
      rune == 0x1680 ||
      (rune >= 0x2000 && rune <= 0x200a) ||
      rune == 0x2028 ||
      rune == 0x2029 ||
      rune == 0x202f ||
      rune == 0x205f ||
      rune == 0x3000;

  proto.Notetype_Field toProto() => proto.Notetype_Field(
        ord: ord == null ? null : generic.UInt32(val: ord!),
        name: name,
        config: config,
      );
}
