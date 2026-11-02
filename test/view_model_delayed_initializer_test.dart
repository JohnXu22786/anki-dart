/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from ViewModelUtils.kt and ChangeNoteTypeViewModel.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ViewModelDelayedInitializer', () {
    test('status values have source structural equality', () {
      expect(InitStatus.pending, InitStatus.pending);
      expect(InitStatus.inProgress, InitStatus.inProgress);
      expect(InitStatus.completed, InitStatus.completed);
      expect(InitStatus.pending, isNot(InitStatus.inProgress));

      final exception = Exception('failure');
      expect(InitStatus.failed(exception), InitStatus.failed(exception));
      expect(
        InitStatus.failed(Exception('failure')),
        isNot(InitStatus.failed(exception)),
      );
    });

    test('launch is called once and host can defer the work closure', () async {
      final events = <String>[];
      Future<void> Function()? work;
      var launchCalls = 0;

      projectViewModelDelayedInit(
        launch: (scheduledWork) {
          launchCalls++;
          work = scheduledWork;
          events.add('launch');
        },
        publishStatus: (status) => events.add('state:${status.runtimeType}'),
        logDebug: (message) => events.add('debug:$message'),
        logWarning: (exception, message) => events.add('warning:$message'),
        block: () async => events.add('block'),
      );

      expect(launchCalls, 1);
      expect(events, ['launch']);
      await work!();
      expect(events.first, 'launch');
      expect(events.last, 'state:InitStatusCompleted');
    });

    test('successful init publishes and logs in source order', () async {
      final events = <Object>[];
      Future<void> Function()? work;

      projectViewModelDelayedInit(
        launch: (scheduledWork) => work = scheduledWork,
        publishStatus: events.add,
        logDebug: events.add,
        logWarning: (exception, message) => events.add(exception),
        block: () async => events.add('block'),
      );

      await work!();
      expect(events, [
        InitStatus.inProgress,
        'init started',
        'block',
        'init completed',
        InitStatus.completed,
      ]);
    });

    test(
      'catches Exceptions from init, logs the same object, and publishes Failed',
      () async {
        final events = <Object>[];
        Future<void> Function()? work;
        final exception = Exception('init failed');

        projectViewModelDelayedInit(
          launch: (scheduledWork) => work = scheduledWork,
          publishStatus: events.add,
          logDebug: events.add,
          logWarning: (loggedException, message) {
            events.add(loggedException);
            events.add(message);
          },
          block: () async => throw exception,
        );

        await work!();
        expect(events, [
          InitStatus.inProgress,
          'init started',
          same(exception),
          'Failed to initialize ViewModel',
          InitStatus.failed(exception),
        ]);
      },
    );

    test('does not catch a Dart Error from init', () async {
      final events = <Object>[];
      Future<void> Function()? work;
      final error = StateError('init failed');

      projectViewModelDelayedInit(
        launch: (scheduledWork) => work = scheduledWork,
        publishStatus: events.add,
        logDebug: events.add,
        logWarning: (exception, message) => events.add(message),
        block: () async => throw error,
      );

      await expectLater(work!(), throwsA(same(error)));
      expect(events, [InitStatus.inProgress, 'init started']);
    });

    test(
      'launch and InProgress publication failures propagate before the try',
      () async {
        final launchException = Exception('launch failed');
        expect(
          () => projectViewModelDelayedInit(
            launch: (_) => throw launchException,
            publishStatus: (_) {},
            logDebug: (_) {},
            logWarning: (_, _) {},
            block: () async {},
          ),
          throwsA(same(launchException)),
        );

        final publishException = Exception('publish failed');
        Future<void> Function()? work;
        projectViewModelDelayedInit(
          launch: (scheduledWork) => work = scheduledWork,
          publishStatus: (_) => throw publishException,
          logDebug: (_) => fail('debug must not run'),
          logWarning: (_, _) => fail('warning must not run'),
          block: () async => fail('init must not run'),
        );
        await expectLater(work!(), throwsA(same(publishException)));
      },
    );

    test(
      'Exceptions from try-region logging and completion publication are caught',
      () async {
        final startLogException = Exception('start logger failed');
        Future<void> Function()? startWork;
        final startEvents = <Object>[];
        projectViewModelDelayedInit(
          launch: (scheduledWork) => startWork = scheduledWork,
          publishStatus: startEvents.add,
          logDebug: (message) {
            if (message == 'init started') throw startLogException;
          },
          logWarning: (exception, message) {
            startEvents.add(exception);
            startEvents.add(message);
          },
          block: () async => fail('init must not run'),
        );
        await startWork!();
        expect(startEvents, [
          InitStatus.inProgress,
          same(startLogException),
          'Failed to initialize ViewModel',
          InitStatus.failed(startLogException),
        ]);

        final completeLogException = Exception('completion logger failed');
        Future<void> Function()? completeWork;
        final completeEvents = <Object>[];
        projectViewModelDelayedInit(
          launch: (scheduledWork) => completeWork = scheduledWork,
          publishStatus: completeEvents.add,
          logDebug: (message) {
            if (message == 'init completed') throw completeLogException;
            completeEvents.add(message);
          },
          logWarning: (exception, message) {
            completeEvents.add(exception);
            completeEvents.add(message);
          },
          block: () async {},
        );
        await completeWork!();
        expect(completeEvents, [
          InitStatus.inProgress,
          'init started',
          same(completeLogException),
          'Failed to initialize ViewModel',
          InitStatus.failed(completeLogException),
        ]);

        final completePublishException = Exception('completion publish failed');
        Future<void> Function()? publishWork;
        final publishEvents = <Object>[];
        projectViewModelDelayedInit(
          launch: (scheduledWork) => publishWork = scheduledWork,
          publishStatus: (status) {
            publishEvents.add(status);
            if (status == InitStatus.completed) throw completePublishException;
          },
          logDebug: publishEvents.add,
          logWarning: (exception, message) {
            publishEvents.add(exception);
            publishEvents.add(message);
          },
          block: () async {},
        );
        await publishWork!();
        expect(publishEvents, [
          InitStatus.inProgress,
          'init started',
          'init completed',
          InitStatus.completed,
          same(completePublishException),
          'Failed to initialize ViewModel',
          InitStatus.failed(completePublishException),
        ]);
      },
    );

    test(
      'warning and Failed publication failures propagate from the catch handler',
      () async {
        Future<void> Function()? warningWork;
        final warningException = Exception('warning failed');
        projectViewModelDelayedInit(
          launch: (scheduledWork) => warningWork = scheduledWork,
          publishStatus: (_) {},
          logDebug: (_) {},
          logWarning: (_, _) => throw warningException,
          block: () async => throw Exception('init failed'),
        );
        await expectLater(warningWork!(), throwsA(same(warningException)));

        Future<void> Function()? publishWork;
        final publishException = Exception('failed status publish failed');
        projectViewModelDelayedInit(
          launch: (scheduledWork) => publishWork = scheduledWork,
          publishStatus: (status) {
            if (status is InitStatusFailed) throw publishException;
          },
          logDebug: (_) {},
          logWarning: (_, _) {},
          block: () async => throw Exception('init failed'),
        );
        await expectLater(publishWork!(), throwsA(same(publishException)));
      },
    );
  });
}
