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
 * Source-derived from RecyclerView.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('runWhenNotComputingLayout', () {
    test('runs the action once when layout is idle', () {
      final action = _RunnableAction();
      final recyclerView = _RecyclerViewAccess(computingLayout: false);

      runWhenNotComputingLayout(recyclerView, action);

      expect(recyclerView.layoutStateReads, 1);
      expect(action.runCalls, 1);
      expect(recyclerView.postedActions, isEmpty);
    });

    test('posts the same action once while computing layout', () {
      final action = _RunnableAction();
      final recyclerView = _RecyclerViewAccess(computingLayout: true);

      runWhenNotComputingLayout(recyclerView, action);

      expect(recyclerView.layoutStateReads, 1);
      expect(recyclerView.postedActions, hasLength(1));
      expect(identical(recyclerView.postedActions.single, action), isTrue);
      expect(action.runCalls, 0);
    });

    test('post failure propagates unchanged and skips action execution', () {
      final failure = StateError('post failed');
      final action = _RunnableAction();
      final recyclerView = _RecyclerViewAccess(
        computingLayout: true,
        postFailure: failure,
      );

      expect(
        () => runWhenNotComputingLayout(recyclerView, action),
        throwsA(same(failure)),
      );
      expect(recyclerView.layoutStateReads, 1);
      expect(recyclerView.postedActions, hasLength(1));
      expect(action.runCalls, 0);
    });

    test('action failure propagates unchanged and skips posting', () {
      final failure = StateError('action failed');
      final action = _RunnableAction(runFailure: failure);
      final recyclerView = _RecyclerViewAccess(computingLayout: false);

      expect(
        () => runWhenNotComputingLayout(recyclerView, action),
        throwsA(same(failure)),
      );
      expect(recyclerView.layoutStateReads, 1);
      expect(action.runCalls, 1);
      expect(recyclerView.postedActions, isEmpty);
    });
  });
}

class _RunnableAction implements RunnableAction {
  _RunnableAction({this.runFailure});

  final Object? runFailure;
  int runCalls = 0;

  @override
  void run() {
    runCalls++;
    if (runFailure case final failure?) throw failure;
  }
}

class _RecyclerViewAccess
    implements RecyclerViewRunWhenNotComputingLayoutAccess<RunnableAction> {
  _RecyclerViewAccess({required this.computingLayout, this.postFailure});

  final bool computingLayout;
  final Object? postFailure;
  int layoutStateReads = 0;
  final postedActions = <RunnableAction>[];

  @override
  bool get isComputingLayout {
    layoutStateReads++;
    return computingLayout;
  }

  @override
  void post(RunnableAction action) {
    postedActions.add(action);
    if (postFailure case final failure?) throw failure;
  }
}
