// SPDX-License-Identifier: AGPL-3.0-or-later
// Port of Anki Core rslib/src/search/builder.rs.
import 'package:fixnum/fixnum.dart';

import 'search_ast.dart';
import 'writer.dart';

/// A small, composable builder for searches represented by the shared AST.
final class SearchBuilder {
  SearchBuilder() : _nodes = const [];
  SearchBuilder._(this._nodes);

  final List<Node> _nodes;

  /// Creates a builder containing [node], unwrapping a root group.
  factory SearchBuilder.fromRoot(Node node) => switch (node) {
        GroupNode(:final nodes) => SearchBuilder._(List.unmodifiable(nodes)),
        _ => SearchBuilder._([node]),
      };

  /// Creates a builder whose nodes are joined by AND.
  factory SearchBuilder.all(Iterable<Object> values) =>
      SearchBuilder._(_interspersed(values, NodeKind.and));

  /// Creates a builder whose nodes are joined by OR.
  factory SearchBuilder.any(Iterable<Object> values) =>
      SearchBuilder._(_interspersed(values, NodeKind.or));

  factory SearchBuilder.fromDecks(Iterable<Int64> ids) =>
      SearchBuilder.fromRoot(
        Search(
          DeckIdsWithoutChildren(ids.map((id) => id.toString()).join(',')),
        ),
      );

  factory SearchBuilder.learningCards() =>
      SearchBuilder.fromValue(StateKind.learning)
          .and(StateKind.review.negated());

  factory SearchBuilder.relearningCards() =>
      SearchBuilder.fromValue(StateKind.learning).and(StateKind.review);

  factory SearchBuilder.fromValue(Object value) =>
      SearchBuilder.fromRoot(searchValueToNode(value));

  static List<Node> _interspersed(Iterable<Object> values, NodeKind kind) {
    final nodes = values.map(searchValueToNode).toList(growable: false);
    if (nodes.length < 2) return nodes;
    return List.unmodifiable([
      for (var i = 0; i < nodes.length; i++) ...[
        if (i > 0) BooleanNode(kind),
        nodes[i],
      ],
    ]);
  }

  bool get isEmpty => _nodes.isEmpty;

  /// Number of AST nodes, including boolean operators.
  int get length => _nodes.length;

  /// Wraps multiple nodes in a group; zero and one node remain unchanged.
  SearchBuilder group() =>
      _nodes.length > 1 ? SearchBuilder._([GroupNode(_nodes)]) : this;

  /// Serialize with the canonical search writer.
  String write() => writeNodes(_nodes);

  SearchBuilder and(Object other) => _join(other, NodeKind.and, group: true);
  SearchBuilder or(Object other) => _join(other, NodeKind.or, group: true);
  SearchBuilder andFlat(Object other) =>
      _join(other, NodeKind.and, group: false);
  SearchBuilder orFlat(Object other) => _join(other, NodeKind.or, group: false);

  SearchBuilder _join(Object other, NodeKind kind, {required bool group}) {
    final left = group ? this.group()._nodes : _nodes;
    final rightBuilder = searchValueToBuilder(other);
    final right = group ? rightBuilder.group()._nodes : rightBuilder._nodes;
    if (left.isEmpty) return SearchBuilder._(List.unmodifiable(right));
    if (right.isEmpty) return SearchBuilder._(List.unmodifiable(left));
    return SearchBuilder._([...left, BooleanNode(kind), ...right]);
  }
}

/// Programmatic constructors corresponding to Anki Core's `SearchNode` helpers.
abstract final class SearchNodeBuilder {
  static SearchNode fromDeckId(Int64 id, {bool withChildren = false}) =>
      withChildren ? DeckIdWithChildren(id) : DeckIdsWithoutChildren('$id');

  static SearchNode fromDeckName(String name) =>
      Deck(escapeAnkiWildcardsForSearchNode(name));

  static SearchNode fromTagName(String name) => Tag(
        tag: escapeAnkiWildcardsForSearchNode(name),
        mode: FieldSearchMode.normal,
      );

  static SearchNode fromNotetypeName(String name) =>
      Notetype(escapeAnkiWildcardsForSearchNode(name));

  static SearchNode fromTemplateName(String name) =>
      CardTemplate(TemplateName(escapeAnkiWildcardsForSearchNode(name)));

  static SearchNode fromNoteIds(Iterable<Int64> ids) =>
      NoteIds(ids.map((id) => id.toString()).join(','));

  static SearchNode fromCardIds(Iterable<Int64> ids) =>
      CardIds(ids.map((id) => id.toString()).join(','));

  static SearchNode fromNotetypeId(Int64 id) => NotetypeIdSearch(id);
  static SearchNode fromTemplateKind(TemplateKind kind) => CardTemplate(kind);
  static SearchNode fromNoteId(Int64 id) => NoteIds(id.toString());
  static SearchNode fromStateKind(StateKind kind) => State(kind);
}

/// Convert a value accepted by the source builder into one AST node.
Node searchValueToNode(Object value) => switch (value) {
      Node() => value,
      SearchNode() => Search(value),
      StateKind() => Search(State(value)),
      TemplateKind() => Search(CardTemplate(value)),
      _ =>
        throw ArgumentError.value(value, 'value', 'Unsupported search value'),
    };

SearchBuilder searchValueToBuilder(Object value) => switch (value) {
      SearchBuilder() => value,
      _ => SearchBuilder.fromRoot(searchValueToNode(value)),
    };

/// Negate a value, removing one existing negation when present.
extension SearchNegation on Object {
  Node negated() {
    final node = searchValueToNode(this);
    return node is NegatedNode ? node.node : NegatedNode(node);
  }
}

/// Preserve the source builder's typed-ID conversions despite Dart's Int64
/// representation being shared by its NoteId and NotetypeId aliases.
extension SearchInt64Conversions on Int64 {
  Node asNotetypeIdNode() => Search(NotetypeIdSearch(this));
  Node asNoteIdNode() => Search(NoteIds(toString()));
}

extension SearchNodeNodeConversion on SearchNode {
  Node toNode() => Search(this);
}

extension SearchValueNodeConversion on StateKind {
  Node toNode() => Search(State(this));
}

extension TemplateKindNodeConversion on TemplateKind {
  Node toNode() => Search(CardTemplate(this));
}
