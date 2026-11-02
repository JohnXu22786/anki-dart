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
 * Source-derived from AnkiDroid 2.25.3 EditDeckDescriptionDialogViewModel.kt;
 * see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Edit Deck Description state', () {
    test('fresh initialization replaces saved values and completes', () {
      final state = EditDeckDescriptionDialogState(
        restoredDescription: 'stale saved value',
        restoredFormatAsMarkdown: true,
      );

      state.initialize(
        persistedDescription: 'database description',
        persistedFormatAsMarkdown: false,
      );

      expect(state.description, 'database description');
      expect(state.formatAsMarkdown, isFalse);
      expect(state.userHasMadeChanges, isFalse);
      expect(state.isInitialStateComplete, isTrue);
      expect(state.hasChanges, isFalse);
    });

    test('restored user edits survive initialization', () {
      final state = EditDeckDescriptionDialogState(
        restoredDescription: 'restored description',
        restoredFormatAsMarkdown: true,
        restoredUserHasMadeChanges: true,
      );

      state.initialize(
        persistedDescription: 'database description',
        persistedFormatAsMarkdown: false,
      );

      expect(state.description, 'restored description');
      expect(state.formatAsMarkdown, isTrue);
      expect(state.userHasMadeChanges, isTrue);
      expect(state.isInitialStateComplete, isTrue);
      expect(state.hasChanges, isTrue);
    });

    test('both setters mark edits even when assigned the current value', () {
      final description = EditDeckDescriptionDialogState();
      description.initialize(
        persistedDescription: '',
        persistedFormatAsMarkdown: false,
      );
      description.description = '';
      expect(description.userHasMadeChanges, isTrue);
      expect(description.hasChanges, isFalse);

      final markdown = EditDeckDescriptionDialogState();
      markdown.initialize(
        persistedDescription: '',
        persistedFormatAsMarkdown: false,
      );
      markdown.formatAsMarkdown = false;
      expect(markdown.userHasMadeChanges, isTrue);
      expect(markdown.hasChanges, isFalse);
    });

    test(
      'change comparison waits for initialization and accepts reversion',
      () {
        final state = EditDeckDescriptionDialogState();
        state.description = 'edited before initialization';
        expect(state.hasChanges, isFalse);

        state.initialize(
          persistedDescription: 'initial',
          persistedFormatAsMarkdown: false,
        );
        expect(state.hasChanges, isTrue);

        state.description = 'initial';
        expect(state.hasChanges, isFalse);
      },
    );

    test(
      'back closes unchanged state and requests confirmation when changed',
      () {
        final state = EditDeckDescriptionDialogState();
        state.initialize(
          persistedDescription: 'initial',
          persistedFormatAsMarkdown: false,
        );
        expect(
          state.onBackRequested(),
          EditDeckDescriptionBackAction.closeWithoutSaving,
        );

        state.formatAsMarkdown = true;
        expect(
          state.onBackRequested(),
          EditDeckDescriptionBackAction.showDiscardConfirmation,
        );
      },
    );

    test('explicit close dismisses without saving despite edits', () {
      final state = EditDeckDescriptionDialogState();
      state.description = 'unsaved';

      expect(
        state.closeWithoutSaving(),
        EditDeckDescriptionDismissal.closedWithoutSaving,
      );
    });

    test('save plan persists the current snapshot before Saved dismissal', () {
      final state = EditDeckDescriptionDialogState();
      state.initialize(
        persistedDescription: 'initial',
        persistedFormatAsMarkdown: false,
      );
      state.description = 'saved description';
      state.formatAsMarkdown = true;

      final actions = state.saveAndExitActions();

      expect(actions, hasLength(2));
      expect(actions.first, isA<EditDeckDescriptionPersistAction>());
      final save = actions.first as EditDeckDescriptionPersistAction;
      expect(save.description, 'saved description');
      expect(save.formatAsMarkdown, isTrue);
      expect(
        actions.last,
        const EditDeckDescriptionDismissAction(
          EditDeckDescriptionDismissal.saved,
        ),
      );
    });
  });
}
