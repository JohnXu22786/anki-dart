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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateEditorDeckSelected', () {
    test('removes a deck override in source order', () {
      final events = <Object?>[];
      final template = Object();

      cardTemplateEditorDeckSelected<Object, Object>(
        deck: null,
        callbacks: _callbacks(
          events,
          template: template,
          readTemplateName: (_) => 'Card A',
        ),
      );

      expect(events, [
        'validate:null',
        'cloze',
        'ordinal',
        'template:4',
        ('templateName', template),
        ('logRemoval', 'Card A'),
        ('setOverride', (template, null)),
        ('removedMessage', 'Card A'),
        ('snackbar', 'removed:Card A'),
        'invalidate',
        'discard',
      ]);
    });

    test('sets the selected deck ID and reads the name at each source use', () {
      final events = <Object?>[];
      final template = Object();
      final deck = Object();

      cardTemplateEditorDeckSelected<Object, Object>(
        deck: deck,
        callbacks: _callbacks(
          events,
          template: template,
          deckId: (_) => 27,
          deckName: (_) => 'Filtered Candidate',
          isFilteredDeck: (id) => false,
          readTemplateName: (_) => 'Card B',
        ),
      );

      expect(events, [
        'validate:deck',
        'cloze',
        'ordinal',
        'template:4',
        ('templateName', template),
        'deckId',
        ('filtered', 27),
        'deckName',
        ('logAddition', ('Card B', 'Filtered Candidate')),
        'deckId',
        ('setOverride', (template, 27)),
        'deckName',
        ('addedMessage', ('Card B', 'Filtered Candidate')),
        ('snackbar', 'added:Card B:Filtered Candidate'),
        'invalidate',
        'discard',
      ]);
    });

    test('cloze rejection stops before ordinal or template access', () {
      final events = <Object?>[];

      cardTemplateEditorDeckSelected<Object, Object>(
        deck: Object(),
        callbacks: _callbacks(events, isCloze: () => true),
      );

      expect(events, [
        'validate:deck',
        'cloze',
        'warnCloze',
        'clozeError',
        ('snackbar', 'cloze-error'),
      ]);
    });

    test('filtered deck rejection stops before mutation and final effects', () {
      final events = <Object?>[];
      final template = Object();

      cardTemplateEditorDeckSelected<Object, Object>(
        deck: Object(),
        callbacks: _callbacks(
          events,
          template: template,
          deckId: (_) => 9,
          deckName: (_) => 'Filtered',
          isFilteredDeck: (id) => true,
          readTemplateName: (_) => 'Card C',
        ),
      );

      expect(events, [
        'validate:deck',
        'cloze',
        'ordinal',
        'template:4',
        ('templateName', template),
        'deckId',
        ('filtered', 9),
        'deckName',
        ('warnFiltered', ('Card C', 'Filtered')),
        'filteredError',
        ('snackbar', 'filtered-error'),
      ]);
    });

    test('invalid deck fails validation before any model reads', () {
      final events = <Object?>[];
      final failure = ArgumentError('not SelectableDeck.Deck');

      expect(
        () => cardTemplateEditorDeckSelected<Object, Object>(
          deck: Object(),
          callbacks: _callbacks(events, validateDeck: (_) => throw failure),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['validate:deck']);
    });

    test('callback failures propagate unchanged and stop later stages', () {
      final cases = <({String stage, List<String> reached})>[
        (stage: 'validate', reached: ['validate:deck']),
        (stage: 'cloze', reached: ['validate:deck', 'cloze']),
        (stage: 'ordinal', reached: ['validate:deck', 'cloze', 'ordinal']),
        (
          stage: 'template',
          reached: ['validate:deck', 'cloze', 'ordinal', 'template:4'],
        ),
        (
          stage: 'setOverride',
          reached: [
            'validate:deck',
            'cloze',
            'ordinal',
            'template:4',
            'templateName',
            'deckId',
            'filtered',
            'deckName',
            'logAddition',
            'deckId',
            'setOverride',
          ],
        ),
        (
          stage: 'snackbar',
          reached: [
            'validate:deck',
            'cloze',
            'ordinal',
            'template:4',
            'templateName',
            'deckId',
            'filtered',
            'deckName',
            'logAddition',
            'deckId',
            'setOverride',
            'deckName',
            'addedMessage',
            'snackbar',
          ],
        ),
      ];

      for (final testCase in cases) {
        final events = <Object?>[];
        final failure = StateError('${testCase.stage} failed');
        void hit(String stage) {
          if (stage == testCase.stage) throw failure;
        }

        expect(
          () => cardTemplateEditorDeckSelected<Object, Object>(
            deck: Object(),
            callbacks: _callbacks(
              events,
              template: Object(),
              deckId: (_) => 8,
              deckName: (_) => 'Deck',
              isFilteredDeck: (_) => false,
              onStage: hit,
            ),
          ),
          throwsA(same(failure)),
          reason: 'failure at ${testCase.stage} should propagate',
        );
        expect(
          events
              .map(
                (event) =>
                    event is String ? event : (event as (String, Object?)).$1,
              )
              .toList(),
          testCase.reached,
          reason: testCase.stage,
        );
      }
    });
  });
}

