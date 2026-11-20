// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_models/src/blake3.dart' as blake3;
import 'package:anki_backend_protocol/anki/notetypes.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  test('renderer can select standard rather than browser template formats',
      () {
    final type = _notetype(
      question: '{{Front}}',
      answer: '{{Back}}',
      questionBrowser: '{{Back}}',
      answerBrowser: '{{Front}}',
    );
    const renderer = BrowserCardTemplateRenderer();
    final note = Note(fields: ['standard', 'browser']);
    final card = Card(templateIdx: 0);

    expect(renderer.render(note: note, card: card, notetype: type).questionHtml,
        'browser');
    expect(
        renderer.render(
            note: note,
            card: card,
            notetype: type,
            useBrowserFormats: false).questionHtml,
        'standard');
  });

  test('templateRendersWithFields evaluates negated conditionals like Core',
      () {
    expect(
      templateRendersWithFields(
        '{{^Front}}{{Back}}{{/Front}}',
        {'Front', 'Back'},
      ),
      isFalse,
    );
    expect(
      templateRendersWithFields('{{^Front}}{{Back}}{{/Front}}', {'Back'}),
      isTrue,
    );
  });

  test(
      'renders fields, filters, nested conditionals, comments and alternate syntax',
      () {
    final type = _notetype(
      question:
          '{{#Front}}<!-- hidden -->{{text:Front}}{{^Back}}:empty{{/Back}}{{/Front}}',
      answer: '{{=<% %>=}}<%Front%>',
    );
    final result = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['<b>question &amp; answer</b>', '']),
      card: Card(templateIdx: 0),
      notetype: type,
    );

    expect(result.isAvailable, isTrue);
    expect(result.questionHtml, '<!-- hidden -->question & answer:empty');
    expect(result.answerHtml, '<b>question &amp; answer</b>');

    final tripleBrace = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['triple', 'back']),
      card: Card(templateIdx: 0),
      notetype: _notetype(question: '{{{Front}}}', answer: ''),
    );
    // The third closing brace is text under Core's two-brace delimiter lexer.
    expect(tripleBrace.questionHtml, 'triple}');

    final unmatchedComment = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['after-comment', 'back']),
      card: Card(templateIdx: 0),
      notetype: _notetype(question: '<!--{{Front}}', answer: ''),
    );
    expect(unmatchedComment.questionHtml, '<!--after-comment');

    final repeatedAlternateDirective = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['value', '']),
      card: Card(templateIdx: 0),
      notetype: _notetype(
        question: '{{=<% %>=}}{{=<% %>=}}<%Front%>',
        answer: '',
      ),
    );
    expect(repeatedAlternateDirective.questionHtml, 'value');

    final hinted = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['foo']),
      card: Card(templateIdx: 0),
      notetype: _notetype(
        question: '{{hint:field}}',
        answer: '',
        fields: ['field'],
      ),
    );
    expect(hinted.questionHtml,
        contains("document.getElementById('hint83fe48607f0f3a66')"));

    final nestedSoundInTts = BrowserCardTemplateRenderer().render(
      note: Note(fields: [
        'before [anki:foo   bar=x]custom [sound:inside-other.mp3][/anki:foo] '
            '[anki:tts lang=en_US]say [sound:inside.mp3][/anki:tts] '
            '[sound:outside.mp3] [anki:tts lang=en_US]malformed',
      ]),
      card: Card(templateIdx: 0),
      notetype: _notetype(
        question: '{{Front}}',
        answer: '',
        fields: ['Front'],
      ),
    );
    expect(
      nestedSoundInTts.questionHtml,
      'before [anki:foo bar=x]custom [sound:inside-other.mp3][/anki:foo] '
      '💬say [sound:inside.mp3]💬 '
      '🔉outside.mp3🔉 [anki:tts lang=en_US]malformed',
    );

    final unknownFilter = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['foo', '']),
      card: Card(templateIdx: 0),
      notetype: _notetype(
        question: '{{hint:unknown:Front}}',
        answer: '',
      ),
    );
    expect(
      unknownFilter.questionHtml,
      'foo',
      reason: 'browser partial rendering stops before later filters',
    );

    // Official BLAKE3 test vector for the 1,025-byte repeating 0..250 input.
    final longBlake3Input = List<int>.generate(1025, (index) => index % 251);
    expect(
      blake3.blake3Prefix64HexBytes(longBlake3Input),
      'd00278ae47eb27b3',
    );

    final combinedTypingFilter = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['answer', '']),
      card: Card(templateIdx: 0),
      notetype: _notetype(
        question: '{{type:cloze:Front}}',
        answer: '',
      ),
    );
    expect(combinedTypingFilter.questionHtml, '[[type:cloze:Front]]');

    final filteredEmptyField = BrowserCardTemplateRenderer().render(
      note: Note(fields: ['front', 'back']),
      card: Card(templateIdx: 0),
      notetype: _notetype(question: '{{text:}}', answer: ''),
    );
    expect(filteredEmptyField.isAvailable, isTrue);
    expect(filteredEmptyField.questionHtml, '');
  });

  test(
    'renders cloze and FrontSide, and rejects invalid or unknown references',
    () {
      final type = _notetype(
        question: '{{cloze:Text}}',
        answer: '{{FrontSide}}<hr id=answer>{{Text}} [sound:voice.mp3]',
        fields: ['Text'],
        cloze: true,
      );
      final result = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['before {{c1::word}} after']),
        card: Card(templateIdx: 0),
        notetype: type,
      );

      expect(result.isAvailable, isTrue);
      expect(result.questionHtml, contains('data-cloze="word"'));
      expect(result.answerHtml, startsWith('<hr id=answer>'));
      expect(result.answerHtml, contains('🔉voice.mp3🔉'));

      final nestedCloze = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['{{c1::a{ {{c2::b}} c}}']),
        card: Card(templateIdx: 0),
        notetype: _notetype(
          question: '{{cloze:Text}}',
          answer: '',
          fields: ['Text'],
          cloze: true,
        ),
      );
      expect(nestedCloze.isAvailable, isFalse);
      expect(nestedCloze.unavailableReason, 'unsupported-complex-cloze');

      final missingCloze = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['before {{c1::word}} after']),
        card: Card(templateIdx: 1),
        notetype: type,
      );
      expect(missingCloze.isAvailable, isFalse);
      expect(missingCloze.unavailableReason, 'missing-cloze');

      final unknown = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['value']),
        card: Card(templateIdx: 0),
        notetype: _notetype(question: '{{Missing}}', answer: 'answer'),
      );
      expect(unknown.isAvailable, isFalse);
      expect(unknown.questionHtml, isNull);

      final outOfRangeOrdinal = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['front', 'back']),
        card: Card(templateIdx: -1),
        notetype: _notetype(question: '{{Front}}', answer: '{{Back}}'),
      );
      expect(outOfRangeOrdinal.isAvailable, isFalse);

      final malformed = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['value', 'other']),
        card: Card(templateIdx: 0),
        notetype: _notetype(question: '{{#Front}}oops', answer: 'answer'),
      );
      expect(malformed.isAvailable, isFalse);

      final maxClozeConditional = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['value', 'other']),
        card: Card(templateIdx: 0),
        notetype: _notetype(
          question: '{{#c4294967295}}last{{/c4294967295}}',
          answer: '',
        ),
      );
      expect(maxClozeConditional.isAvailable, isTrue);

      // Core only recognizes cN conditionals when N parses as u32; overflow is
      // an unknown conditional and produces a template error.
      final overflowClozeConditional = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['value', 'other']),
        card: Card(templateIdx: 0),
        notetype: _notetype(
          question: '{{#c4294967296}}overflow{{/c4294967296}}',
          answer: '',
        ),
      );
      expect(overflowClozeConditional.isAvailable, isFalse);

      // Core's lexer treats an incomplete handlebar as literal text.
      final incompleteHandlebar = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['value', 'other']),
        card: Card(templateIdx: 0),
        notetype: _notetype(question: '{{Front', answer: 'answer'),
      );
      expect(incompleteHandlebar.isAvailable, isTrue);
      expect(incompleteHandlebar.questionHtml, '{{Front');

      final unknownInInactiveBranch = BrowserCardTemplateRenderer().render(
        note: Note(fields: ['front', 'filled']),
        card: Card(templateIdx: 0),
        notetype: _notetype(
          question: '{{^Back}}{{Missing}}{{/Back}}',
          answer: '',
        ),
      );
      expect(
        unknownInInactiveBranch.isAvailable,
        isFalse,
        reason:
            'Core validates skipped conditional children for template errors',
      );
    },
  );
}

Notetype _notetype({
  required String question,
  required String answer,
  String? questionBrowser,
  String? answerBrowser,
  List<String> fields = const ['Front', 'Back'],
  bool cloze = false,
}) =>
    Notetype(
      id: NotetypeId(Int64(1)),
      fields: [
        for (final name in fields)
          NoteField(name: name, config: proto.Notetype_Field_Config()),
      ],
      templates: [
        CardTemplate(
          name: 'Card 1',
          config: proto.Notetype_Template_Config(
            qFormat: question,
            aFormat: answer,
            qFormatBrowser: questionBrowser ?? question,
            aFormatBrowser: answerBrowser ?? answer,
          ),
        ),
      ],
      config: proto.Notetype_Config(
        kind: cloze
            ? proto.Notetype_Config_Kind.KIND_CLOZE
            : proto.Notetype_Config_Kind.KIND_NORMAL,
      ),
    );
