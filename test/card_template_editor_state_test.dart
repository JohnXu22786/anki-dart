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
 * SPDX-FileCopyrightText: 2025 Snowiee <xenonnn4w@gmail.com>
 * SPDX-FileCopyrightText: 2025 lukstbit <52494258+lukstbit@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from CardTemplateEditorState.kt and
 * CardTemplateEditorViewModel.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Template Editor state', () {
    test('enum cases preserve source order', () {
      expect(EditorViewType.values, [
        EditorViewType.FRONT,
        EditorViewType.BACK,
        EditorViewType.STYLING,
      ]);
      expect(CardTemplateEditorUserMessage.values, [
        CardTemplateEditorUserMessage.CantDeleteLastTemplate,
        CardTemplateEditorUserMessage.CantAddTemplateToDynamic,
        CardTemplateEditorUserMessage.SaveSuccess,
        CardTemplateEditorUserMessage.DeletionWouldOrphanNote,
      ]);
    });

    test('starts initializing and exposes source defaults', () {
      final model = CardTemplateEditorStateMachine();
      expect(model.state, isA<CardTemplateEditorInitializing>());
      expect(const CardTemplateEditorInitializing().exception, isNull);

      const loaded = CardTemplateEditorLoaded();
      expect(loaded.currentTemplateOrd, 0);
      expect(loaded.currentEditorView, EditorViewType.FRONT);
      expect(loaded.message, isNull);
      expect(loaded.error, isNull);
    });

    test('load, error, and finish transitions replace the full state', () {
      final model = CardTemplateEditorStateMachine();
      final exception = ReportableExceptionData(
        source: StateError('load failed'),
        isReportable: false,
      );
      model.onError(exception);
      expect(model.state, CardTemplateEditorInitializing(exception));
      expect(
        (model.state as CardTemplateEditorInitializing).exception,
        same(exception),
      );
      expect(
        (model.state as CardTemplateEditorInitializing).exception!.isReportable,
        isFalse,
      );

      model.onLoadComplete();
      expect(model.state, const CardTemplateEditorLoaded());
      model.setCurrentTemplateOrd(3);
      model.onError(exception);
      expect(model.state, CardTemplateEditorInitializing(exception));
      model.onLoadComplete();
      expect(model.state, const CardTemplateEditorLoaded());

      model.onFinish();
      expect(model.state, CardTemplateEditorFinished.instance);
    });

    test('loaded updates change only the requested field', () {
      const message = CardTemplateEditorUserMessage.SaveSuccess;
      final error = ReportableExceptionData(source: StateError('save failed'));
      final model = CardTemplateEditorStateMachine(
        initialState: CardTemplateEditorLoaded(
          currentTemplateOrd: 2,
          currentEditorView: EditorViewType.BACK,
          message: message,
          error: error,
        ),
      );

      model.setCurrentTemplateOrd(4);
      expect(
        model.state,
        CardTemplateEditorLoaded(
          currentTemplateOrd: 4,
          currentEditorView: EditorViewType.BACK,
          message: message,
          error: error,
        ),
      );
      model.setCurrentEditorView(EditorViewType.STYLING);
      expect(
        model.state,
        CardTemplateEditorLoaded(
          currentTemplateOrd: 4,
          currentEditorView: EditorViewType.STYLING,
          message: message,
          error: error,
        ),
      );
      model.clearMessage();
      expect(
        model.state,
        CardTemplateEditorLoaded(
          currentTemplateOrd: 4,
          currentEditorView: EditorViewType.STYLING,
          error: error,
        ),
      );
      model.clearError();
      expect(
        model.state,
        const CardTemplateEditorLoaded(
          currentTemplateOrd: 4,
          currentEditorView: EditorViewType.STYLING,
        ),
      );
    });

    test('loaded state retains opaque error payload and reportable flag', () {
      final hostError = Object();
      final exception = ReportableExceptionData(
        source: hostError,
        isReportable: false,
      );
      final loaded = CardTemplateEditorLoaded(error: exception);
      expect(loaded.error!.source, same(hostError));
      expect(loaded.error!.isReportable, isFalse);
    });

    test('updates outside loaded retain the exact state instance', () {
      final initializing = CardTemplateEditorInitializing(
        ReportableExceptionData(source: StateError('initialization failed')),
      );
      final initializingModel = CardTemplateEditorStateMachine(
        initialState: initializing,
      );
      _applyEveryUpdate(initializingModel);
      expect(initializingModel.state, same(initializing));

      final finished = CardTemplateEditorFinished.instance;
      final finishedModel = CardTemplateEditorStateMachine(
        initialState: finished,
      );
      _applyEveryUpdate(finishedModel);
      expect(finishedModel.state, same(finished));

      for (final terminalState in [initializing, finished]) {
        final model = CardTemplateEditorStateMachine(
          initialState: terminalState,
        );
        model.onLoadComplete();
        expect(model.state, const CardTemplateEditorLoaded());
        model.onError(
          ReportableExceptionData(source: StateError('next failure')),
        );
        expect(model.state, isA<CardTemplateEditorInitializing>());
        model.onFinish();
        expect(model.state, same(CardTemplateEditorFinished.instance));
      }
    });

    test('state values preserve Kotlin data-class equality semantics', () {
      final hostError = StateError('same host error');
      final exception = ReportableExceptionData(source: hostError);
      final equalException = ReportableExceptionData(source: hostError);
      expect(exception, equalException);
      expect(exception.hashCode, equalException.hashCode);
      expect(
        CardTemplateEditorInitializing(exception),
        CardTemplateEditorInitializing(equalException),
      );
      expect(
        CardTemplateEditorInitializing(exception).hashCode,
        CardTemplateEditorInitializing(equalException).hashCode,
      );
      final valueException = ReportableExceptionData(
        source: const _ValueException(7),
      );
      final equalValueException = ReportableExceptionData(
        source: const _ValueException(7),
      );
      expect(valueException, equalValueException);
      expect(valueException.hashCode, equalValueException.hashCode);
      expect(valueException.isReportable, isTrue);
      expect(
        ReportableExceptionData(source: hostError, isReportable: false),
        isNot(exception),
      );

      const loaded = CardTemplateEditorLoaded(
        currentTemplateOrd: 5,
        currentEditorView: EditorViewType.BACK,
        message: CardTemplateEditorUserMessage.SaveSuccess,
      );
      const equalLoaded = CardTemplateEditorLoaded(
        currentTemplateOrd: 5,
        currentEditorView: EditorViewType.BACK,
        message: CardTemplateEditorUserMessage.SaveSuccess,
      );
      expect(loaded, equalLoaded);
      expect(loaded.hashCode, equalLoaded.hashCode);
      for (final differentField in [
        const CardTemplateEditorLoaded(
          currentTemplateOrd: 6,
          currentEditorView: EditorViewType.BACK,
          message: CardTemplateEditorUserMessage.SaveSuccess,
        ),
        const CardTemplateEditorLoaded(
          currentTemplateOrd: 5,
          currentEditorView: EditorViewType.FRONT,
          message: CardTemplateEditorUserMessage.SaveSuccess,
        ),
        const CardTemplateEditorLoaded(
          currentTemplateOrd: 5,
          currentEditorView: EditorViewType.BACK,
          message: CardTemplateEditorUserMessage.CantDeleteLastTemplate,
        ),
        CardTemplateEditorLoaded(
          currentTemplateOrd: 5,
          currentEditorView: EditorViewType.BACK,
          message: CardTemplateEditorUserMessage.SaveSuccess,
          error: exception,
        ),
      ]) {
        expect(loaded, isNot(differentField));
      }
      expect(
        CardTemplateEditorFinished.instance,
        CardTemplateEditorFinished.instance,
      );
      expect(
        CardTemplateEditorFinished.instance.hashCode,
        CardTemplateEditorFinished.instance.hashCode,
      );
    });
  });
}

void _applyEveryUpdate(CardTemplateEditorStateMachine model) {
  model.setCurrentTemplateOrd(8);
  model.setCurrentEditorView(EditorViewType.STYLING);
  model.clearMessage();
  model.clearError();
}

final class _ValueException {
  const _ValueException(this.code);

  final int code;

  @override
  bool operator ==(Object other) =>
      other is _ValueException && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
