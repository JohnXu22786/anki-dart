// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/search.pbenum.dart' as proto;
import 'package:fixnum/fixnum.dart';

typedef DeckId = Int64;
typedef NotetypeId = Int64;

enum FieldSearchMode { normal, regex, noCombining }

extension FieldSearchModeProto on FieldSearchMode {
  proto.SearchNode_FieldSearchMode toProto() => switch (this) {
        FieldSearchMode.normal =>
          proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_NORMAL,
        FieldSearchMode.regex =>
          proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_REGEX,
        FieldSearchMode.noCombining =>
          proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_NOCOMBINING,
      };

  static FieldSearchMode fromProto(proto.SearchNode_FieldSearchMode mode) =>
      switch (mode) {
        proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_NORMAL =>
          FieldSearchMode.normal,
        proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_REGEX =>
          FieldSearchMode.regex,
        proto.SearchNode_FieldSearchMode.FIELD_SEARCH_MODE_NOCOMBINING =>
          FieldSearchMode.noCombining,
        _ =>
          throw ArgumentError.value(mode, 'mode', 'Unknown field search mode'),
      };
}

enum NodeKind { and, or }

sealed class Node {
  const Node();
}

final class BooleanNode extends Node {
  const BooleanNode(this.kind);
  final NodeKind kind;
  @override
  bool operator ==(Object other) => other is BooleanNode && other.kind == kind;
  @override
  int get hashCode => kind.hashCode;
}

final class NegatedNode extends Node {
  const NegatedNode(this.node);
  final Node node;
  @override
  bool operator ==(Object other) => other is NegatedNode && other.node == node;
  @override
  int get hashCode => node.hashCode;
}

final class GroupNode extends Node {
  const GroupNode(this.nodes);
  final List<Node> nodes;
  @override
  bool operator ==(Object other) =>
      other is GroupNode && _listEquals(other.nodes, nodes);
  @override
  int get hashCode => Object.hashAll(nodes);
}

final class Search extends Node {
  const Search(this.value);
  final SearchNode value;
  @override
  bool operator ==(Object other) => other is Search && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

sealed class SearchNode {
  const SearchNode();
}

final class TextSearch extends SearchNode {
  const TextSearch(this.text);
  final String text;
  @override
  bool operator ==(Object other) => other is TextSearch && other.text == text;
  @override
  int get hashCode => text.hashCode;
}

final class SingleFieldSearch extends SearchNode {
  const SingleFieldSearch(
      {required this.field, required this.text, required this.mode});
  final String field;
  final String text;
  final FieldSearchMode mode;
  @override
  bool operator ==(Object other) =>
      other is SingleFieldSearch &&
      other.field == field &&
      other.text == text &&
      other.mode == mode;
  @override
  int get hashCode => Object.hash(field, text, mode);
}

final class AddedInDays extends SearchNode {
  const AddedInDays(this.days);
  final int days;
}

final class EditedInDays extends SearchNode {
  const EditedInDays(this.days);
  final int days;
}

final class IntroducedInDays extends SearchNode {
  const IntroducedInDays(this.days);
  final int days;
}

final class CardTemplate extends SearchNode {
  const CardTemplate(this.kind);
  final TemplateKind kind;
}

final class Deck extends SearchNode {
  const Deck(this.name);
  final String name;
}

final class DeckIdsWithoutChildren extends SearchNode {
  const DeckIdsWithoutChildren(this.ids);
  final String ids;
}

final class DeckIdWithChildren extends SearchNode {
  const DeckIdWithChildren(this.id);
  final DeckId id;
}

final class NotetypeIdSearch extends SearchNode {
  const NotetypeIdSearch(this.id);
  final NotetypeId id;
}

final class Notetype extends SearchNode {
  const Notetype(this.name);
  final String name;
}

final class Rated extends SearchNode {
  const Rated({required this.days, required this.ease});
  final int days;
  final RatingKind ease;
}

final class Tag extends SearchNode {
  const Tag({required this.tag, required this.mode});
  final String tag;
  final FieldSearchMode mode;
}

final class Duplicates extends SearchNode {
  const Duplicates({required this.notetypeId, required this.text});
  final NotetypeId notetypeId;
  final String text;
}

final class State extends SearchNode {
  const State(this.kind);
  final StateKind kind;
}

final class Flag extends SearchNode {
  const Flag(this.value);
  final int value;
}

final class NoteIds extends SearchNode {
  const NoteIds(this.ids);
  final String ids;
}

final class CardIds extends SearchNode {
  const CardIds(this.ids);
  final String ids;
}

final class Property extends SearchNode {
  const Property({required this.operator, required this.kind});
  final String operator;
  final PropertyKind kind;
}

final class WholeCollection extends SearchNode {
  const WholeCollection();
}

final class RegexSearch extends SearchNode {
  const RegexSearch(this.pattern);
  final String pattern;
}

final class NoCombining extends SearchNode {
  const NoCombining(this.text);
  final String text;
}

final class StripClozes extends SearchNode {
  const StripClozes(this.text);
  final String text;
}

final class WordBoundary extends SearchNode {
  const WordBoundary(this.text);
  final String text;
}

final class CustomData extends SearchNode {
  const CustomData(this.value);
  final String value;
}

final class Preset extends SearchNode {
  const Preset(this.name);
  final String name;
}

sealed class PropertyKind {
  const PropertyKind();
}

final class DueProperty extends PropertyKind {
  const DueProperty(this.value);
  final int value;
}

final class IntervalProperty extends PropertyKind {
  const IntervalProperty(this.value);
  final int value;
}

final class RepsProperty extends PropertyKind {
  const RepsProperty(this.value);
  final int value;
}

final class LapsesProperty extends PropertyKind {
  const LapsesProperty(this.value);
  final int value;
}

final class EaseProperty extends PropertyKind {
  const EaseProperty(this.value);
  final double value;
}

final class PositionProperty extends PropertyKind {
  const PositionProperty(this.value);
  final int value;
}

final class RatedProperty extends PropertyKind {
  const RatedProperty(this.days, this.rating);
  final int days;
  final RatingKind rating;
}

final class StabilityProperty extends PropertyKind {
  const StabilityProperty(this.value);
  final double value;
}

final class DifficultyProperty extends PropertyKind {
  const DifficultyProperty(this.value);
  final double value;
}

final class RetrievabilityProperty extends PropertyKind {
  const RetrievabilityProperty(this.value);
  final double value;
}

final class CustomDataNumberProperty extends PropertyKind {
  const CustomDataNumberProperty({required this.key, required this.value});
  final String key;
  final double value;
}

final class CustomDataStringProperty extends PropertyKind {
  const CustomDataStringProperty({required this.key, required this.value});
  final String key;
  final String value;
}

enum StateKind {
  newCard,
  review,
  learning,
  due,
  buried,
  userBuried,
  schedBuried,
  suspended
}

sealed class TemplateKind {
  const TemplateKind();
}

final class TemplateOrdinal extends TemplateKind {
  const TemplateOrdinal(this.value);
  final int value;
}

final class TemplateName extends TemplateKind {
  const TemplateName(this.value);
  final String value;
}

sealed class RatingKind {
  const RatingKind();
}

final class AnswerButton extends RatingKind {
  const AnswerButton(this.value);
  final int value;
}

final class AnyAnswerButton extends RatingKind {
  const AnyAnswerButton();
}

final class ManualReschedule extends RatingKind {
  const ManualReschedule();
}
