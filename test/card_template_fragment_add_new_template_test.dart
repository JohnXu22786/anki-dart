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
 * Source-derived from CardTemplateFragment.addNewTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('add card template', () {
    test('preserves callback order and exact host object identities', () {
      final host = _Host([_Template(0, 'q', 'a'), _Template(1, 'q2', 'a2')]);
      final oldTemplates = List<_Template>.of(host.templates);

      cardTemplateFragmentAddNewTemplate(
        noteType: host.noteType,
        callbacks: host.callbacks,
      );

      final created = host.created!;
      expect(created.question, 'q');
      expect(created.answer, 'a');
      expect(created.ordinal, 2);
      expect(host.templates, [oldTemplates[0], oldTemplates[1], same(created)]);
      expect(host.temporaryAdded, same(created));
      expect(host.events, [
        'read-card-index',
        'read-templates',
        'template-at:0',
        'new-card-name',
        'new-template:Card 3',
        'read-question:0',
        'write-question:Card 3',
        'read-answer:0',
        'write-answer:Card 3',
        'templates-length:2',
        'last-template',
        'template-ord:1',
        'log-last:1',
        'set-ord:2',
        'append',
        'read-temp-note-type',
        'temporary-add',
        'resolve-adapter',
        'notify',
        'resolve-pager',
        'templates-length:3',
        'animation-disabled',
        'set-current:2:false',
      ]);
      expect(host.nameTemplates, same(host.templates));
      expect(host.appendedTemplate, same(created));
    });

    test(
      'flips only for a single current template before assigning its ordinal',
      () {
        final host = _Host([_Template(4, 'front', 'back')]);

        cardTemplateFragmentAddNewTemplate(
          noteType: host.noteType,
          callbacks: host.callbacks,
        );

        expect(host.created!.question, 'flipped-back');
        expect(host.created!.answer, 'flipped-front');
        expect(
          host.events,
          containsAllInOrder([
            'templates-length:1',
            'flip',
            'last-template',
            'template-ord:4',
            'log-last:4',
            'set-ord:5',
            'append',
          ]),
        );
      },
    );

    test('indexed template failure stops before name projection', () {
      final host = _Host([]);

      expect(
        () => cardTemplateFragmentAddNewTemplate(
          noteType: host.noteType,
          callbacks: host.callbacks,
        ),
        throwsRangeError,
      );
      expect(host.events, [
        'read-card-index',
        'read-templates',
        'template-at:0',
      ]);
    });

    test('empty collection failure from last stops before ordinal logging', () {
      final host = _Host([_Template(0, 'q', 'a')])..emptyDuringName = true;

      expect(
        () => cardTemplateFragmentAddNewTemplate(
          noteType: host.noteType,
          callbacks: host.callbacks,
        ),
        throwsStateError,
      );
      expect(host.events, [
        'read-card-index',
        'read-templates',
        'template-at:0',
        'new-card-name',
        'new-template:Card 2',
        'read-question:0',
        'write-question:Card 2',
        'read-answer:0',
        'write-answer:Card 2',
        'templates-length:0',
        'last-template',
      ]);
    });

    test(
      'callback failure propagates unchanged and stops later side effects',
      () {
        final failure = StateError('name projection failed');
        final host = _Host([_Template(0, 'q', 'a')])
          ..newCardNameFailure = failure;

        expect(
          () => cardTemplateFragmentAddNewTemplate(
            noteType: host.noteType,
            callbacks: host.callbacks,
          ),
          throwsA(same(failure)),
        );
        expect(host.events, [
          'read-card-index',
          'read-templates',
          'template-at:0',
          'new-card-name',
        ]);
      },
    );

    test('wraps JVM Int32 ordinal addition before appending', () {
      final host = _Host([_Template(0x7fffffff, 'q', 'a')]);

      cardTemplateFragmentAddNewTemplate(
        noteType: host.noteType,
        callbacks: host.callbacks,
      );

      expect(host.created!.ordinal, -0x80000000);
      expect(host.events, contains('set-ord:-2147483648'));
    });
  });
}

final class _Template {
  _Template(this.ordinal, this.question, this.answer, {this.name = ''});

  int ordinal;
  String question;
  String answer;
  final String name;
}

final class _Host {
  _Host(this.templates);

  final Object noteType = Object();
  final List<_Template> templates;
  final events = <String>[];
  Object? newCardNameFailure;
  bool emptyDuringName = false;
  _Template? created;
  List<_Template>? nameTemplates;
  _Template? appendedTemplate;
  _Template? temporaryAdded;
  List<_Template>? assignedTemplates;

  late final callbacks =
      CardTemplateFragmentAddNewTemplateCallbacks<
        _Template,
        _Template,
        Object,
        List<_Template>,
        Object,
        Object,
        Object
      >(
        readCardIndex: () {
          events.add('read-card-index');
          return 0;
        },
        readTemplates: (actualNoteType) {
          expect(actualNoteType, same(noteType));
          events.add('read-templates');
          return templates;
        },
        templateAt: (actualTemplates, index) {
          expect(actualTemplates, same(templates));
          events.add('template-at:$index');
          return actualTemplates[index];
        },
        newCardName: (actualTemplates) {
          events.add('new-card-name');
          nameTemplates = actualTemplates;
          if (newCardNameFailure case final failure?) throw failure;
          final number = actualTemplates.length + 1;
          if (emptyDuringName) actualTemplates.clear();
          return 'Card $number';
        },
        createTemplate: (name) {
          events.add('new-template:$name');
          return created = _Template(0, '', '', name: name);
        },
        question: (template) {
          events.add('read-question:${template.ordinal}');
          return template.question;
        },
        setQuestion: (template, value) {
          events.add('write-question:${template.name}');
          template.question = value;
        },
        answer: (template) {
          events.add('read-answer:${template.ordinal}');
          return template.answer;
        },
        setAnswer: (template, value) {
          events.add('write-answer:${template.name}');
          template.answer = value;
        },
        templatesLength: (actualTemplates) {
          events.add('templates-length:${actualTemplates.length}');
          return actualTemplates.length;
        },
        flipQA: (template) {
          events.add('flip');
          final question = template.question;
          final answer = template.answer;
          template.question = 'flipped-$answer';
          template.answer = 'flipped-$question';
        },
        lastTemplate: (actualTemplates) {
          events.add('last-template');
          return actualTemplates.last;
        },
        templateOrdinal: (template) {
          events.add('template-ord:${template.ordinal}');
          return template.ordinal;
        },
        logLastOrdinal: (ordinal) => events.add('log-last:$ordinal'),
        setOrdinal: (template, ordinal) {
          events.add('set-ord:$ordinal');
          template.ordinal = ordinal;
        },
        appendTemplate: (actualTemplates, template) {
          events.add('append');
          appendedTemplate = template;
          actualTemplates.add(template);
        },
        readTemporaryNoteType: () {
          events.add('read-temp-note-type');
          return Object();
        },
        addTemporaryTemplate: (temporaryNoteType, template) {
          events.add('temporary-add');
          temporaryAdded = template;
        },
        resolvePagerAdapter: () {
          events.add('resolve-adapter');
          return Object();
        },
        notifyDataSetChanged: (_) => events.add('notify'),
        resolvePager: () {
          events.add('resolve-pager');
          return Object();
        },
        animationDisabled: () {
          events.add('animation-disabled');
          return false;
        },
        setCurrentItem: (_, index, animated) =>
            events.add('set-current:$index:$animated'),
      );
}
