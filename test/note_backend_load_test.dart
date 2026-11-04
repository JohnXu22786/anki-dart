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
 * SPDX-FileCopyrightText: 2011 Norbert Nagold
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived Note backend-load adapter tests; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('LibAnki Note.load', () {
    test(
      'reads the current ID, fetches once, and forwards the exact backend note',
      () {
        final source = _BackendNote();
        final calls = <String>[];
        final forwarded = <_BackendNote>[];

        libankiNoteLoad<_BackendNote>(
          currentId: () {
            calls.add('currentId');
            return 42;
          },
          getNote: (id) {
            calls.add('getNote:$id');
            return source;
          },
          loadFromBackendNote: (note) {
            calls.add('project');
            forwarded.add(note);
          },
        );

        expect(calls, ['currentId', 'getNote:42', 'project']);
        expect(forwarded, [same(source)]);
      },
    );

    test('stops before projection when getNote fails', () {
      final failure = StateError('backend failed');
      final calls = <String>[];

      expect(
        () => libankiNoteLoad<_BackendNote>(
          currentId: () {
            calls.add('currentId');
            return 42;
          },
          getNote: (_) {
            calls.add('getNote');
            throw failure;
          },
          loadFromBackendNote: (_) => calls.add('project'),
        ),
        throwsA(same(failure)),
      );
      expect(calls, ['currentId', 'getNote']);
    });
  });

  group('LibAnki Note.loadFromBackendNote', () {
    test('reads and assigns fields in source order and copies both lists', () {
      final fixture = _Fixture();
      final originalTags = <String>['one', 'two'];
      final originalFields = <String>['front', 'back'];
      fixture.note.tags = originalTags;
      fixture.note.fields = originalFields;

      fixture.project();

      expect(fixture.calls, [
        'readId',
        'setId:7',
        'readGuid',
        'setGuid:guid',
        'readNotetypeId',
        'setNoteTypeId:11',
        'readCurrentNoteTypeId',
        'lookupNotetype:11',
        'unwrapNotetype',
        'setNotetype',
        'readMtimeSecs',
        'setMod:13',
        'readUsn',
        'setUsn:17',
        'readTagsList',
        'copyList',
        'setTags',
        'readFieldsList',
        'copyList',
        'setFields',
        'readNotetype',
        'createFieldMap',
        'setFieldMap',
      ]);
      expect(fixture.note.id, 7);
      expect(fixture.note.guid, 'guid');
      expect(fixture.note.noteTypeId, 11);
      expect(fixture.note.notetype, same(fixture.notetype));
      expect(fixture.note.mod, 13);
      expect(fixture.note.usn, 17);
      expect(fixture.note.tags, ['one', 'two']);
      expect(fixture.note.tags, isNot(same(originalTags)));
      expect(fixture.note.fields, ['front', 'back']);
      expect(fixture.note.fields, isNot(same(originalFields)));
      expect(fixture.note.fieldMap, same(fixture.fieldMap));
      fixture.note.tags.add('changed');
      fixture.note.fields.add('changed');
      expect(originalTags, ['one', 'two']);
      expect(originalFields, ['front', 'back']);
    });

    test(
      'notetype unwrap failure preserves prior writes and skips later work',
      () {
        final fixture = _Fixture()..failureAt = 'unwrapNotetype';
        final failure = fixture.failure;

        expect(() => fixture.project(), throwsA(same(failure)));
        expect(fixture.calls, [
          'readId',
          'setId:7',
          'readGuid',
          'setGuid:guid',
          'readNotetypeId',
          'setNoteTypeId:11',
          'readCurrentNoteTypeId',
          'lookupNotetype:11',
          'unwrapNotetype',
        ]);
        expect(fixture.note.id, 7);
        expect(fixture.note.guid, 'guid');
        expect(fixture.note.noteTypeId, 11);
        expect(fixture.note.notetype, isNull);
        expect(fixture.note.mod, 0);
        expect(fixture.note.usn, 0);
        expect(fixture.note.tags, isEmpty);
        expect(fixture.note.fields, isEmpty);
        expect(fixture.note.fieldMap, isNull);
      },
    );

    test('null notetype lookup fails at the required unwrap', () {
      final fixture = _Fixture()..notetypeLookupReturnsNull = true;

      expect(
        () => fixture.project(),
        throwsA(same(fixture.hostNullPointerException)),
      );
      expect(fixture.calls, [
        'readId',
        'setId:7',
        'readGuid',
        'setGuid:guid',
        'readNotetypeId',
        'setNoteTypeId:11',
        'readCurrentNoteTypeId',
        'lookupNotetype:11',
        'unwrapNotetype',
      ]);
      expect(fixture.note.id, 7);
      expect(fixture.note.guid, 'guid');
      expect(fixture.note.noteTypeId, 11);
      expect(fixture.note.notetype, isNull);
      expect(fixture.note.mod, 0);
      expect(fixture.note.tags, isEmpty);
    });

    test(
      'tag-copy failure retains earlier writes and stops before fields/map',
      () {
        final fixture = _Fixture()..failureAt = 'copyList';
        fixture.note.tags = ['old-tag'];
        fixture.note.fields = ['old-field'];

        expect(() => fixture.project(), throwsA(same(fixture.failure)));
        expect(fixture.calls, [
          'readId',
          'setId:7',
          'readGuid',
          'setGuid:guid',
          'readNotetypeId',
          'setNoteTypeId:11',
          'readCurrentNoteTypeId',
          'lookupNotetype:11',
          'unwrapNotetype',
          'setNotetype',
          'readMtimeSecs',
          'setMod:13',
          'readUsn',
          'setUsn:17',
          'readTagsList',
          'copyList',
        ]);
        expect(fixture.note.notetype, same(fixture.notetype));
        expect(fixture.note.mod, 13);
        expect(fixture.note.usn, 17);
        expect(fixture.note.tags, ['old-tag']);
        expect(fixture.note.fields, ['old-field']);
        expect(fixture.note.fieldMap, isNull);
      },
    );

    test('field-map failure occurs after all preceding assignments', () {
      final fixture = _Fixture()..failureAt = 'createFieldMap';

      expect(() => fixture.project(), throwsA(same(fixture.failure)));
      expect(fixture.calls.last, 'createFieldMap');
      expect(fixture.calls, isNot(contains('setFieldMap')));
      expect(fixture.note.id, 7);
      expect(fixture.note.guid, 'guid');
      expect(fixture.note.notetype, same(fixture.notetype));
      expect(fixture.note.mod, 13);
      expect(fixture.note.usn, 17);
      expect(fixture.note.tags, ['one', 'two']);
      expect(fixture.note.fields, ['front', 'back']);
      expect(fixture.note.fieldMap, isNull);
    });
  });
}

