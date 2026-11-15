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
  group('cardTemplateFragmentShowRenameDialog', () {
    test('dynamic note types warn and return before later callbacks', () {
      final harness = _Harness(isCloze: true);

      cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);

      expect(harness.events, ['is cloze', 'warn']);
      expect(harness.warning, 'attempted to rename a dynamic note type');
      expect(harness.dialogConfirmation, isNull);
    });

    test('image occlusion note types also warn before later callbacks', () {
      final harness = _Harness(isImageOcclusion: true);

      cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);

      expect(harness.events, ['is cloze', 'is image occlusion', 'warn']);
      expect(harness.warning, 'attempted to rename a dynamic note type');
    });

    test('warning failures propagate before any later callback', () {
      final harness = _Harness(isCloze: true, failAt: 'warn');

      expect(
        () =>
            cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks),
        throwsA(same(harness.failure)),
      );
      expect(harness.events, ['is cloze', 'warn']);
    });

    test(
      'prepares in source order and preserves repeated reads and name order',
      () {
        final harness = _Harness();

        cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);

        expect(harness.events, [
          'is cloze',
          'is image occlusion',
          'ordinal',
          'temporary model',
          'selected template',
          'temporary model second',
          'notetype templates',
          'template name first',
          'convert First',
          'template name selected existing',
          'convert Selected existing',
          'template name duplicate',
          'convert Duplicate',
          'template name duplicate again',
          'convert Duplicate again',
          'require context',
          'template name selected for prefill',
          'template name selected for current name',
          'convert Selected current',
          'show dialog',
        ]);
        expect(harness.ordinalReads, 1);
        expect(harness.tempModelReads, 2);
        expect(harness.nameReads, 6);
        expect(harness.dialogContext, same(harness.context));
        expect(harness.dialogPrefill, 'Selected prefill');
        expect(harness.dialogCurrentName?.value, 'Selected current');
        expect(harness.dialogExistingNames?.map((name) => name.value), [
          'First',
          'Selected existing',
          'Duplicate',
          'Duplicate',
        ]);
      },
    );

    test(
      'confirmation is deferred and applies ordered effects to same handles',
      () {
        final harness = _Harness();

        cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);
        final beforeConfirmation = [...harness.events];
        expect(beforeConfirmation.last, 'show dialog');
        expect(harness.assignedValue, isNull);

        harness.dialogConfirmation!(harness.newName);

        expect(harness.events, [
          ...beforeConfirmation,
          'new name value',
          'assign name',
          'update discard callback',
          'info log',
          'debug log',
          'pager adapter',
          'notify adapter',
          'reload previewer',
        ]);
        expect(harness.assignedTemplate, same(harness.selectedTemplate));
        expect(harness.assignedValue, 'Renamed');
        expect(harness.infoMessage, 'updated card template name');
        expect(harness.debugFormat, "updated name of template %d to '%s'");
        expect(harness.debugOrdinal, 12);
        expect(harness.debugName, same(harness.newName));
        expect(harness.notifiedAdapter, same(harness.adapter));
      },
    );

    test('null temporary model assertion stops before template access', () {
      final harness = _Harness(nullModelRead: 1);

      expect(
        () =>
            cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks),
        throwsA(isA<TypeError>()),
      );
      expect(harness.events, [
        'is cloze',
        'is image occlusion',
        'ordinal',
        'temporary model',
      ]);
    });

    test('null pager adapter assertion stops before notify and reload', () {
      final harness = _Harness(nullAdapter: true);
      cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);

      expect(
        () => harness.dialogConfirmation!(harness.newName),
        throwsA(isA<TypeError>()),
      );
      expect(harness.events.last, 'pager adapter');
      expect(harness.events, isNot(contains('notify adapter')));
      expect(harness.events, isNot(contains('reload previewer')));
    });

    test(
      'preparation failures propagate unchanged and stop later callbacks',
      () {
        const preparationStages = [
          'is cloze',
          'is image occlusion',
          'ordinal',
          'temporary model',
          'selected template',
          'temporary model second',
          'notetype templates',
          'template name first',
          'convert First',
          'template name selected existing',
          'convert Selected existing',
          'template name duplicate',
          'convert Duplicate',
          'template name duplicate again',
          'convert Duplicate again',
          'require context',
          'template name selected for prefill',
          'template name selected for current name',
          'convert Selected current',
          'show dialog',
        ];
        for (var i = 0; i < preparationStages.length; i++) {
          final failedStage = preparationStages[i];
          final harness = _Harness(failAt: failedStage);

          expect(
            () => cardTemplateFragmentShowRenameDialog(
              callbacks: harness.callbacks,
            ),
            throwsA(same(harness.failure)),
            reason: failedStage,
          );
          expect(harness.events.last, failedStage, reason: failedStage);
          expect(
            harness.events,
            preparationStages.take(i + 1),
            reason: failedStage,
          );
        }
      },
    );

    test('confirmation failures stop remaining confirmation effects', () {
      const confirmationStages = [
        'new name value',
        'assign name',
        'update discard callback',
        'info log',
        'debug log',
        'pager adapter',
        'notify adapter',
        'reload previewer',
      ];
      for (var i = 0; i < confirmationStages.length; i++) {
        final failedStage = confirmationStages[i];
        final harness = _Harness(failAt: failedStage);
        cardTemplateFragmentShowRenameDialog(callbacks: harness.callbacks);

        expect(
          () => harness.dialogConfirmation!(harness.newName),
          throwsA(same(harness.failure)),
          reason: failedStage,
        );
        expect(
          harness.events.where(confirmationStages.contains),
          confirmationStages.take(i + 1),
          reason: failedStage,
        );
      }
    });
  });
}

