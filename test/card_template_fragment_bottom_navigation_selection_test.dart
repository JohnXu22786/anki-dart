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
 * SPDX-FileCopyrightText: 2014 Timothy Rae
 * SPDX-FileCopyrightText: 2018 Mike Hardy
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cardTemplateFragmentBottomNavigationSelection', () {
    for (final entry in <(int, String)>[
      (10, 'css'),
      (20, 'answer'),
      (30, 'question'),
    ]) {
      test('routes ID ${entry.$1} in source callback order', () {
        final harness = _Harness(selectedId: entry.$1);

        final handled = cardTemplateFragmentBottomNavigationSelection(
          item: harness.item,
          callbacks: harness.callbacks,
        );

        expect(handled, isTrue);
        expect(harness.events, [
          'read-item-id',
          'read-card-index:1',
          'write-tab:1:${entry.$1}',
          'read-item-title',
          'log:selected editor view: %s:host title',
          'read-card-index:2',
          'read-${entry.$2}',
          'set-view:${entry.$1}:2:${entry.$2}',
          'invalidate-options-menu',
        ]);
        expect(harness.itemIdReads, 1);
        expect(harness.viewId, entry.$1);
        expect(harness.viewIndex, 2);
        expect(harness.viewContent, entry.$2);
        expect(harness.invalidations, 1);
      });
    }

    test('a selected-view failure propagates and skips menu invalidation', () {
      final harness = _Harness(selectedId: 30, failAt: 'set-view');
      final failure = harness.failure;

      expect(
        () => cardTemplateFragmentBottomNavigationSelection(
          item: harness.item,
          callbacks: harness.callbacks,
        ),
        throwsA(same(failure)),
      );
      expect(harness.events, [
        'read-item-id',
        'read-card-index:1',
        'write-tab:1:30',
        'read-item-title',
        'log:selected editor view: %s:host title',
        'read-card-index:2',
        'read-question',
        'set-view:30:2:question',
      ]);
      expect(harness.invalidations, 0);
    });

    test('a tab-map failure prevents title and view reads', () {
      final harness = _Harness(selectedId: 10, failAt: 'write-tab');

      expect(
        () => cardTemplateFragmentBottomNavigationSelection(
          item: harness.item,
          callbacks: harness.callbacks,
        ),
        throwsA(same(harness.failure)),
      );
      expect(harness.events, [
        'read-item-id',
        'read-card-index:1',
        'write-tab:1:10',
      ]);
      expect(harness.invalidations, 0);
    });
  });
}

final class _Harness {
  _Harness({required this.selectedId, this.failAt}) {
    callbacks = CardTemplateFragmentBottomNavigationSelectionCallbacks<_Item>(
      itemId: (item) {
        expect(item, same(this.item));
        events.add('read-item-id');
        itemIdReads++;
        _fail('read-item-id');
        return selectedId;
      },
      itemTitle: (item) {
        expect(item, same(this.item));
        events.add('read-item-title');
        _fail('read-item-title');
        return 'host title';
      },
      cardIndex: () {
        final index = ++cardIndexReads;
        events.add('read-card-index:$index');
        _fail('read-card-index:$index');
        return index;
      },
      writeTabToViewId: (index, id) {
        events.add('write-tab:$index:$id');
        _fail('write-tab');
        tabIndex = index;
        tabValue = id;
      },
      logInfo: (message, argument) {
        events.add('log:$message:$argument');
        _fail('log');
      },
      stylingEditId: 10,
      backEditId: 20,
      fragmentTempModelCss: () {
        events.add('read-css');
        _fail('read-css');
        return 'css';
      },
      currentTemplateAnswerFormat: () {
        events.add('read-answer');
        _fail('read-answer');
        return 'answer';
      },
      currentTemplateQuestionFormat: () {
        events.add('read-question');
        _fail('read-question');
        return 'question';
      },
      setCurrentEditorView: (id, index, content) {
        events.add('set-view:$id:$index:$content');
        _fail('set-view');
        viewId = id;
        viewIndex = index;
        viewContent = content;
      },
      invalidateOptionsMenu: () {
        events.add('invalidate-options-menu');
        _fail('invalidate-options-menu');
        invalidations++;
      },
    );
  }

  final int selectedId;
  final String? failAt;
  final _Item item = _Item();
  final events = <String>[];
  final failure = StateError('injected callback failure');
  late final CardTemplateFragmentBottomNavigationSelectionCallbacks<_Item>
  callbacks;
  int itemIdReads = 0;
  int cardIndexReads = 0;
  int? tabIndex;
  int? tabValue;
  int? viewId;
  int? viewIndex;
  String? viewContent;
  int invalidations = 0;

  void _fail(String stage) {
    if (failAt == stage) throw failure;
  }
}

final class _Item {}
