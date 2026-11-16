// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/decks.pb.dart' as proto;
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as config_proto;
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'card.dart' show InvalidModelValue;

typedef DeckId = Int64;

String _humanDeckName(String value) => value.split('::').map((component) {
      final normalized = unorm.nfc(
        String.fromCharCodes(
          component.runes.where((rune) => !(rune <= 0x1f || rune == 0x7f)),
        ),
      );
      final runes = normalized.runes.toList(growable: false);
      var start = 0;
      var end = runes.length;
      while (start < end && _isRustDeckWhitespaceOrColon(runes[start])) {
        start++;
      }
      while (end > start && _isRustDeckWhitespaceOrColon(runes[end - 1])) {
        end--;
      }
      final trimmed = String.fromCharCodes(runes.sublist(start, end));
      return trimmed.isEmpty ? 'blank' : trimmed;
    }).join('::');

/// Normalizes a human-readable deck name using Anki Core's component rules.
String normalizeDeckName(String value) => _humanDeckName(value);

bool _isRustDeckWhitespaceOrColon(int rune) =>
    rune == 0x3a ||
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

sealed class DeckKind {
  const DeckKind();

  factory DeckKind.normal(proto.Deck_Normal value) = NormalDeckKind;
  factory DeckKind.filtered(proto.Deck_Filtered value) = FilteredDeckKind;

  factory DeckKind.fromProto(proto.Deck value) => switch (value.whichKind()) {
        proto.Deck_Kind.normal => NormalDeckKind(value.normal.deepCopy()),
        proto.Deck_Kind.filtered => FilteredDeckKind(value.filtered.deepCopy()),
        proto.Deck_Kind.notSet => throw const InvalidModelValue('missing kind'),
      };
}

final class NormalDeckKind extends DeckKind {
  NormalDeckKind(proto.Deck_Normal value) : value = value.deepCopy();
  final proto.Deck_Normal value;
}

final class FilteredDeckKind extends DeckKind {
  FilteredDeckKind(proto.Deck_Filtered value) : value = value.deepCopy();
  final proto.Deck_Filtered value;
}

/// Stored common deck values plus the normal or filtered deck payload.
class Deck {
  Deck({
    this.id = Int64.ZERO,
    this.name = '',
    this.mtimeSecs = Int64.ZERO,
    int usn = 0,
    proto.Deck_Common? common,
    required this.kind,
  })  : usn = usn.toSigned(32),
        common = (common ?? proto.Deck_Common()).deepCopy();

  factory Deck.newNormal() => Deck(
        common: proto.Deck_Common(studyCollapsed: true, browserCollapsed: true),
        kind: NormalDeckKind(proto.Deck_Normal(configId: Int64.ONE)),
      );

  factory Deck.fromProto(proto.Deck value) => Deck(
        id: value.id,
        name: normalizeDeckName(value.name),
        mtimeSecs: value.mtimeSecs,
        usn: value.usn,
        common: value.hasCommon() ? value.common : null,
        kind: DeckKind.fromProto(value),
      );

  final DeckId id;
  final String name;
  final Int64 mtimeSecs;
  final int usn;
  final proto.Deck_Common common;
  final DeckKind kind;

  Int64? get configId => switch (kind) {
        NormalDeckKind(:final value) => value.configId,
        FilteredDeckKind() => null,
      };

  double effectiveDesiredRetention(config_proto.DeckConfig_Config config) =>
      switch (kind) {
        NormalDeckKind(:final value) => value.hasDesiredRetention()
            ? value.desiredRetention
            : config.desiredRetention,
        FilteredDeckKind() => config.desiredRetention,
      };

  proto.Deck toProto() => proto.Deck(
        id: id,
        name: name,
        mtimeSecs: mtimeSecs,
        usn: usn,
        common: common.deepCopy(),
        normal: switch (kind) {
          NormalDeckKind(:final value) => value.deepCopy(),
          FilteredDeckKind() => null,
        },
        filtered: switch (kind) {
          NormalDeckKind() => null,
          FilteredDeckKind(:final value) => value.deepCopy(),
        },
      );
}
