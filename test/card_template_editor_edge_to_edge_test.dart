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
 * Source-derived from CardTemplateEditor.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Card Template Editor edge-to-edge setup', () {
    test('registers listeners in order and lazily applies source padding', () {
      final calls = <String>[];
      final topInsets = _Insets(left: 1, top: 2, right: 3);
      final rootInsets = _Insets(left: 4, top: 5, right: 6);
      final topInput = _Insets(left: 10, top: 11, right: 12);
      final rootInput = _Insets(left: 13, top: 14, right: 15);
      Object? returnedTop;
      Object? returnedRoot;
      Object? topMask;
      Object? rootMask;
      Object? lookupTop;
      Object? lookupEditor;
      Object? lookupContainer;
      late _Insets Function(_Insets) topListener;
      late _Insets Function(_Insets) rootListener;

      setupCardTemplateEditorEdgeToEdge<_Insets, Object, Object>(
        enableEdgeToEdgeDarkTransparent: () => calls.add('enable'),
        installTopInsetsListener: (listener) {
          calls.add('install-top');
          topListener = listener;
        },
        installRootInsetsListener: (listener) {
          calls.add('install-root');
          rootListener = listener;
        },
        topInsetTypes: () {
          calls.add('top-mask');
          return topMask = 'system-bars|display-cutout';
        },
        rootInsetTypes: () {
          calls.add('root-mask');
          return rootMask = 'system-bars|display-cutout|ime';
        },
        getInsets: (input, mask) {
          calls.add('get-insets:$mask');
          return identical(input, topInput) ? topInsets : rootInsets;
        },
        isFragmented: () {
          calls.add('fragmented');
          return true;
        },
        findTopView: () {
          calls.add('find-top');
          return lookupTop = Object();
        },
        findEditorView: () {
          calls.add('find-editor');
          return lookupEditor = Object();
        },
        findFragmentContainerView: () {
          calls.add('find-container');
          return lookupContainer = Object();
        },
        leftInset: (value) {
          calls.add('left:${value.left}');
          return value.left;
        },
        topInset: (value) {
          calls.add('top:${value.top}');
          return value.top;
        },
        rightInset: (value) {
          calls.add('right:${value.right}');
          return value.right;
        },
        updatePadding: (view, {left, top, right}) {
          calls.add(
            'padding:${identical(view, lookupTop)
                ? 'top'
                : identical(view, lookupEditor)
                ? 'editor'
                : identical(view, lookupContainer)
                ? 'container'
                : 'unknown'}:$left:$top:$right',
          );
        },
      );

      expect(calls, ['enable', 'install-top', 'install-root']);
      expect(topMask, isNull);
      expect(rootMask, isNull);
      returnedTop = topListener(topInput);
      expect(identical(returnedTop, topInput), isTrue);
      returnedRoot = rootListener(rootInput);
      expect(identical(returnedRoot, rootInput), isTrue);
      expect(calls, [
        'enable',
        'install-top',
        'install-root',
        'top-mask',
        'get-insets:system-bars|display-cutout',
        'find-top',
        'left:1',
        'top:2',
        'right:3',
        'padding:top:1:2:3',
        'root-mask',
        'get-insets:system-bars|display-cutout|ime',
        'fragmented',
        'find-editor',
        'left:4',
        'padding:editor:4:null:null',
        'find-container',
        'right:6',
        'padding:container:null:null:6',
      ]);
    });

    test('non-fragmented root callback skips both view lookups', () {
      final calls = <String>[];
      late _Insets Function(_Insets) rootListener;

      setupCardTemplateEditorEdgeToEdge<_Insets, Object, Object>(
        enableEdgeToEdgeDarkTransparent: () {},
        installTopInsetsListener: (listener) {},
        installRootInsetsListener: (listener) => rootListener = listener,
        topInsetTypes: () => 'top-mask',
        rootInsetTypes: () => 'root-mask',
        getInsets: (_, __) => _Insets(left: 0, top: 0, right: 0),
        isFragmented: () {
          calls.add('fragmented');
          return false;
        },
        findTopView: () {
          calls.add('top-lookup');
          return Object();
        },
        findEditorView: () {
          calls.add('editor-lookup');
          return Object();
        },
        findFragmentContainerView: () {
          calls.add('container-lookup');
          return Object();
        },
        leftInset: (_) => 0,
        topInset: (_) => 0,
        rightInset: (_) => 0,
        updatePadding: (_, {left, top, right}) => calls.add('padding'),
      );

      final input = _Insets(left: 1, top: 2, right: 3);
      expect(identical(rootListener(input), input), isTrue);
      expect(calls, ['fragmented']);
    });

    test('a failed first listener registration prevents the root listener', () {
      final error = StateError('source callback failed');
      final calls = <String>[];
      expect(
        () => setupCardTemplateEditorEdgeToEdge<_Insets, Object, Object>(
          enableEdgeToEdgeDarkTransparent: () => calls.add('enable'),
          installTopInsetsListener: (_) {
            calls.add('install-top');
            throw error;
          },
          installRootInsetsListener: (_) => calls.add('install-root'),
          topInsetTypes: () => 'top-mask',
          rootInsetTypes: () => 'root-mask',
          getInsets: (_, __) => _Insets(left: 0, top: 0, right: 0),
          isFragmented: () {
            calls.add('fragmented');
            return false;
          },
          findTopView: () => Object(),
          findEditorView: () => Object(),
          findFragmentContainerView: () => Object(),
          leftInset: (_) => 0,
          topInset: (_) => 0,
          rightInset: (_) => 0,
          updatePadding: (_, {left, top, right}) {},
        ),
        throwsA(same(error)),
      );
      expect(calls, ['enable', 'install-top']);
    });

    test('an inset-read failure propagates before later root work', () {
      final error = StateError('insets failed');
      final calls = <String>[];
      late _Insets Function(_Insets) topListener;

      setupCardTemplateEditorEdgeToEdge<_Insets, Object, Object>(
        enableEdgeToEdgeDarkTransparent: () {},
        installTopInsetsListener: (listener) => topListener = listener,
        installRootInsetsListener: (_) {},
        topInsetTypes: () => 'top-mask',
        rootInsetTypes: () => 'root-mask',
        getInsets: (_, __) => throw error,
        isFragmented: () {
          calls.add('fragmented');
          return true;
        },
        findTopView: () {
          calls.add('find-top');
          return Object();
        },
        findEditorView: () => Object(),
        findFragmentContainerView: () => Object(),
        leftInset: (_) => 0,
        topInset: (_) => 0,
        rightInset: (_) => 0,
        updatePadding: (_, {left, top, right}) {},
      );

      expect(
        () => topListener(_Insets(left: 1, top: 2, right: 3)),
        throwsA(same(error)),
      );
      expect(calls, isEmpty);
    });
  });
}

class _Insets {
  const _Insets({required this.left, required this.top, required this.right});

  final int left;
  final int top;
  final int right;
}
