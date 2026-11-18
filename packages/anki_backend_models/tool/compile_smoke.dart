// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/notes.pbenum.dart' as notes;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

void main() {
  final card = Card(id: Int64(1));
  final note = Note(id: Int64(2));
  if (card.id.toInt() + note.id.toInt() != 3) {
    throw StateError('model package JS smoke compilation failed');
  }
  final reviewStates = ReviewCardState(
    scheduledDays: 10,
    elapsedDays: 14,
  ).nextStates(const ReviewSchedulingContext());
  if (reviewStates.hard.review.scheduledDays != 12 ||
      reviewStates.good.review.scheduledDays != 30 ||
      reviewStates.easy.review.scheduledDays != 46) {
    throw StateError('review-state calculation differs on JavaScript');
  }
  if (fieldChecksum('test') != 2840236005) {
    throw StateError('unsigned SHA-1 checksum differs on JavaScript');
  }
  final fields = fixNoteFieldCount(['front', 'back', 'extra'], 2);
  if (fields.length != 2 || fields[1] != 'back; extra') {
    throw StateError('field-count migration differs on JavaScript');
  }
  if (!fieldIsEmpty('<BR />') || fieldIsEmpty('\u00a0')) {
    throw StateError('field emptiness differs on JavaScript');
  }
  final nonempty = Note(fields: ['answer']).nonEmptyFields([
    NoteField(name: 'Back', config: proto.Notetype_Field_Config()),
  ]);
  if (!nonempty.contains('Back')) {
    throw StateError('nonempty Note fields differ on JavaScript');
  }
  final hasDuplicate = isDuplicateNoteField(
    note: Note(id: Int64(2), notetypeId: Int64(3), fields: ['answer']),
    firstFieldWithoutHtml: 'answer',
    loadFieldsByChecksum: (notetypeId, checksum) {
      if (notetypeId != Int64(3) || checksum != fieldChecksum('answer')) {
        throw StateError('duplicate Note query arguments differ on JavaScript');
      }
      return [
        NoteChecksumMatch(
          noteId: Int64(4),
          firstField: '<b>answer</b>',
        ),
      ];
    },
  );
  if (!hasDuplicate) {
    throw StateError('duplicate Note check differs on JavaScript');
  }
  final notetype = Notetype(
    id: NotetypeId(Int64(7)),
    fields: [
      NoteField(name: 'Front', config: proto.Notetype_Field_Config()),
    ],
    config: Notetype.defaultConfig(),
  );
  final state = noteFieldsCheck(
    note: Note(id: Int64(2), notetypeId: Int64(7), fields: ['front']),
    getNotetype: (_) => notetype,
    normalizeText: false,
    loadFieldsByChecksum: (_, __) => [],
  );
  if (containsCloze('{{c1::text}}') != true ||
      state != notes.NoteFieldsCheckResponse_State.NORMAL) {
    throw StateError('note field validation differs on JavaScript');
  }
  final rendererType = Notetype(
    id: NotetypeId(Int64(8)),
    fields: [
      NoteField(name: 'field', config: proto.Notetype_Field_Config()),
    ],
    templates: [
      CardTemplate(
        name: 'Card 1',
        config: proto.Notetype_Template_Config(
          qFormatBrowser: '{{hint:field}}',
          aFormatBrowser: '{{FrontSide}}',
        ),
      ),
    ],
    config: Notetype.defaultConfig(),
  );
  final rendered = const BrowserCardTemplateRenderer().render(
    note: Note(id: Int64(9), notetypeId: Int64(8), fields: ['foo']),
    card: Card(id: Int64(10)),
    notetype: rendererType,
  );
  if (!rendered.isAvailable ||
      !rendered.questionHtml!.contains('hint83fe48607f0f3a66')) {
    throw StateError('browser template rendering differs on JavaScript');
  }
}