CardTemplateDeckSelectionCallbacks<TDeck, TTemplate>
_callbacks<TDeck extends Object, TTemplate>(
  List<Object?> events, {
  TTemplate? template,
  bool Function()? isCloze,
  void Function(TDeck? deck)? validateDeck,
  int Function()? currentOrdinal,
  TTemplate Function(int ordinal)? templateAt,
  String Function(TTemplate template)? readTemplateName,
  int Function(TDeck deck)? deckId,
  String Function(TDeck deck)? deckName,
  bool Function(int deckId)? isFilteredDeck,
  void Function(String templateName)? logRemoval,
  void Function(String templateName, String deckName)? logAddition,
  void Function(String templateName, String deckName)? warnFilteredDeck,
  void Function()? warnCloze,
  void Function(TTemplate template, int? deckId)? setDeckOverride,
  String Function(String templateName)? deckOverrideRemovedMessage,
  String Function(String templateName, String deckName)?
  deckOverrideAddedMessage,
  String Function()? clozeErrorMessage,
  String Function()? filteredDeckErrorMessage,
  void Function(String message)? showShortSnackbar,
  void Function()? invalidateOptionsMenu,
  void Function()? updateDiscardChanges,
  void Function(String stage)? onStage,
}) {
  void stage(String name, [Object? detail]) {
    events.add(detail == null ? name : (name, detail));
    onStage?.call(name.split(':').first);
  }

  return CardTemplateDeckSelectionCallbacks<TDeck, TTemplate>(
    validateDeck: (deck) {
      stage('validate:${deck == null ? 'null' : 'deck'}');
      validateDeck?.call(deck);
    },
    isCloze: () {
      stage('cloze');
      return isCloze?.call() ?? false;
    },
    warnCloze: () => stage('warnCloze'),
    clozeErrorMessage: () {
      stage('clozeError');
      return clozeErrorMessage?.call() ?? 'cloze-error';
    },
    currentOrdinal: () {
      stage('ordinal');
      return currentOrdinal?.call() ?? 4;
    },
    templateAt: (ordinal) {
      stage('template:$ordinal');
      return templateAt?.call(ordinal) ?? template as TTemplate;
    },
    templateName: (actualTemplate) {
      stage('templateName', actualTemplate);
      return readTemplateName?.call(actualTemplate) ?? 'Template';
    },
    deckId: (deck) {
      stage('deckId');
      return deckId?.call(deck) ?? 0;
    },
    deckName: (deck) {
      stage('deckName');
      return deckName?.call(deck) ?? 'Deck';
    },
    isFilteredDeck: (id) {
      stage('filtered', id);
      return isFilteredDeck?.call(id) ?? false;
    },
    warnFilteredDeck: (name, selectedDeckName) {
      stage('warnFiltered', (name, selectedDeckName));
      warnFilteredDeck?.call(name, selectedDeckName);
    },
    logRemoval: (name) {
      stage('logRemoval', name);
      logRemoval?.call(name);
    },
    logAddition: (name, selectedDeckName) {
      stage('logAddition', (name, selectedDeckName));
      logAddition?.call(name, selectedDeckName);
    },
    setDeckOverride: (actualTemplate, id) {
      stage('setOverride', (actualTemplate, id));
      setDeckOverride?.call(actualTemplate, id);
    },
    deckOverrideRemovedMessage: (name) {
      stage('removedMessage', name);
      return deckOverrideRemovedMessage?.call(name) ?? 'removed:$name';
    },
    deckOverrideAddedMessage: (name, selectedDeckName) {
      stage('addedMessage', (name, selectedDeckName));
      return deckOverrideAddedMessage?.call(name, selectedDeckName) ??
          'added:$name:$selectedDeckName';
    },
    filteredDeckErrorMessage: () {
      stage('filteredError');
      return filteredDeckErrorMessage?.call() ?? 'filtered-error';
    },
    showShortSnackbar: (message) {
      stage('snackbar', message);
      showShortSnackbar?.call(message);
    },
    invalidateOptionsMenu: () => stage('invalidate'),
    updateDiscardChanges: () => stage('discard'),
  );
}
