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
 * Source-derived from CardTemplateEditor.onCollectionLoaded in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateEditorOnCollectionLoaded', () {
    test('preserves callback order and resolves mediator reads lazily', () {
      final events = <String>[];
      final collection = Object();
      final originalNoteTypeId = Object();
      final originalNoteType = Object();
      final loadedNoteType = Object();
      final replacedNoteType = Object();
      final fields = Object();
      final editor = Object();
      final pager = Object();
      final adapter = Object();
      final tabs = Object();
      final mediator = Object();
      final tab = Object();
      final actionBar = Object();
      Object? currentNoteType;
      void Function(Object, int)? configureTab;

      cardTemplateEditorOnCollectionLoaded(
        collection: collection,
        originalNoteTypeId: originalNoteTypeId,
        startingOrdinal: 3,
        editor: editor,
        callbacks: CardTemplateEditorOnCollectionLoadedCallbacks(
          superOnCollectionLoaded: (actual) {
            expect(actual, same(collection));
            events.add('super');
          },
          clearNotetypeCache: (actual) {
            expect(actual, same(collection));
            events.add('clear cache');
          },
          readTemporaryNoteType: () {
            events.add('read temporary note type');
            return currentNoteType;
          },
          lookupNoteType: (actualCollection, id) {
            expect(actualCollection, same(collection));
            expect(id, same(originalNoteTypeId));
            events.add('lookup note type');
            return originalNoteType;
          },
          requireNoteType: (actual) {
            expect(actual, same(originalNoteType));
            events.add('assert note type');
            return actual!;
          },
          deepCloneNoteType: (actual) {
            expect(actual, same(originalNoteType));
            events.add('deep clone');
            return loadedNoteType;
          },
          assignTemporaryNoteType: (actual) {
            expect(actual, same(loadedNoteType));
            currentNoteType = actual;
            events.add('assign temporary note type');
          },
          readFieldNames: (actual) {
            expect(actual, same(loadedNoteType));
            events.add('read field names');
            return fields;
          },
          assignFieldNames: (actual) {
            expect(actual, same(fields));
            events.add('assign field names');
          },
          readPager: () {
            events.add('read pager');
            return pager;
          },
          createPagerAdapter: (actual) {
            expect(actual, same(editor));
            events.add('create pager adapter');
            return adapter;
          },
          assignPagerAdapter: (actualPager, actualAdapter) {
            expect(actualPager, same(pager));
            expect(actualAdapter, same(adapter));
            events.add('assign pager adapter');
          },
          setOffscreenPageLimit: (actualPager, limit) {
            expect(actualPager, same(pager));
            expect(limit, 7);
            events.add('offscreen:$limit');
          },
          readTabs: () {
            events.add('read tabs');
            return tabs;
          },
          createTabMediator: (actualTabs, actualPager, onConfigureTab) {
            expect(actualTabs, same(tabs));
            expect(actualPager, same(pager));
            configureTab = onConfigureTab;
            events.add('create mediator');
            return mediator;
          },
          attachTabMediator: (actual) {
            expect(actual, same(mediator));
            events.add('attach mediator');
          },
          configureTabText: (actual, name) {
            expect(actual, same(tab));
            events.add('tab text:$name');
          },
          readTemplate: (actual, position) {
            expect(actual, same(replacedNoteType));
            expect(position, 5);
            events.add('read template');
            return 'template';
          },
          readTemplateName: (template) {
            expect(template, 'template');
            events.add('read template name');
            return 'Current name';
          },
          readSupportActionBar: () {
            events.add('read action bar');
            return actionBar;
          },
          setActionBarTitle: (actual) {
            expect(actual, same(actionBar));
            events.add('set title');
          },
          readNoteTypeName: (actual) {
            expect(actual, same(loadedNoteType));
            events.add('read note type name');
            return 'Note type';
          },
          setActionBarSubtitle: (actual, name) {
            expect(actual, same(actionBar));
            expect(name, 'Note type');
            events.add('set subtitle');
          },
          logInfo: (message, id) {
            expect(
              message,
              'CardTemplateEditor:: Card template editor successfully started for note type id %d',
            );
            expect(id, same(originalNoteTypeId));
            events.add('info log');
          },
          logDebug: (message, ordinal) {
            expect(message, 'Setting starting tab to %d');
            expect(ordinal, 3);
            events.add('debug log');
          },
          animationDisabled: () {
            events.add('animation disabled');
            return false;
          },
          setCurrentPage: (actualPager, ordinal, animated) {
            expect(actualPager, same(pager));
            expect(ordinal, 3);
            expect(animated, isFalse);
            events.add('set current page');
          },
          updateDiscardChangesCallback: () => events.add('update discard'),
        ),
      );

      expect(events, [
        'super',
        'clear cache',
        'read temporary note type',
        'lookup note type',
        'assert note type',
        'deep clone',
        'assign temporary note type',
        'read temporary note type',
        'read field names',
        'assign field names',
        'read pager',
        'create pager adapter',
        'assign pager adapter',
        'read pager',
        'offscreen:7',
        'read tabs',
        'read pager',
        'create mediator',
        'attach mediator',
        'read action bar',
        'set title',
        'read temporary note type',
        'read note type name',
        'set subtitle',
        'info log',
        'debug log',
        'read pager',
        'animation disabled',
        'set current page',
        'update discard',
      ]);

      currentNoteType = replacedNoteType;
      configureTab!(tab, 5);
      expect(events.skip(30), [
        'read temporary note type',
        'read template',
        'read template name',
        'tab text:Current name',
      ]);
    });

    test('null ActionBar and ordinal -1 skip their guarded operations', () {
      final events = <String>[];
      cardTemplateEditorOnCollectionLoaded(
        collection: Object(),
        originalNoteTypeId: 9,
        startingOrdinal: -1,
        editor: Object(),
        callbacks: _callbacks(events, actionBar: null),
      );

      expect(events, contains('info log'));
      expect(events, contains('debug log'));
      expect(events, isNot(contains('set title')));
      expect(events, isNot(contains('set subtitle')));
      expect(events, isNot(contains('animation disabled')));
      expect(events, isNot(contains('set current page')));
      expect(events.last, 'update discard');
    });

    test('a failing callback stops later operations and preserves failure', () {
      final events = <String>[];
      final failure = StateError('clear failed');
      expect(
        () => cardTemplateEditorOnCollectionLoaded(
          collection: Object(),
          originalNoteTypeId: 9,
          startingOrdinal: -1,
          editor: Object(),
          callbacks: _callbacks(
            events,
            actionBar: null,
            failAt: 'clear cache',
            failure: failure,
          ),
        ),
        throwsA(same(failure)),
      );
      expect(events, ['super', 'clear cache']);
    });
  });
}

