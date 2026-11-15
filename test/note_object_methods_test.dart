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
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note clone', () {
    test('returns the exact host clone and invokes cloning once', () {
      final clone = _HostNote(1);
      var cloneCalls = 0;
      var castCalls = 0;

      final result = libankiNoteClone<_HostNote>(
        shallowClone: () {
          cloneCalls++;
          return clone;
        },
        castToNote: (value) {
          castCalls++;
          return value as _HostNote;
        },
        isCloneNotSupportedException: (_) => false,
        runtimeException: _HostRuntimeException.new,
      );

      expect(result, same(clone));
      expect(cloneCalls, 1);
      expect(castCalls, 1);
    });

    test('wraps only CloneNotSupportedException with its exact cause', () {
      final failure = _CloneNotSupportedException();
      final classified = <Object>[];
      final wrappers = <_HostRuntimeException>[];

      expect(
        () => libankiNoteClone<_HostNote>(
          shallowClone: () => throw failure,
          castToNote: (value) => value as _HostNote,
          isCloneNotSupportedException: (error) {
            classified.add(error);
            return error is _CloneNotSupportedException;
          },
          runtimeException: (cause) {
            final wrapper = _HostRuntimeException(cause);
            wrappers.add(wrapper);
            return wrapper;
          },
        ),
        throwsA(isA<_HostRuntimeException>()),
      );

      expect(classified, [same(failure)]);
      expect(wrappers, hasLength(1));
      expect(wrappers.single.cause, same(failure));
    });

    test('propagates unrelated clone and cast failures unchanged', () {
      for (final failInCast in [false, true]) {
        final failure = StateError('clone failed');
        var wrapperCalls = 0;

        expect(
          () => libankiNoteClone<_HostNote>(
            shallowClone: () {
              if (failInCast) return Object();
              throw failure;
            },
            castToNote: (_) {
              throw failure;
            },
            isCloneNotSupportedException: (error) =>
                error is _CloneNotSupportedException,
            runtimeException: (cause) {
              wrapperCalls++;
              return _HostRuntimeException(cause);
            },
          ),
          throwsA(same(failure)),
        );
        expect(wrapperCalls, 0);
      }
    });
  });

  group('LibAnki Note equality', () {
    test('returns true for self before class or ID access', () {
      final note = _HostNote(1);
      var classChecks = 0;
      var idReads = 0;

      expect(
        libankiNoteEquals(
          note,
          note,
          sameRuntimeClass: (_, _) {
            classChecks++;
            return true;
          },
          noteId: (_) {
            idReads++;
            return 1;
          },
        ),
        isTrue,
      );
      expect(classChecks, 0);
      expect(idReads, 0);
    });

    test('returns false for null before class or ID access', () {
      final note = _HostNote(1);
      var classChecks = 0;
      var idReads = 0;

      expect(
        libankiNoteEquals(
          note,
          null,
          sameRuntimeClass: (_, _) {
            classChecks++;
            return true;
          },
          noteId: (_) {
            idReads++;
            return 1;
          },
        ),
        isFalse,
      );
      expect(classChecks, 0);
      expect(idReads, 0);
    });

    test('returns false for different runtime classes without reading IDs', () {
      final first = _HostNote(1);
      final other = _OtherHostNote(1);
      final classChecks = <(Object, Object)>[];
      var idReads = 0;

      expect(
        libankiNoteEquals(
          first,
          other,
          sameRuntimeClass: (self, candidate) {
            classChecks.add((self, candidate));
            return self.runtimeType == candidate.runtimeType;
          },
          noteId: (_) {
            idReads++;
            return 1;
          },
        ),
        isFalse,
      );
      expect(classChecks, [(first, other)]);
      expect(idReads, 0);
    });

    test('compares distinct same-class Notes by IDs in source order', () {
      final first = _HostNote(42);
      final sameId = _HostNote(42);
      final differentId = _HostNote(43);
      final classChecks = <(Object, Object)>[];
      final idReads = <Object>[];

      bool sameRuntimeClass(Object self, Object other) {
        classChecks.add((self, other));
        return self.runtimeType == other.runtimeType;
      }

      int noteId(Object note) {
        idReads.add(note);
        return (note as _HostNote).id;
      }

      expect(
        libankiNoteEquals(
          first,
          sameId,
          sameRuntimeClass: sameRuntimeClass,
          noteId: noteId,
        ),
        isTrue,
      );
      expect(
        libankiNoteEquals(
          first,
          differentId,
          sameRuntimeClass: sameRuntimeClass,
          noteId: noteId,
        ),
        isFalse,
      );
      expect(classChecks, [(first, sameId), (first, differentId)]);
      expect(idReads, [first, sameId, first, differentId]);
    });
  });

  group('LibAnki Note hash code', () {
    test('folds signed Long IDs to the JVM signed 32-bit hash', () {
      for (final (id, expected) in <(int, int)>[
        (0, 0),
        (0x7fffffff, 0x7fffffff),
        (0x100000001, 0),
        (0x7fffffff00000001, 0x7ffffffe),
        (-1, 0),
        (-0x100000001, 1),
        (-0x8000000000000000, -0x80000000),
      ]) {
        expect(libankiNoteHashCode(id), expected, reason: 'ID $id');
      }
    });
  });
}

final class _HostNote {
  const _HostNote(this.id);

  final int id;
}

final class _OtherHostNote {
  const _OtherHostNote(this.id);

  final int id;
}

final class _CloneNotSupportedException implements Exception {}

final class _HostRuntimeException implements Exception {
  _HostRuntimeException(this.cause);

  final Object cause;
}
