// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'card_template.dart';
import 'note_field.dart';
import 'unicode_casefold.dart';

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
/// [ankiDefault], [defaultConfig] and [clozeConfig] reproduce Anki Core's
/// default CSS and LaTeX assets. When [fromProto] receives a protobuf with no
/// `config`, it uses the generated protocol message's default config, matching
/// the service conversion behavior.
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
  String name;
  final Int64 mtimeSecs;
  final int usn;
  final List<NoteField> fields;
  final List<CardTemplate> templates;
  final proto.Notetype_Config config;

  /// The stored defaults created by Anki Core's `Notetype::default()`.
  factory Notetype.ankiDefault() => Notetype(config: defaultConfig());

  /// Build the exact default configuration from Anki Core's pinned CSS and
  /// LaTeX assets.
  static proto.Notetype_Config defaultConfig() => proto.Notetype_Config(
        css: defaultCss,
        latexPre: defaultLatexHeader,
        latexPost: defaultLatexFooter,
      );

  /// Build the exact default configuration used for cloze note types.
  static proto.Notetype_Config clozeConfig() => proto.Notetype_Config(
        kind: proto.Notetype_Config_Kind.KIND_CLOZE,
        css: '$defaultCss$defaultClozeCss',
        latexPre: defaultLatexHeader,
        latexPost: defaultLatexFooter,
      );

  static const defaultCss = '.card {\n'
      '    font-family: arial;\n'
      '    font-size: 20px;\n'
      '    line-height: 1.5;\n'
      '    text-align: center;\n'
      '    color: black;\n'
      '    background-color: white;\n'
      '}\n';

  static const defaultClozeCss = '.cloze {\n'
      '    font-weight: bold;\n'
      '    color: blue;\n'
      '}\n'
      '.nightMode .cloze {\n'
      '    color: lightblue;\n'
      '}\n';

  static const defaultLatexHeader = r'\documentclass[12pt]{article}'
      '\n'
      r'\special{papersize=3in,5in}'
      '\n'
      r'\usepackage[utf8]{inputenc}'
      '\n'
      r'\usepackage{amssymb,amsmath}'
      '\n'
      r'\pagestyle{empty}'
      '\n'
      r'\setlength{\parindent}{0in}'
      '\n'
      r'\begin{document}'
      '\n';

  static const defaultLatexFooter = r'\end{document}';

  factory Notetype.fromProto(proto.Notetype value) => Notetype(
        id: NotetypeId(value.id),
        name: value.name,
        mtimeSecs: value.mtimeSecs,
        usn: value.usn,
        fields: value.fields.map(NoteField.fromProto).toList(),
        templates: value.templates.map(CardTemplate.fromProto).toList(),
        config: value.hasConfig() ? value.config : proto.Notetype_Config(),
      );

  /// Normalize this notetype and all child names to Unicode NFC.
  void normalizeNames() {
    name = unorm.nfc(name);
    for (final field in fields) {
      field.name = unorm.nfc(field.name);
    }
    for (final template in templates) {
      template.name = unorm.nfc(template.name);
    }
  }

  /// Fix field names in order, stopping at the first invalid name.
  void fixFieldNames() {
    for (final field in fields) {
      field.fixName();
    }
  }

  /// Fix template names in order, stopping at the first invalid name.
  void fixTemplateNames() {
    for (final template in templates) {
      template.fixName();
    }
  }

  /// Append `+` to repeated template and field names like Anki Core.
  void ensureNamesUnique() {
    _ensureNamesUnique(templates.map((template) => template.name).toList(),
        (index, name) => templates[index].name = name);
    _ensureNamesUnique(fields.map((field) => field.name).toList(),
        (index, name) => fields[index].name = name);
  }

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

void _ensureNamesUnique(
  List<String> names,
  void Function(int index, String name) assign,
) {
  final seen = <String>{};
  for (var index = 0; index < names.length; index++) {
    var name = names[index];
    while (!seen.add(unicodeCaseFold(name))) {
      name = '$name+';
    }
    assign(index, name);
  }
}
