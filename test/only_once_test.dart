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
 * Source-derived from OnlyOnce.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

class _Job {
  _Job(this.isActive);

  final bool isActive;
  void Function()? onCompletion;
}

void main() {
  group('OnlyOnce', () {
    test('method values retain source declaration order and names', () {
      expect(OnlyOnceMethod.values.map((method) => method.name), [
        'ANSWER_CARD',
        'UNIT_TEST',
      ]);
    });

    test(
      'blocks duplicate calls until completion and logs in source order',
      () {
        final onlyOnce = OnlyOnce();
        final events = <String>[];
        var calls = 0;
        _Job? job;

        onlyOnce.preventSimultaneousExecutions<_Job>(
          name: OnlyOnceMethod.UNIT_TEST,
          function: () {
            calls++;
            return job = _Job(false);
          },
          invokeOnCompletion: (job, callback) => job.onCompletion = callback,
          logWarning: (message) => events.add('warning:$message'),
          logVerbose: (message) => events.add('verbose:$message'),
        );
        onlyOnce.preventSimultaneousExecutions<_Job>(
          name: OnlyOnceMethod.UNIT_TEST,
          function: () {
            calls++;
            return _Job(false);
          },
          invokeOnCompletion: (job, callback) => job.onCompletion = callback,
          logWarning: (message) => events.add('warning:$message'),
          logVerbose: (message) => events.add('verbose:$message'),
        );

        expect(calls, 1);
        expect(events, [
          'verbose:executing UNIT_TEST',
          'warning:simultaneously executions of UNIT_TEST blocked',
        ]);
        expect(job!.onCompletion, isNotNull);

        job!.onCompletion!();
        expect(events.last, 'verbose:completed UNIT_TEST');
        _Job? secondJob;
        onlyOnce.preventSimultaneousExecutions<_Job>(
          name: OnlyOnceMethod.UNIT_TEST,
          function: () {
            calls++;
            return secondJob = _Job(false);
          },
          invokeOnCompletion: (job, callback) => job.onCompletion = callback,
          logWarning: (message) => events.add('warning:$message'),
          logVerbose: (message) => events.add('verbose:$message'),
        );
        expect(calls, 2);
        secondJob!.onCompletion!();
      },
    );

    test('shares method blocks and completion release across instances', () {
      final first = OnlyOnce();
      final second = OnlyOnce();
      final events = <String>[];
      var calls = 0;
      final heldJob = _Job(false);

      void invoke(OnlyOnce onlyOnce) =>
          onlyOnce.preventSimultaneousExecutions<_Job>(
            name: OnlyOnceMethod.ANSWER_CARD,
            function: () {
              calls++;
              return heldJob;
            },
            invokeOnCompletion: (job, callback) => job.onCompletion = callback,
            logWarning: (message) => events.add('warning:$message'),
            logVerbose: (message) => events.add('verbose:$message'),
          );

      invoke(first);
      invoke(second);
      expect(calls, 1);
      expect(
        events,
        contains('warning:simultaneously executions of ANSWER_CARD blocked'),
      );

      heldJob.onCompletion!();
      invoke(second);
      expect(calls, 2);
      expect(events.last, 'verbose:executing ANSWER_CARD');
      heldJob.onCompletion!();
    });

    test(
      'synchronous function failures propagate and keep the method blocked',
      () {
        final onlyOnce = OnlyOnce();
        final error = StateError('function failed');
        var calls = 0;
        var warnings = 0;

        void invoke() => onlyOnce.preventSimultaneousExecutions<_Job>(
          name: OnlyOnceMethod.UNIT_TEST,
          function: () {
            calls++;
            throw error;
          },
          invokeOnCompletion: (job, callback) => job.onCompletion = callback,
          logWarning: (_) => warnings++,
          logVerbose: (_) {},
        );

        expect(invoke, throwsA(same(error)));
        invoke();
        expect(calls, 1);
        expect(warnings, 1);
      },
    );

    test(
      'RunOnlyOnce checks activity once, skips active calls, then assigns',
      () {
        final previous = _Job(true);
        final launched = _Job(true);
        final runOnlyOnce = RunOnlyOnce<_Job>(initialJob: previous);
        var checks = 0;
        var launches = 0;
        var debugLogs = 0;

        void run() => runOnlyOnce.launch(
          isActive: (job) {
            checks++;
            return job?.isActive ?? false;
          },
          launch: () {
            launches++;
            return launched;
          },
          logDebug: (_) => debugLogs++,
        );

        run();
        run();
        expect(checks, 2);
        expect(launches, 0);
        expect(debugLogs, 2);
        expect(runOnlyOnce.job, same(previous));

        final idle = RunOnlyOnce<_Job>(initialJob: _Job(false));
        var idleChecks = 0;
        idle.launch(
          isActive: (job) {
            idleChecks++;
            return job?.isActive ?? false;
          },
          launch: () => launched,
          logDebug: (_) {},
        );
        expect(idleChecks, 1);
        expect(idle.job, same(launched));
      },
    );

    test('launch failure propagates and preserves the previous job', () {
      final previous = _Job(false);
      final runOnlyOnce = RunOnlyOnce<_Job>(initialJob: previous);
      final error = StateError('launch failed');
      var checks = 0;

      expect(
        () => runOnlyOnce.launch(
          isActive: (job) {
            checks++;
            return job?.isActive ?? false;
          },
          launch: () => throw error,
          logDebug: (_) {},
        ),
        throwsA(same(error)),
      );
      expect(checks, 1);
      expect(runOnlyOnce.job, same(previous));
    });
  });
}