CardTemplateEditorOnCollectionLoadedCallbacks<
  Object,
  int,
  Object,
  Object,
  Object,
  Object,
  Object,
  Object,
  Object,
  Object,
  Object
>
_callbacks(
  List<String> events, {
  required Object? actionBar,
  String? failAt,
  Object? failure,
}) {
  void hit(String event) {
    events.add(event);
    if (event == failAt) throw failure!;
  }

  final temporaryNoteType = Object();
  return CardTemplateEditorOnCollectionLoadedCallbacks<
    Object,
    int,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object,
    Object
  >(
    superOnCollectionLoaded: (_) => hit('super'),
    clearNotetypeCache: (_) => hit('clear cache'),
    readTemporaryNoteType: () {
      hit('read temporary note type');
      return temporaryNoteType;
    },
    lookupNoteType: (_, _) {
      hit('lookup note type');
      return Object();
    },
    requireNoteType: (_) {
      hit('assert note type');
      return Object();
    },
    deepCloneNoteType: (_) {
      hit('deep clone');
      return temporaryNoteType;
    },
    assignTemporaryNoteType: (_) => hit('assign temporary note type'),
    readFieldNames: (_) {
      hit('read field names');
      return Object();
    },
    assignFieldNames: (_) => hit('assign field names'),
    readPager: () {
      hit('read pager');
      return Object();
    },
    createPagerAdapter: (_) {
      hit('create pager adapter');
      return Object();
    },
    assignPagerAdapter: (_, _) => hit('assign pager adapter'),
    setOffscreenPageLimit: (_, limit) => hit('offscreen:$limit'),
    readTabs: () {
      hit('read tabs');
      return Object();
    },
    createTabMediator: (_, _, _) {
      hit('create mediator');
      return Object();
    },
    attachTabMediator: (_) => hit('attach mediator'),
    configureTabText: (_, _) => hit('tab text'),
    readTemplate: (_, _) {
      hit('read template');
      return Object();
    },
    readTemplateName: (_) {
      hit('read template name');
      return 'name';
    },
    readSupportActionBar: () {
      hit('read action bar');
      return actionBar;
    },
    setActionBarTitle: (_) => hit('set title'),
    readNoteTypeName: (_) {
      hit('read note type name');
      return 'name';
    },
    setActionBarSubtitle: (_, _) => hit('set subtitle'),
    logInfo: (_, _) => hit('info log'),
    logDebug: (_, _) => hit('debug log'),
    animationDisabled: () {
      hit('animation disabled');
      return false;
    },
    setCurrentPage: (_, _, _) => hit('set current page'),
    updateDiscardChangesCallback: () => hit('update discard'),
  );
}
