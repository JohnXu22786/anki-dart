// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright: Ankitects Pty Ltd and contributors
// License: GNU AGPL, version 3 or later; http://www.gnu.org/licenses/agpl.html

import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/generic.pb.dart' as generic;
import 'package:fixnum/fixnum.dart';

import 'base91.dart';

/// A card template's ordinal, modification values and official config.
class CardTemplate {
  CardTemplate({
    int? ord,
    Int64? mtimeSecs,
    int usn = 0,
    this.name = '',
    required this.config,
  }) : ord = ord?.toUnsigned(32),
       mtimeSecs = mtimeSecs ?? Int64.ZERO,
       usn = usn.toSigned(32);

  final int? ord;
  final Int64 mtimeSecs;
  final int usn;
  final String name;
  final proto.Notetype_Template_Config config;

  /// Create a template with the defaults from Anki Core's
  /// `CardTemplate::new()`.
  factory CardTemplate.newTemplate(
    String name,
    String questionFormat,
    String answerFormat, {
    required BigInt Function() randomU64,
  }) => CardTemplate(
    name: name,
    config: proto.Notetype_Template_Config(
      qFormat: questionFormat,
      aFormat: answerFormat,
      id: int64FromRandomU64(randomU64()),
    ),
  );

  factory CardTemplate.fromProto(proto.Notetype_Template value) => CardTemplate(
    ord: value.hasOrd() ? value.ord.val : null,
    mtimeSecs: value.mtimeSecs,
    usn: value.usn,
    name: value.name,
    config: value.hasConfig() ? value.config : proto.Notetype_Template_Config(),
  );

  proto.Notetype_Template toProto() => proto.Notetype_Template(
    ord: ord == null ? null : generic.UInt32(val: ord!),
    mtimeSecs: mtimeSecs,
    usn: usn,
    name: name,
    config: config,
  );
}