final class _Handle {
  const _Handle(this.value);
  final String value;
}

final class _Harness {
  _Harness({
    this.isCloze = false,
    this.isImageOcclusion = false,
    this.failAt,
    this.nullModelRead,
    this.nullAdapter = false,
  });

  final bool isCloze;
  final bool isImageOcclusion;
  final String? failAt;
  final int? nullModelRead;
  final bool nullAdapter;
  final failure = StateError('callback failed');
  final events = <String>[];
  final tempModel = _Handle('temporary model');
  final selectedTemplate = _Handle('selected');
  final firstTemplate = _Handle('first');
  final duplicateTemplate = _Handle('duplicate');
  final duplicateTemplateAgain = _Handle('duplicate again');
  final context = _Handle('context');
  final adapter = _Handle('adapter');
  final newName = _Handle('new name');
  int ordinalReads = 0;
  int tempModelReads = 0;
  int nameReads = 0;
  String? warning;
  String? dialogPrefill;
  _Handle? dialogContext;
  _Handle? dialogCurrentName;
  List<_Handle>? dialogExistingNames;
  void Function(_Handle newName)? dialogConfirmation;
  _Handle? assignedTemplate;
  String? assignedValue;
  String? infoMessage;
  String? debugFormat;
  int? debugOrdinal;
  _Handle? debugName;
  _Handle? notifiedAdapter;
  int selectedNameReads = 0;
  int duplicateConversionReads = 0;

  void hit(String event) {
    events.add(event);
    if (failAt == event) throw failure;
  }

  String templateName(_Handle template) {
    if (identical(template, firstTemplate)) {
      hit('template name first');
      return 'First';
    }
    if (identical(template, duplicateTemplate)) {
      hit('template name duplicate');
      return 'Duplicate';
    }
    if (identical(template, duplicateTemplateAgain)) {
      hit('template name duplicate again');
      return 'Duplicate';
    }
    if (identical(template, selectedTemplate)) {
      selectedNameReads++;
      if (selectedNameReads == 1) {
        hit('template name selected existing');
        return 'Selected existing';
      }
      if (selectedNameReads == 2) {
        hit('template name selected for prefill');
        return 'Selected prefill';
      }
      hit('template name selected for current name');
      return 'Selected current';
    }
    throw StateError('unexpected template handle');
  }

  CardTemplateFragmentShowRenameDialogCallbacks<
    _Handle,
    _Handle,
    _Handle,
    _Handle,
    _Handle,
    _Handle
  >
  get callbacks => CardTemplateFragmentShowRenameDialogCallbacks(
    isCloze: () {
      hit('is cloze');
      return isCloze;
    },
    isImageOcclusion: () {
      hit('is image occlusion');
      return isImageOcclusion;
    },
    warn: (message) {
      hit('warn');
      warning = message;
    },
    readOrdinal: () {
      hit('ordinal');
      ordinalReads++;
      return 12;
    },
    readTemporaryModel: () {
      tempModelReads++;
      hit(tempModelReads == 2 ? 'temporary model second' : 'temporary model');
      return tempModelReads == nullModelRead ? null : tempModel;
    },
    readSelectedTemplate: (model, ordinal) {
      hit('selected template');
      expect(model, same(tempModel));
      expect(ordinal, 12);
      return selectedTemplate;
    },
    readNotetypeTemplates: (model) {
      hit('notetype templates');
      expect(model, same(tempModel));
      return [
        firstTemplate,
        selectedTemplate,
        duplicateTemplate,
        duplicateTemplateAgain,
      ];
    },
    readTemplateName: (template) {
      nameReads++;
      return templateName(template);
    },
    cardTypeNameFromString: (name) {
      final conversionEvent = switch (name) {
        'Duplicate' =>
          ++duplicateConversionReads == 1
              ? 'convert Duplicate'
              : 'convert Duplicate again',
        _ => 'convert $name',
      };
      hit(conversionEvent);
      final result = _Handle(name);
      return result;
    },
    requireContext: () {
      hit('require context');
      return context;
    },
    showRenameDialog:
        ({
          required context,
          required prefill,
          required currentName,
          required existingNames,
          required onConfirm,
        }) {
          hit('show dialog');
          dialogContext = context;
          dialogPrefill = prefill;
          dialogCurrentName = currentName;
          dialogExistingNames = existingNames;
          dialogConfirmation = onConfirm;
        },
    readNewNameValue: (name) {
      hit('new name value');
      expect(name, same(newName));
      return 'Renamed';
    },
    assignTemplateName: (template, value) {
      hit('assign name');
      assignedTemplate = template;
      assignedValue = value;
    },
    updateDiscardChangesCallback: () => hit('update discard callback'),
    infoLog: (message) {
      hit('info log');
      infoMessage = message;
    },
    debugLog: (format, ordinal, name) {
      hit('debug log');
      debugFormat = format;
      debugOrdinal = ordinal;
      debugName = name;
    },
    readPagerAdapter: () {
      hit('pager adapter');
      return nullAdapter ? null : adapter;
    },
    notifyAdapterDataSetChanged: (actualAdapter) {
      hit('notify adapter');
      notifiedAdapter = actualAdapter;
    },
    loadTemplatePreviewerIfFragmented: () => hit('reload previewer'),
  );
}
