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
 * Source-derived from Collection.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('collectionBuildSearchString', () {
    test('passes one identical node in source order', () {
      final node = Object();
      List<Object>? forwardedNodes;

      collectionBuildSearchString<Object>(node, (nodes) {
        forwardedNodes = nodes;
        return 'query';
      });

      expect(forwardedNodes, hasLength(1));
      expect(identical(forwardedNodes!.single, node), isTrue);
    });

    test('passes an unmodifiable singleton list', () {
      final node = Object();

      expect(
        () => collectionBuildSearchString<Object>(node, (nodes) {
          nodes.add(Object());
          return 'unreachable';
        }),
        throwsUnsupportedError,
      );
    });

    test('invokes the collection callback exactly once', () {
      var calls = 0;

      collectionBuildSearchString<Object>(Object(), (nodes) {
        calls++;
        return 'query';
      });

      expect(calls, 1);
    });

    test('returns the exact collection result', () {
      const result = 'backend search string';

      final actual = collectionBuildSearchString<Object>(
        Object(),
        (_) => result,
      );

      expect(actual, same(result));
    });

    test('propagates the exact collection failure', () {
      final failure = StateError('collection search failed');

      expect(
        () =>
            collectionBuildSearchString<Object>(Object(), (_) => throw failure),
        throwsA(same(failure)),
      );
    });
  });

  group('collectionBuildSearchStringFromTerms', () {
    test(
      'validates every entry before constructing any node or calling backend',
      () {
        final events = <String>[];
        final first = Object();
        final invalid = 42;
        final terms = ['tag:one', first, invalid];

        expect(
          () => collectionBuildSearchStringFromTerms<Object, String, String>(
            stringsOrSearchNodes: terms,
            joiner: 'OR',
            isSearchNode: (value) {
              events.add('is:${identical(value, first) ? 'node' : value}');
              return identical(value, first);
            },
            searchNodeFromString: (term) {
              events.add('text:$term');
              return Object();
            },
            toBackendJoiner: (joiner) {
              events.add('joiner');
              return joiner;
            },
            groupSearchNodes: (nodes, joiner) {
              events.add('group');
              return Object();
            },
            buildSearchString: (_) {
              events.add('backend');
              return 'unreachable';
            },
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'buildSearchString expects a list containing Strings or '
                  'SearchNodes: $terms',
            ),
          ),
        );

        expect(events, ['is:node', 'is:42']);
      },
    );

    test('rejects an empty list before backend construction', () {
      final events = <String>[];

      expect(
        () => collectionBuildSearchStringFromTerms<Object, String, String>(
          stringsOrSearchNodes: const [],
          joiner: 'AND',
          isSearchNode: (_) {
            events.add('is');
            return false;
          },
          searchNodeFromString: (_) {
            events.add('text');
            return Object();
          },
          toBackendJoiner: (joiner) {
            events.add('joiner');
            return joiner;
          },
          groupSearchNodes: (_, _) {
            events.add('group');
            return Object();
          },
          buildSearchString: (_) {
            events.add('backend');
            return 'unreachable';
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(events, isEmpty);
    });

    test(
      'converts mixed terms once in order and groups with the supplied joiner',
      () {
        final events = <String>[];
        final nodeA = Object();
        final nodeB = Object();
        final joiner = 'OR';
        final backendJoiner = Object();
        final grouped = Object();
        final result = String.fromCharCodes([113, 117, 101, 114, 121]);

        final actual =
            collectionBuildSearchStringFromTerms<Object, String, Object>(
              stringsOrSearchNodes: ['tag:first', nodeA, 'deck:second', nodeB],
              joiner: joiner,
              isSearchNode: (value) {
                events.add('is:${identical(value, nodeA) ? 'a' : 'b'}');
                return identical(value, nodeA) || identical(value, nodeB);
              },
              searchNodeFromString: (term) {
                events.add('text:$term');
                return term == 'tag:first' ? nodeB : nodeA;
              },
              toBackendJoiner: (actualJoiner) {
                events.add('joiner');
                expect(identical(actualJoiner, joiner), isTrue);
                return backendJoiner;
              },
              groupSearchNodes: (nodes, actualJoiner) {
                events.add('group');
                expect(nodes, hasLength(4));
                expect(identical(nodes[0], nodeB), isTrue);
                expect(identical(nodes[1], nodeA), isTrue);
                expect(identical(nodes[2], nodeA), isTrue);
                expect(identical(nodes[3], nodeB), isTrue);
                expect(identical(actualJoiner, backendJoiner), isTrue);
                expect(() => nodes.add(Object()), throwsUnsupportedError);
                return grouped;
              },
              buildSearchString: (node) {
                events.add('backend');
                expect(identical(node, grouped), isTrue);
                return result;
              },
            );

        expect(actual, same(result));
        expect(events, [
          'is:a',
          'is:b',
          'text:tag:first',
          'text:deck:second',
          'joiner',
          'group',
          'backend',
        ]);
      },
    );

    test(
      'passes one accepted node through without grouping or joiner conversion',
      () {
        final events = <String>[];
        final node = Object();
        final result = String.fromCharCodes([111, 107]);

        final actual =
            collectionBuildSearchStringFromTerms<Object, Object, Object>(
              stringsOrSearchNodes: [node],
              joiner: Object(),
              isSearchNode: (value) {
                events.add('validate');
                return identical(value, node);
              },
              searchNodeFromString: (_) {
                events.add('text');
                return Object();
              },
              toBackendJoiner: (_) {
                events.add('joiner');
                return Object();
              },
              groupSearchNodes: (_, _) {
                events.add('group');
                return Object();
              },
              buildSearchString: (actualNode) {
                events.add('backend');
                expect(identical(actualNode, node), isTrue);
                return result;
              },
            );

        expect(actual, same(result));
        expect(events, ['validate', 'backend']);
      },
    );

    test('converts one String then passes the converted node directly', () {
      final events = <String>[];
      final node = Object();

      collectionBuildSearchStringFromTerms<Object, Object, Object>(
        stringsOrSearchNodes: ['tag:one'],
        joiner: Object(),
        isSearchNode: (_) => fail('String should not be checked as SearchNode'),
        searchNodeFromString: (term) {
          events.add('text:$term');
          return node;
        },
        toBackendJoiner: (_) => fail('single node should not convert joiner'),
        groupSearchNodes: (_, _) => fail('single node should not be grouped'),
        buildSearchString: (actualNode) {
          events.add('backend');
          expect(identical(actualNode, node), isTrue);
          return 'query';
        },
      );

      expect(events, ['text:tag:one', 'backend']);
    });

    test('propagates text-node, group, and backend failures unchanged', () {
      final textFailure = StateError('node construction failed');
      final textEvents = <String>[];
      expect(
        () => collectionBuildSearchStringFromTerms<Object, String, String>(
          stringsOrSearchNodes: ['tag:one', 'tag:two'],
          joiner: 'OR',
          isSearchNode: (_) => false,
          searchNodeFromString: (_) {
            textEvents.add('text');
            throw textFailure;
          },
          toBackendJoiner: (_) => 'OR',
          groupSearchNodes: (_, _) {
            textEvents.add('group');
            return Object();
          },
          buildSearchString: (_) {
            textEvents.add('backend');
            return 'unreachable';
          },
        ),
        throwsA(same(textFailure)),
      );
      expect(textEvents, ['text']);

      final groupFailure = StateError('group construction failed');
      final groupEvents = <String>[];
      expect(
        () => collectionBuildSearchStringFromTerms<Object, String, String>(
          stringsOrSearchNodes: ['tag:one', 'tag:two'],
          joiner: 'OR',
          isSearchNode: (_) => false,
          searchNodeFromString: (term) => Object(),
          toBackendJoiner: (_) => 'OR',
          groupSearchNodes: (_, _) {
            groupEvents.add('group');
            throw groupFailure;
          },
          buildSearchString: (_) {
            groupEvents.add('backend');
            return 'unreachable';
          },
        ),
        throwsA(same(groupFailure)),
      );
      expect(groupEvents, ['group']);

      final joinerFailure = StateError('joiner conversion failed');
      final joinerEvents = <String>[];
      expect(
        () => collectionBuildSearchStringFromTerms<Object, String, String>(
          stringsOrSearchNodes: ['tag:one', 'tag:two'],
          joiner: 'OR',
          isSearchNode: (_) => false,
          searchNodeFromString: (_) => Object(),
          toBackendJoiner: (_) {
            joinerEvents.add('joiner');
            throw joinerFailure;
          },
          groupSearchNodes: (_, _) {
            joinerEvents.add('group');
            return Object();
          },
          buildSearchString: (_) {
            joinerEvents.add('backend');
            return 'unreachable';
          },
        ),
        throwsA(same(joinerFailure)),
      );
      expect(joinerEvents, ['joiner']);

      final backendFailure = StateError('backend failed');
      expect(
        () => collectionBuildSearchStringFromTerms<Object, String, String>(
          stringsOrSearchNodes: ['tag:one'],
          joiner: 'OR',
          isSearchNode: (_) => false,
          searchNodeFromString: (_) => Object(),
          toBackendJoiner: (_) => 'OR',
          groupSearchNodes: (_, _) => fail('single node should not be grouped'),
          buildSearchString: (_) => throw backendFailure,
        ),
        throwsA(same(backendFailure)),
      );
    });
  });
}
