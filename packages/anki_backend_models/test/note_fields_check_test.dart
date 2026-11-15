// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as notes;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

NoteField field(String name) => NoteField(
      name: name,
      config: proto.Notetype_Field_Config(),
    );

Notetype notetype({
  bool cloze = false,
  required List<String> fields,
  String question = '{{Text}}',
  List<String> questions = const [],
}) =>
    Notetype(
      id: NotetypeId(Int64(7)),
      fields: fields.map(field).toList(),
      templates: [
        for (final format in questions.isEmpty ? [question] : questions)
          CardTemplate(config: proto.Notetype_Template_Config(qFormat: format)),
      ],
      config: cloze ? Notetype.clozeConfig() : Notetype.defaultConfig(),
    );

void main() {
  group('containsCloze', () {
    test('requires a parsed nonzero u16 ordinal and a body separator', () {
      expect(containsCloze('{{c1::text}}'), isTrue);
      expect(containsCloze('{{c1,2::text}}'), isTrue);
      expect(containsCloze('{{c0::text}}'), isFalse);
      expect(containsCloze('{{c65536::text}}'), isFalse);
      expect(containsCloze('{{c1:text}}'), isFalse);
      expect(containsCloze('{{C1::text}}'), isFalse);
    });

    test('handles nested closures and ignores incomplete openings', () {
      expect(containsCloze('{{c1::outer {{c0::inner}}}}'), isTrue);
      expect(containsCloze('{{c0::outer {{c1::inner}}}}'), isFalse);
      expect(containsCloze('{{c1::unfinished'), isFalse);
      expect(containsCloze('stray }}'), isFalse);
    });
  });

  group('Notetype.clozeFields', () {
    test('reads cloze-filtered references from first question format only', () {
      final type = notetype(
        cloze: true,
        fields: ['Text', 'Other'],
        questions: ['{{type:cloze:Text}} {{cloze:missing}}', '{{cloze:Other}}'],
      );
      expect(type.clozeFields, {0});
    });

    test('ignores comments, non-cloze references and malformed templates', () {
      final type = notetype(
        cloze: true,
        fields: ['Text'],
        question: '<!-- {{cloze:Text}} --> {{Text}} {{cloze:Text',
      );
      expect(type.clozeFields, isEmpty);
      expect(notetype(fields: ['Text'], question: '{{cloze:Text}}').clozeFields,
          isEmpty);
    });

    test('continues parsing after an unterminated HTML comment opener', () {
      expect(
        notetype(
          cloze: true,
          fields: ['Text'],
          question: '<!-- {{cloze:Text}}',
        ).clozeFields,
        {0},
      );
    });

    test('matches field names case-insensitively and alternate template syntax',
        () {
      final type = notetype(
        cloze: true,
        fields: ['TEXT'],
        question: '{{=<% %>=}}<%cloze:text%>',
      );
      expect(type.clozeFields, {0});
    });
  });

  group('noteFieldsCheck', () {
    final normal = notetype(fields: ['Text', 'Extra']);
    final cloze = notetype(
      cloze: true,
      fields: ['Text', 'Extra'],
      question: '{{cloze:Text}}',
    );
    Note note(List<String> values) => Note(
          id: Int64(2),
          notetypeId: Int64(7),
          fields: values,
        );

    test('preserves notetype and field cloze precedence before field status',
        () {
      final checks = [
        (
          note: note(['{{c1::x}}', '']),
          type: normal,
          result: notes.NoteFieldsCheckResponse_State.NOTETYPE_NOT_CLOZE
        ),
        (
          note: note(['', '{{c1::x}}']),
          type: cloze,
          result: notes.NoteFieldsCheckResponse_State.FIELD_NOT_CLOZE
        ),
        (
          note: note(['', '']),
          type: cloze,
          result: notes.NoteFieldsCheckResponse_State.EMPTY
        ),
      ];
      for (final check in checks) {
        expect(
          noteFieldsCheck(
            note: check.note,
            getNotetype: (_) => check.type,
            normalizeText: false,
            loadFieldsByChecksum: (_, __) =>
                throw StateError('unexpected query'),
          ),
          check.result,
        );
      }
    });

    test('first-field emptiness precedes missing cloze and duplicates', () {
      var queried = false;
      expect(
        noteFieldsCheck(
          note: note(['<b></b>', '']),
          getNotetype: (_) => cloze,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) {
            queried = true;
            return [];
          },
        ),
        notes.NoteFieldsCheckResponse_State.EMPTY,
      );
      expect(queried, isFalse);
    });

    test('strips HTML and optionally normalizes first field before emptiness',
        () {
      final fields = ['<div> </div>'];
      for (final normalize in [true, false]) {
        expect(
          noteFieldsCheck(
            note: note(fields),
            getNotetype: (_) => normal,
            normalizeText: normalize,
            loadFieldsByChecksum: (_, __) => [],
          ),
          notes.NoteFieldsCheckResponse_State.EMPTY,
        );
      }
      final decomposed = note(['e\u0301']);
      final checksums = <int>[];
      for (final normalize in [true, false]) {
        expect(
          noteFieldsCheck(
            note: decomposed,
            getNotetype: (_) => normal,
            normalizeText: normalize,
            loadFieldsByChecksum: (_, checksum) {
              checksums.add(checksum);
              return [];
            },
          ),
          notes.NoteFieldsCheckResponse_State.NORMAL,
        );
      }
      expect(checksums, [fieldChecksum('é'), fieldChecksum('e\u0301')]);
    });

    test('returns missing cloze only after a nonempty first field', () {
      expect(
        noteFieldsCheck(
          note: note(['front']),
          getNotetype: (_) => cloze,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) => throw StateError('unexpected query'),
        ),
        notes.NoteFieldsCheckResponse_State.MISSING_CLOZE,
      );
    });

    test('queries duplicates only for a normal cloze check', () {
      var requested = false;
      expect(
        noteFieldsCheck(
          note: note(['{{c1::front}}']),
          getNotetype: (_) => cloze,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) {
            requested = true;
            return [
              NoteChecksumMatch(noteId: Int64(3), firstField: '{{c1::front}}')
            ];
          },
        ),
        notes.NoteFieldsCheckResponse_State.DUPLICATE,
      );
      expect(requested, isTrue);
    });

    test(
        'returns empty for a missing first field and propagates callback errors',
        () {
      final missingType = StateError('notetype storage failed');
      expect(
        () => noteFieldsCheck(
          note: note([]),
          getNotetype: (_) => throw missingType,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) => [],
        ),
        throwsA(same(missingType)),
      );
      expect(
        noteFieldsCheck(
          note: note([]),
          getNotetype: (_) => normal,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) => throw StateError('unexpected query'),
        ),
        notes.NoteFieldsCheckResponse_State.EMPTY,
      );
      final storageError = StateError('duplicate query failed');
      expect(
        () => noteFieldsCheck(
          note: note(['front']),
          getNotetype: (_) => normal,
          normalizeText: false,
          loadFieldsByChecksum: (_, __) => throw storageError,
        ),
        throwsA(same(storageError)),
      );
    });
  });
}
