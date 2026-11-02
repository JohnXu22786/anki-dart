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
 * Source-derived from CardTemplateFragment.deleteTemplate in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('delete card template', () {
    test('preserves source order, callback order, and retained identities', () {
      final host = _Host([_Template(0), _Template(1), _Template(2)]);
      final target = _Template(1);

      cardTemplateFragmentDeleteTemplate(
        tmpl: target,
        notetype: host.notetype,
        callbacks: host.callbacks,
      );

      expect(host.newTemplates, hasLength(2));
      expect(host.newTemplates[0], same(host.oldTemplates[0]));
      expect(host.newTemplates[1], same(host.oldTemplates[2]));
      expect(host.removedOrdinals, [1]);
      expect(host.events, [
        'read-templates',
        'create-templates',
        'template-ord:0',
        'target-ord:1',
        'append:0',
        'template-ord:1',
        'target-ord:1',
        'template-ord:1',
        'log:1',
        'read-temp-note-type',
        'template-ord:1',
        'remove:1',
        'template-ord:2',
        'target-ord:1',
        'append:2',
        'assign-templates',
        'update-ordinals',
        'resolve-adapter-shift',
        'ordinal-shift',
        'resolve-adapter-notify',
        'notify-data-set-changed',
        'resolve-pager',
        'templates-length',
        'animation-disabled',
        'set-current:1:false',
      ]);
      expect(host.assignedTemplates, same(host.newTemplates));
    });

    test(
      'repeats deletion for each matching ordinal and leaves missing matches empty',
      () {
        final duplicateHost = _Host([_Template(4), _Template(4), _Template(7)]);

        cardTemplateFragmentDeleteTemplate(
          tmpl: _Template(4),
          notetype: duplicateHost.notetype,
          callbacks: duplicateHost.callbacks,
        );

        expect(duplicateHost.removedOrdinals, [4, 4]);
        expect(duplicateHost.newTemplates, [
          same(duplicateHost.oldTemplates.last),
        ]);
        expect(
          duplicateHost.events.where((event) => event == 'log:4'),
          hasLength(2),
        );

        final missingHost = _Host([_Template(0), _Template(2)]);
        cardTemplateFragmentDeleteTemplate(
          tmpl: _Template(1),
          notetype: missingHost.notetype,
          callbacks: missingHost.callbacks,
        );
        expect(missingHost.removedOrdinals, isEmpty);
        expect(missingHost.newTemplates, hasLength(2));
      },
    );

    test('empty source retains negative current index', () {
      final host = _Host([]);

      cardTemplateFragmentDeleteTemplate(
        tmpl: _Template(0),
        notetype: host.notetype,
        callbacks: host.callbacks,
      );

      expect(host.currentIndex, -1);
      expect(host.events.last, 'set-current:-1:false');
    });

    test('callback failure propagates unchanged and stops later effects', () {
      final failure = StateError('temporary note type unavailable');
      final host = _Host([_Template(2)])..temporaryNoteTypeFailure = failure;

      expect(
        () => cardTemplateFragmentDeleteTemplate(
          tmpl: _Template(2),
          notetype: host.notetype,
          callbacks: host.callbacks,
        ),
        throwsA(same(failure)),
      );
      expect(host.events, [
        'read-templates',
        'create-templates',
        'template-ord:2',
        'target-ord:2',
        'template-ord:2',
        'log:2',
        'read-temp-note-type',
      ]);
    });
  });
}

final class _Template {
  const _Template(this.ord);

  final int ord;
}

final class _Host {
  _Host(this.oldTemplates);

  final Object notetype = Object();
  final List<_Template> oldTemplates;
  final events = <String>[];
  final removedOrdinals = <int>[];
  List<_Template> newTemplates = [];
  List<_Template>? assignedTemplates;
  Object? temporaryNoteTypeFailure;
  int? currentIndex;

  late final callbacks =
      CardTemplateFragmentDeleteTemplateCallbacks<
        _Template,
        _Template,
        Object,
        List<_Template>,
        Object,
        Object,
        Object
      >(
        readTemplates: (actualNotetype) {
          expect(actualNotetype, same(notetype));
          events.add('read-templates');
          return oldTemplates;
        },
        createEmptyTemplates: () {
          events.add('create-templates');
          return newTemplates = <_Template>[];
        },
        templateOrdinal: (template) {
          events.add('template-ord:${template.ord}');
          return template.ord;
        },
        targetOrdinal: (template) {
          events.add('target-ord:${template.ord}');
          return template.ord;
        },
        appendTemplate: (templates, template) {
          events.add('append:${template.ord}');
          templates.add(template);
        },
        logMatch: (ordinal) => events.add('log:$ordinal'),
        readTemporaryNoteType: () {
          events.add('read-temp-note-type');
          if (temporaryNoteTypeFailure case final failure?) throw failure;
          return Object();
        },
        removeTemplate: (_, ordinal) {
          events.add('remove:$ordinal');
          removedOrdinals.add(ordinal);
        },
        assignTemplates: (actualNotetype, templates) {
          expect(actualNotetype, same(notetype));
          events.add('assign-templates');
          assignedTemplates = templates;
        },
        updateTemplateOrdinals: (actualNotetype) {
          expect(actualNotetype, same(notetype));
          events.add('update-ordinals');
        },
        resolvePagerAdapterForOrdinalShift: () {
          events.add('resolve-adapter-shift');
          return Object();
        },
        ordinalShift: (_) => events.add('ordinal-shift'),
        resolvePagerAdapterForNotification: () {
          events.add('resolve-adapter-notify');
          return Object();
        },
        notifyDataSetChanged: (_) => events.add('notify-data-set-changed'),
        resolvePager: () {
          events.add('resolve-pager');
          return Object();
        },
        templatesLength: (templates) {
          events.add('templates-length');
          return templates.length;
        },
        animationDisabled: () {
          events.add('animation-disabled');
          return false;
        },
        setCurrentItem: (_, index, animationDisabled) {
          events.add('set-current:$index:$animationDisabled');
          currentIndex = index;
        },
      );
}
