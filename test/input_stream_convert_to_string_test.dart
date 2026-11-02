/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from InputStream.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('inputStreamConvertToString', () {
    test('returns empty at EOF and concatenates lines without separators', () {
      final emptyReader = _FakeReader([], []);
      expect(
        inputStreamConvertToString(
          createReader: () => emptyReader,
          warn: (_) => fail('unexpected warning'),
        ),
        '',
      );
      expect(emptyReader.events, ['read', 'close']);

      final reader = _FakeReader(['first', '', 'second'], []);
      expect(
        inputStreamConvertToString(
          createReader: () => reader,
          warn: (_) => fail('unexpected warning'),
        ),
        'firstsecond',
      );
      expect(reader.events, ['read', 'read', 'read', 'read', 'close']);
    });

    test(
      'warns after reader construction Exception and performs no later work',
      () {
        final failure = Exception('reader construction failed');
        final events = <String>[];
        final warnings = <Exception>[];

        final result = inputStreamConvertToString(
          createReader: () {
            events.add('create');
            throw failure;
          },
          warn: (exception) {
            events.add('warn');
            warnings.add(exception);
          },
        );

        expect(result, '');
        expect(events, ['create', 'warn']);
        expect(warnings, [same(failure)]);
      },
    );

    test('discards partial content and warns after read Exception', () {
      final failure = Exception('read failed');
      final events = <String>[];
      final warnings = <Exception>[];
      final reader = _FakeReader(['partial'], [failure], events: events);

      final result = inputStreamConvertToString(
        createReader: () {
          events.add('create');
          return reader;
        },
        warn: (exception) {
          events.add('warn');
          warnings.add(exception);
        },
      );

      expect(result, '');
      expect(events, ['create', 'read', 'read', 'warn']);
      expect(warnings, [same(failure)]);
    });

    test('closes after EOF and discards content when close throws', () {
      final failure = Exception('close failed');
      final events = <String>[];
      final warnings = <Exception>[];
      final reader = _FakeReader(
        ['partial'],
        [],
        closeFailure: failure,
        events: events,
      );

      final result = inputStreamConvertToString(
        createReader: () {
          events.add('create');
          return reader;
        },
        warn: (exception) {
          events.add('warn');
          warnings.add(exception);
        },
      );

      expect(result, '');
      expect(events, ['create', 'read', 'read', 'close', 'warn']);
      expect(warnings, [same(failure)]);
    });

    test(
      'passes the original Exception to warning and propagates warning failure',
      () {
        final readFailure = Exception('read failed');
        final warningFailure = StateError('warning failed');
        final events = <String>[];
        final reader = _FakeReader(['partial'], [readFailure], events: events);

        expect(
          () => inputStreamConvertToString(
            createReader: () {
              events.add('create');
              return reader;
            },
            warn: (exception) {
              events.add('warn:${identical(exception, readFailure)}');
              throw warningFailure;
            },
          ),
          throwsA(same(warningFailure)),
        );
        expect(events, ['create', 'read', 'read', 'warn:true']);
      },
    );

    test('does not catch Dart Error or warn for it', () {
      final failure = StateError('fatal read failure');
      final events = <String>[];
      final reader = _FakeReader(['partial'], [failure], events: events);

      expect(
        () => inputStreamConvertToString(
          createReader: () {
            events.add('create');
            return reader;
          },
          warn: (_) => events.add('warn'),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['create', 'read', 'read']);
    });
  });
}

final class _FakeReader implements InputStreamLineReader {
  _FakeReader(
    this.lines,
    this.readFailures, {
    this.closeFailure,
    List<String>? events,
  }) : events = events ?? <String>[];

  final List<String> lines;
  final List<Object> readFailures;
  final Object? closeFailure;
  final List<String> events;
  var _lineIndex = 0;
  var _failureIndex = 0;

  @override
  String? readLine() {
    events.add('read');
    if (_lineIndex < lines.length) return lines[_lineIndex++];
    if (_failureIndex < readFailures.length) {
      throw readFailures[_failureIndex++];
    }
    return null;
  }

  @override
  void close() {
    events.add('close');
    if (closeFailure case final failure?) throw failure;
  }
}
