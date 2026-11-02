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
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
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

typedef _Callbacks =
    CardTemplateFragmentApplyWindowInsetsCallbacks<Object, Object, Object>;

void main() {
  group('cardTemplateFragmentCreateWindowInsetsHandler', () {
    test(
      'defers host reads and applies insets and page effects in source order',
      () {
        final state = _State(imeBottom: 12, minimumHeight: 11);
        final handler = cardTemplateFragmentCreateWindowInsetsHandler(
          callbacks: state.callbacks(),
        );

        expect(state.calls, isEmpty);
        handler(state.view, state.insets, state.initial);

        expect(state.calls, [
          'ime insets',
          'ime bottom',
          'minimum height',
          'navigation visible false',
          'keyboard insets',
          'keyboard bottom',
          'view bottom 24',
          'current page',
          'update discard',
          'fragmented',
          'bars insets',
          'left inset',
          'right inset',
          'scroll padding 3 5',
        ]);
      },
    );

    test('uses strict IME threshold and zero bottom padding when hidden', () {
      final state = _State(
        imeBottom: 10,
        minimumHeight: 10,
        currentPage: false,
        fragmented: true,
      );
      cardTemplateFragmentCreateWindowInsetsHandler(
        callbacks: state.callbacks(),
      )(state.view, state.insets, state.initial);

      expect(state.calls, contains('navigation visible true'));
      expect(state.calls, contains('view bottom 0'));
      expect(state.calls, isNot(contains('update discard')));
      expect(state.calls, isNot(contains('bars insets')));
    });

    test(
      'reads live page and fragmentation state only at their source points',
      () {
        final state = _State();
        var page = false;
        var fragmented = true;
        final callbacks = state.callbacks(
          isCurrentPage: () {
            state.calls.add('current page');
            return page;
          },
          fragmented: () {
            state.calls.add('fragmented');
            return fragmented;
          },
        );
        final handler = cardTemplateFragmentCreateWindowInsetsHandler(
          callbacks: callbacks,
        );
        page = true;
        fragmented = false;

        handler(state.view, state.insets, state.initial);

        expect(state.calls, contains('update discard'));
        expect(state.calls, contains('bars insets'));
      },
    );

    test('fragmented mode skips bars sample and scroll padding reads', () {
      final state = _State(fragmented: true);
      cardTemplateFragmentCreateWindowInsetsHandler(
        callbacks: state.callbacks(),
      )(state.view, state.insets, state.initial);

      expect(state.calls, isNot(contains('bars insets')));
      expect(state.calls, isNot(contains('left inset')));
      expect(state.calls, isNot(contains('right inset')));
      expect(state.calls, isNot(contains('scroll padding 3 5')));
    });

    test('callback failure propagates and stops subsequent work', () {
      final failure = StateError('minimum height failed');
      final state = _State();
      final callbacks = state.callbacks(
        minimumHeight: () {
          state.calls.add('minimum height');
          throw failure;
        },
      );
      final handler = cardTemplateFragmentCreateWindowInsetsHandler(
        callbacks: callbacks,
      );

      expect(
        () => handler(state.view, state.insets, state.initial),
        throwsA(same(failure)),
      );
      expect(state.calls, ['ime insets', 'ime bottom', 'minimum height']);
    });
  });
}

final class _State {
  _State({
    this.imeBottom = 0,
    this.minimumHeight = 0,
    this.currentPage = true,
    this.fragmented = false,
  });

  final calls = <String>[];
  final view = Object();
  final insets = Object();
  final imeSample = Object();
  final keyboardSample = Object();
  final barsSample = Object();
  final initial = Object();
  final int imeBottom;
  final int minimumHeight;
  final int keyboardBottom = 24;
  final int left = 3;
  final int right = 5;
  final bool currentPage;
  final bool fragmented;

  _Callbacks callbacks({
    int Function()? minimumHeight,
    bool Function()? isCurrentPage,
    bool Function()? fragmented,
  }) => CardTemplateFragmentApplyWindowInsetsCallbacks<Object, Object, Object>(
    imeInsets: (insets) {
      expect(insets, same(this.insets));
      calls.add('ime insets');
      return imeSample;
    },
    bottomInset: (sample) {
      if (sample == imeSample) {
        calls.add('ime bottom');
        return imeBottom;
      }
      calls.add('keyboard bottom');
      return keyboardBottom;
    },
    minimumHeight:
        minimumHeight ??
        () {
          calls.add('minimum height');
          return this.minimumHeight;
        },
    setBottomNavigationVisible: (visible) {
      calls.add('navigation visible $visible');
    },
    keyboardInsets: (insets) {
      expect(insets, same(this.insets));
      calls.add('keyboard insets');
      return keyboardSample;
    },
    setViewBottomPadding: (view, bottom) {
      expect(view, same(this.view));
      calls.add('view bottom $bottom');
    },
    isCurrentPage:
        isCurrentPage ??
        () {
          calls.add('current page');
          return this.currentPage;
        },
    updateDiscardChangesCallback: () => calls.add('update discard'),
    fragmented:
        fragmented ??
        () {
          calls.add('fragmented');
          return this.fragmented;
        },
    barsInsets: (insets) {
      expect(insets, same(this.insets));
      calls.add('bars insets');
      return barsSample;
    },
    leftInset: (sample) {
      calls.add('left inset');
      return left;
    },
    rightInset: (sample) {
      calls.add('right inset');
      return right;
    },
    setScrollHorizontalPadding: (left, right) {
      calls.add('scroll padding $left $right');
    },
  );
}
