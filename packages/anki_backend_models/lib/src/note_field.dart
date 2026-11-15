// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/generic.pb.dart' as generic;

/// A note field's ordinal, name and official backend configuration.
class NoteField {
  NoteField({
    int? ord,
    this.name = '',
    required this.config,
  }) : ord = ord?.toUnsigned(32);

  final int? ord;
  final String name;
  final proto.Notetype_Field_Config config;

  factory NoteField.fromProto(proto.Notetype_Field value) => NoteField(
        ord: value.hasOrd() ? value.ord.val : null,
        name: value.name,
        config:
            value.hasConfig() ? value.config : proto.Notetype_Field_Config(),
      );

  proto.Notetype_Field toProto() => proto.Notetype_Field(
        ord: ord == null ? null : generic.UInt32(val: ord!),
        name: name,
        config: config,
      );
}
