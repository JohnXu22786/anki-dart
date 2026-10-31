import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('handleCardTemplateCommonMenuItemSelected', () {
    test('routes every simple menu action in source order', () async {
      final reached = <String>[];
      final model = Object();
      final callbacks = CardTemplateCommonMenuCallbacks<Object, String>(
        infoLog: (message) => reached.add('info:$message'),
        debugLog: (message, [value]) => reached.add('debug:$message:$value'),
        addCardTemplate: () => reached.add('add'),
        showRepositionDialog: () => reached.add('reposition'),
        showRenameDialog: () => reached.add('rename'),
        copyMarkdownTemplateToClipboard: () => reached.add('copy'),
        showInsertFieldDialog: () => reached.add('insert'),
        deleteCardTemplate: () => reached.add('delete'),
        currentTempModel: () {
          reached.add('model');
          return model;
        },
        displayDeckOverrideDialog: (actual) {
          expect(actual, same(model));
          reached.add('override');
        },
        performPreview: () => reached.add('preview'),
        saveNoteType: () {
          reached.add('save');
          return false;
        },
        openBrowserAppearance: () {
          reached.add('appearance');
          return true;
        },
        originalStockKind: () => throw StateError('must be lazy'),
        scheduleTask: (task) => reached.add('scheduled'),
        getStockKinds: () => throw StateError('must be lazy'),
        getStockKindNames: (kinds) => throw StateError('must be lazy'),
        showStockKindPicker: (names, onSelected) =>
            throw StateError('must be lazy'),
        showRestoreConfirmation: (kind, onConfirm, onCancel) =>
            throw StateError('must be lazy'),
        restoreNotetypeToStock: (kind) async => reached.add('restore'),
      );
      final ids = testIds();

      final expected = <(int, List<String>, bool)>[
        (
          ids.add,
          ['info:${cardTemplateCommonMenuLogMessages.add}', 'add'],
          true,
        ),
        (ids.reposition, ['reposition'], true),
        (
          ids.rename,
          ['info:${cardTemplateCommonMenuLogMessages.rename}', 'rename'],
          true,
        ),
        (
          ids.copyAsMarkdown,
          ['info:${cardTemplateCommonMenuLogMessages.copyAsMarkdown}', 'copy'],
          true,
        ),
        (
          ids.insertField,
          ['info:${cardTemplateCommonMenuLogMessages.insertField}', 'insert'],
          true,
        ),
        (
          ids.delete,
          ['info:${cardTemplateCommonMenuLogMessages.delete}', 'delete'],
          true,
        ),
        (
          ids.addDeckOverride,
          [
            'info:${cardTemplateCommonMenuLogMessages.addDeckOverride}',
            'model',
            'override',
          ],
          true,
        ),
        (
          ids.preview,
          ['info:${cardTemplateCommonMenuLogMessages.preview}', 'preview'],
          true,
        ),
        (
          ids.confirm,
          ['info:${cardTemplateCommonMenuLogMessages.confirm}', 'save'],
          false,
        ),
        (
          ids.browserAppearance,
          [
            'info:${cardTemplateCommonMenuLogMessages.browserAppearance}',
            'appearance',
          ],
          true,
        ),
      ];

      for (final (id, expectedCalls, expectedResult) in expected) {
        reached.clear();
        expect(
          handleCardTemplateCommonMenuItemSelected(
            itemId: id,
            ids: ids,
            callbacks: callbacks,
          ),
          expectedResult,
        );
        expect(reached, expectedCalls);
      }

      reached.clear();
      expect(
        handleCardTemplateCommonMenuItemSelected(
          itemId: 999,
          ids: ids,
          callbacks: callbacks,
        ),
        isFalse,
      );
      expect(reached, isEmpty);
    });

    test('propagates an earlier action failure without running later work', () {
      final failure = StateError('log failed');
      final reached = <String>[];
      final callbacks = callbacksFor(
        infoLog: (message) {
          reached.add('log');
          throw failure;
        },
        addCardTemplate: () => reached.add('add'),
      );

      expect(
        () => handleCardTemplateCommonMenuItemSelected(
          itemId: testIds().add,
          ids: testIds(),
          callbacks: callbacks,
        ),
        throwsA(same(failure)),
      );
      expect(reached, ['log']);
    });

    test(
      'known kind confirms with null and schedules restore only on confirm',
      () async {
        final reached = <String>[];
        Future<void> Function()? scheduled;
        void Function()? confirm;
        void Function()? cancel;
        final callbacks = callbacksFor(
          infoLog: (message) => reached.add('info'),
          debugLog: (message, [value]) => reached.add('debug:$value'),
          originalStockKind: () {
            reached.add('kind');
            return 4;
          },
          scheduleTask: (task) {
            reached.add('schedule');
            scheduled = task;
          },
          showRestoreConfirmation: (kind, onConfirm, onCancel) {
            reached.add('confirm:$kind');
            confirm = onConfirm;
            cancel = onCancel;
          },
          restoreNotetypeToStock: (kind) async => reached.add('restore:$kind'),
        );

        expect(
          handleCardTemplateCommonMenuItemSelected(
            itemId: testIds().restoreToDefault,
            ids: testIds(),
            callbacks: callbacks,
          ),
          isTrue,
        );
        expect(reached, ['info', 'kind', 'debug:4', 'confirm:null']);
        cancel!();
        expect(reached, ['info', 'kind', 'debug:4', 'confirm:null']);
        confirm!();
        expect(reached.last, 'schedule');
        await scheduled!();
        expect(reached.last, 'restore:null');
      },
    );

    test(
      'unknown kind schedules before async work and resolves selected kind',
      () async {
        final reached = <String>[];
        Future<void> Function()? scheduled;
        void Function(int)? select;
        void Function()? confirm;
        final callbacks = callbacksFor(
          infoLog: (message) => reached.add('info'),
          debugLog: (message, [value]) => reached.add('debug:$message'),
          originalStockKind: () {
            reached.add('kind');
            return -1;
          },
          scheduleTask: (task) {
            reached.add('schedule');
            scheduled = task;
          },
          getStockKinds: () async {
            reached.add('stock-kinds');
            return ['first', 'chosen', 'last'];
          },
          getStockKindNames: (kinds) async {
            reached.add('names:$kinds');
            return ['First', 'Chosen', 'Last'];
          },
          showStockKindPicker: (names, onSelected) {
            reached.add('picker:$names');
            select = onSelected;
          },
          showRestoreConfirmation: (kind, onConfirm, onCancel) {
            reached.add('confirm:$kind');
            confirm = onConfirm;
          },
          restoreNotetypeToStock: (kind) async => reached.add('restore:$kind'),
        );

        expect(
          handleCardTemplateCommonMenuItemSelected(
            itemId: testIds().restoreToDefault,
            ids: testIds(),
            callbacks: callbacks,
          ),
          isTrue,
        );
        expect(reached, ['info', 'kind', 'schedule']);
        await scheduled!();
        expect(reached, [
          'info',
          'kind',
          'schedule',
          'debug:${cardTemplateCommonMenuLogMessages.unknownStockKind}',
          'stock-kinds',
          'names:[first, chosen, last]',
          'picker:[First, Chosen, Last]',
        ]);
        select!(1);
        expect(reached.last, 'confirm:chosen');
        confirm!();
        expect(reached.last, 'schedule');
        await scheduled!();
        expect(reached.last, 'restore:chosen');
      },
    );

    test(
      'unknown restore task failure propagates and stops later callbacks',
      () async {
        final failure = StateError('names failed');
        final reached = <String>[];
        Future<void> Function()? scheduled;
        final callbacks = callbacksFor(
          infoLog: (message) {},
          originalStockKind: () => -1,
          scheduleTask: (task) => scheduled = task,
          getStockKinds: () async => ['kind'],
          getStockKindNames: (kinds) async {
            reached.add('names');
            throw failure;
          },
          showStockKindPicker: (names, onSelected) => reached.add('picker'),
        );
        handleCardTemplateCommonMenuItemSelected(
          itemId: testIds().restoreToDefault,
          ids: testIds(),
          callbacks: callbacks,
        );

        await expectLater(scheduled!(), throwsA(same(failure)));
        expect(reached, ['names']);
      },
    );
  });
}

