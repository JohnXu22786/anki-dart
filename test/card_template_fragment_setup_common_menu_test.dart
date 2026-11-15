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
  group('setupCardTemplateCommonMenu', () {
    test(
      'dynamic note types hide actions in source order and skip template reads',
      () {
        final events = <String>[];
        final callbacks = _callbacks(
          events,
          isCloze: () {
            events.add('cloze');
            return true;
          },
          isImageOcclusion: () {
            events.add('imageOcclusion');
            return false;
          },
          currentTemplate: () => throw StateError('must not read template'),
          templateHasDid: (_) => throw StateError('must not read did'),
          templateDidIsNull: (_) => throw StateError('must not read did'),
        );

        setupCardTemplateCommonMenu(callbacks: callbacks);

        expect(events, [
          'find:restoreToDefault',
          'title:restoreToDefault:Restore',
          'find:browserAppearance',
          'title:browserAppearance:Browser',
          'cloze',
          'debug:Editing cloze/occlusion note type, disabling add/delete card template and deck override functionality',
          'find:add',
          'visible:add:false',
          'find:rename',
          'visible:rename:false',
          'find:addDeckOverride',
          'visible:addDeckOverride:false',
          'templateCount',
          'fragmented',
          'viewId',
          'find:insertField',
          'visible:insertField:true',
        ]);
      },
    );

    test(
      'non-dynamic note types select deck override title with lazy did reads',
      () {
        for (final scenario in [
          (
            name: 'missing template',
            template: null,
            hasDid: false,
            isNull: false,
            on: false,
          ),
          (
            name: 'missing did',
            template: 'template',
            hasDid: false,
            isNull: false,
            on: false,
          ),
          (
            name: 'null did',
            template: 'template',
            hasDid: true,
            isNull: true,
            on: false,
          ),
          (
            name: 'present did',
            template: 'template',
            hasDid: true,
            isNull: false,
            on: true,
          ),
        ]) {
          final events = <String>[];
          setupCardTemplateCommonMenu(
            callbacks: _callbacks(
              events,
              isCloze: () {
                events.add('cloze');
                return false;
              },
              isImageOcclusion: () {
                events.add('imageOcclusion');
                return false;
              },
              currentTemplate: () {
                events.add('currentTemplate');
                return scenario.template;
              },
              templateHasDid: (_) {
                events.add('hasDid');
                return scenario.hasDid;
              },
              templateDidIsNull: (_) {
                events.add('didIsNull');
                return scenario.isNull;
              },
            ),
          );

          expect(events.take(5), [
            'find:restoreToDefault',
            'title:restoreToDefault:Restore',
            'find:browserAppearance',
            'title:browserAppearance:Browser',
            'cloze',
          ], reason: scenario.name);
          expect(
            events,
            contains(
              'title:addDeckOverride:${scenario.on ? 'Override on' : 'Override off'}',
            ),
            reason: scenario.name,
          );
          expect(
            events.contains('imageOcclusion'),
            isTrue,
            reason: scenario.name,
          );
          expect(
            events.contains('hasDid'),
            scenario.template != null,
            reason: scenario.name,
          );
          expect(
            events.contains('didIsNull'),
            scenario.template != null && scenario.hasDid,
            reason: scenario.name,
          );
          expect(
            events.indexOf('templateCount'),
            greaterThan(
              events.indexOf(
                'title:addDeckOverride:${scenario.on ? 'Override on' : 'Override off'}',
              ),
            ),
            reason: scenario.name,
          );
        }
      },
    );

    test('delete is hidden only when template count is below two', () {
      for (final count in [1, 2]) {
        final events = <String>[];
        setupCardTemplateCommonMenu(
          callbacks: _callbacks(
            events,
            isCloze: () => false,
            isImageOcclusion: () => false,
            currentTemplate: () => null,
            templateHasDid: (_) => false,
            templateDidIsNull: (_) => true,
            templateCount: () => count,
          ),
        );
        expect(events.contains('visible:delete:false'), count == 1);
      }
    });

    test(
      'fragmented mode hides preview and styling view hides insert field',
      () {
        for (final scenario in [
          (
            fragmented: true,
            viewId: 10,
            stylingViewId: 10,
            previewHidden: true,
            insertVisible: false,
          ),
          (
            fragmented: false,
            viewId: 9,
            stylingViewId: 10,
            previewHidden: false,
            insertVisible: true,
          ),
        ]) {
          final events = <String>[];
          setupCardTemplateCommonMenu(
            callbacks: _callbacks(
              events,
              isCloze: () => false,
              isImageOcclusion: () => false,
              currentTemplate: () => null,
              templateHasDid: (_) => false,
              templateDidIsNull: (_) => true,
              fragmented: () => scenario.fragmented,
              currentEditorViewId: () => scenario.viewId,
              stylingViewId: () => scenario.stylingViewId,
            ),
          );
          expect(
            events.contains('visible:preview:false'),
            scenario.previewHidden,
          );
          expect(
            events.contains('visible:insertField:${scenario.insertVisible}'),
            isTrue,
          );
        }
      },
    );

    test('callback failure stops setup and propagates the same object', () {
      final failure = StateError('browser title failed');
      final events = <String>[];
      expect(
        () => setupCardTemplateCommonMenu(
          callbacks: _callbacks(
            events,
            browserAppearanceTitle: () {
              events.add('browserTitle');
              throw failure;
            },
            isCloze: () {
              events.add('cloze');
              return false;
            },
            isImageOcclusion: () => false,
            currentTemplate: () => null,
            templateHasDid: (_) => false,
            templateDidIsNull: (_) => true,
          ),
        ),
        throwsA(same(failure)),
      );
      expect(events, [
        'find:restoreToDefault',
        'title:restoreToDefault:Restore',
        'find:browserAppearance',
        'browserTitle',
      ]);
    });
  });
}

