// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

import 'card_template.dart';
import 'note_field.dart';

/// The signed 64-bit identity used for Anki note types.
class NotetypeId {
  NotetypeId(this.value);

  final Int64 value;

  @override
  bool operator ==(Object other) => other is NotetypeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();

  factory NotetypeId.fromProto(proto.NotetypeId value) =>
      NotetypeId(value.ntid);

  proto.NotetypeId toProto() => proto.NotetypeId(ntid: value);
}

/// Stored Anki note type values and their official backend configuration.
///
/// The upstream default constructor fills CSS and LaTeX assets that are outside
/// this conversion slice. When an incoming protobuf omits `config`, this model
/// uses the generated protocol message's default config, as the service
/// conversion does.
class Notetype {
  Notetype({
    NotetypeId? id,
    this.name = '',
    Int64? mtimeSecs,
    int usn = 0,
    List<NoteField> fields = const [],
    List<CardTemplate> templates = const [],
    required this.config,
  })  : id = id ?? NotetypeId(Int64.ZERO),
        mtimeSecs = mtimeSecs ?? Int64.ZERO,
        usn = usn.toSigned(32),
        fields = List<NoteField>.of(fields),
        templates = List<CardTemplate>.of(templates);

  final NotetypeId id;
  final String name;
  final Int64 mtimeSecs;
  final int usn;
  final List<NoteField> fields;
  final List<CardTemplate> templates;
  final proto.Notetype_Config config;

  factory Notetype.fromProto(proto.Notetype value) => Notetype(
        id: NotetypeId(value.id),
        name: value.name,
        mtimeSecs: value.mtimeSecs,
        usn: value.usn,
        fields: value.fields.map(NoteField.fromProto).toList(),
        templates: value.templates.map(CardTemplate.fromProto).toList(),
        config: value.hasConfig() ? value.config : proto.Notetype_Config(),
      );

  proto.Notetype toProto() => proto.Notetype(
        id: id.value,
        name: name,
        mtimeSecs: mtimeSecs,
        usn: usn,
        fields: fields.map((field) => field.toProto()).toList(),
        templates: templates.map((template) => template.toProto()).toList(),
        config: config,
      );
}