CardTemplateCommonMenuItemIds testIds() => const CardTemplateCommonMenuItemIds(
  add: 1,
  reposition: 2,
  rename: 3,
  copyAsMarkdown: 4,
  insertField: 5,
  delete: 6,
  addDeckOverride: 7,
  preview: 8,
  confirm: 9,
  browserAppearance: 10,
  restoreToDefault: 11,
  unknownStockKind: -1,
);

CardTemplateCommonMenuCallbacks<Object, String> callbacksFor({
  void Function(String)? infoLog,
  void Function(String, [Object?])? debugLog,
  void Function()? addCardTemplate,
  void Function()? showRepositionDialog,
  void Function()? showRenameDialog,
  void Function()? copyMarkdownTemplateToClipboard,
  void Function()? showInsertFieldDialog,
  void Function()? deleteCardTemplate,
  Object Function()? currentTempModel,
  void Function(Object)? displayDeckOverrideDialog,
  void Function()? performPreview,
  bool Function()? saveNoteType,
  bool Function()? openBrowserAppearance,
  int Function()? originalStockKind,
  void Function(Future<void> Function())? scheduleTask,
  Future<List<String>> Function()? getStockKinds,
  Future<List<String>> Function(List<String>)? getStockKindNames,
  void Function(List<String>, void Function(int))? showStockKindPicker,
  void Function(String?, void Function(), void Function())?
  showRestoreConfirmation,
  Future<void> Function(String?)? restoreNotetypeToStock,
}) => CardTemplateCommonMenuCallbacks<Object, String>(
  infoLog: infoLog ?? (message) {},
  debugLog: debugLog ?? (message, [value]) {},
  addCardTemplate: addCardTemplate ?? () {},
  showRepositionDialog: showRepositionDialog ?? () {},
  showRenameDialog: showRenameDialog ?? () {},
  copyMarkdownTemplateToClipboard: copyMarkdownTemplateToClipboard ?? () {},
  showInsertFieldDialog: showInsertFieldDialog ?? () {},
  deleteCardTemplate: deleteCardTemplate ?? () {},
  currentTempModel: currentTempModel ?? Object.new,
  displayDeckOverrideDialog: displayDeckOverrideDialog ?? (_) {},
  performPreview: performPreview ?? () {},
  saveNoteType: saveNoteType ?? () => true,
  openBrowserAppearance: openBrowserAppearance ?? () => true,
  originalStockKind: originalStockKind ?? () => -1,
  scheduleTask: scheduleTask ?? (task) {},
  getStockKinds: getStockKinds ?? () async => <String>[],
  getStockKindNames: getStockKindNames ?? (kinds) async => kinds,
  showStockKindPicker: showStockKindPicker ?? (names, onSelected) {},
  showRestoreConfirmation:
      showRestoreConfirmation ?? (kind, onConfirm, onCancel) {},
  restoreNotetypeToStock: restoreNotetypeToStock ?? (kind) async {},
);