CardTemplateCommonMenuSetupCallbacks<String, CardTemplateCommonMenuSetupItem>
_callbacks(
  List<String> events, {
  String Function()? restoreToDefaultTitle,
  String Function()? browserAppearanceTitle,
  String Function(bool hasOverride)? deckOverrideTitle,
  bool Function()? isCloze,
  bool Function()? isImageOcclusion,
  String? Function()? currentTemplate,
  bool Function(String template)? templateHasDid,
  bool Function(String template)? templateDidIsNull,
  int Function()? templateCount,
  bool Function()? fragmented,
  int Function()? currentEditorViewId,
  int Function()? stylingViewId,
}) =>
    CardTemplateCommonMenuSetupCallbacks<
      String,
      CardTemplateCommonMenuSetupItem
    >(
      findItem: (item) {
        events.add('find:${item.name}');
        return item;
      },
      setTitle: (item, title) => events.add('title:${item.name}:$title'),
      setVisible: (item, visible) =>
          events.add('visible:${item.name}:$visible'),
      restoreToDefaultTitle: restoreToDefaultTitle ?? () => 'Restore',
      browserAppearanceTitle: browserAppearanceTitle ?? () => 'Browser',
      deckOverrideTitle:
          deckOverrideTitle ??
          (hasOverride) => hasOverride ? 'Override on' : 'Override off',
      debugLog: (message) => events.add('debug:$message'),
      isCloze: isCloze ?? () => false,
      isImageOcclusion: isImageOcclusion ?? () => false,
      currentTemplate: currentTemplate ?? () => null,
      templateHasDid: templateHasDid ?? (_) => false,
      templateDidIsNull: templateDidIsNull ?? (_) => true,
      templateCount:
          templateCount ??
          () {
            events.add('templateCount');
            return 2;
          },
      fragmented:
          fragmented ??
          () {
            events.add('fragmented');
            return false;
          },
      currentEditorViewId:
          currentEditorViewId ??
          () {
            events.add('viewId');
            return 9;
          },
      stylingViewId: stylingViewId ?? () => 10,
    );