final class _BackendNote {
  int id = 7;
  String guid = 'guid';
  int notetypeId = 11;
  int mtimeSecs = 13;
  int usn = 17;
  List<String> tagsList = ['one', 'two'];
  List<String> fieldsList = ['front', 'back'];
}

final class _NoteState {
  int id = 0;
  String? guid;
  int noteTypeId = 0;
  Object? notetype;
  int mod = 0;
  int usn = 0;
  List<String> tags = [];
  List<String> fields = [];
  Object? fieldMap;
}

final class _Fixture {
  final calls = <String>[];
  final note = _NoteState();
  final backendNote = _BackendNote();
  final notetype = Object();
  final fieldMap = Object();
  final failure = StateError('injected callback failure');
  final hostNullPointerException = _HostNullPointerException();
  String? failureAt;
  bool notetypeLookupReturnsNull = false;

  void _call(String name) {
    calls.add(name);
    if (failureAt == name) throw failure;
  }

  void project() =>
      libankiNoteLoadFromBackendNote<_BackendNote, Object, Object>(
        note: backendNote,
        readId: (source) {
          _call('readId');
          return source.id;
        },
        setId: (value) {
          _call('setId:$value');
          note.id = value;
        },
        readGuid: (source) {
          _call('readGuid');
          return source.guid;
        },
        setGuid: (value) {
          _call('setGuid:$value');
          note.guid = value;
        },
        readNotetypeId: (source) {
          _call('readNotetypeId');
          return source.notetypeId;
        },
        setNoteTypeId: (value) {
          _call('setNoteTypeId:$value');
          note.noteTypeId = value;
        },
        currentNoteTypeId: () {
          _call('readCurrentNoteTypeId');
          return note.noteTypeId;
        },
        getRequiredNotetype: (id) {
          _call('lookupNotetype:$id');
          final Object? result = id == 11 && !notetypeLookupReturnsNull
              ? notetype
              : null;
          _call('unwrapNotetype');
          if (result == null) throw hostNullPointerException;
          return result;
        },
        setNotetype: (value) {
          _call('setNotetype');
          note.notetype = value;
        },
        readMtimeSecs: (source) {
          _call('readMtimeSecs');
          return source.mtimeSecs;
        },
        setMod: (value) {
          _call('setMod:$value');
          note.mod = value;
        },
        readUsn: (source) {
          _call('readUsn');
          return source.usn;
        },
        setUsn: (value) {
          _call('setUsn:$value');
          note.usn = value;
        },
        readTagsList: (source) {
          _call('readTagsList');
          return source.tagsList;
        },
        readFieldsList: (source) {
          _call('readFieldsList');
          return source.fieldsList;
        },
        copyMutableList: (values) {
          _call('copyList');
          return values.toList();
        },
        setTags: (values) {
          _call('setTags');
          note.tags = values;
        },
        setFields: (values) {
          _call('setFields');
          note.fields = values;
        },
        readNotetype: () {
          _call('readNotetype');
          return note.notetype!;
        },
        createFieldMap: (value) {
          _call('createFieldMap');
          expect(value, same(notetype));
          return fieldMap;
        },
        setFieldMap: (value) {
          _call('setFieldMap');
          note.fieldMap = value;
        },
      );
}

final class _HostNullPointerException implements Exception {}
