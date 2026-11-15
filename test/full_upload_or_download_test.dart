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
 * Source-derived from Sync.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FullUploadOrDownload', () {
    test('builds auth, serverUsn, and upload in source order', () {
      final auth = Object();
      final request = Object();
      final result = Object();
      final builder = Object();
      final calls = <String>[];
      final adapter = FullUploadOrDownload<Object, Object, Object, Object>(
        FullUploadOrDownloadCallbacks(
          createRequestBuilder: () {
            calls.add('create');
            return builder;
          },
          setAuth: (value, actualAuth) {
            calls.add('auth');
            expect(value, same(builder));
            expect(actualAuth, same(auth));
          },
          setServerUsn: (value, serverUsn) {
            calls.add('serverUsn');
            expect(value, same(builder));
            expect(serverUsn, 23);
          },
          setUpload: (value, upload) {
            calls.add('upload');
            expect(value, same(builder));
            expect(upload, isTrue);
          },
          buildRequest: (value) {
            calls.add('build');
            expect(value, same(builder));
            return request;
          },
          fullUploadOrDownload: (actualRequest) {
            calls.add('backend');
            expect(actualRequest, same(request));
            return result;
          },
        ),
      );

      expect(
        adapter.call(auth: auth, upload: true, serverUsn: 23),
        same(result),
      );
      expect(calls, [
        'create',
        'auth',
        'serverUsn',
        'upload',
        'build',
        'backend',
      ]);
    });

    test('omits serverUsn assignment when it is null', () {
      final calls = <String>[];
      final adapter = FullUploadOrDownload<Object, Object, Object, Object>(
        FullUploadOrDownloadCallbacks(
          createRequestBuilder: () => Object(),
          setAuth: (_, _) => calls.add('auth'),
          setServerUsn: (_, _) => calls.add('serverUsn'),
          setUpload: (_, _) => calls.add('upload'),
          buildRequest: (_) => Object(),
          fullUploadOrDownload: (_) => Object(),
        ),
      );

      adapter.call(auth: Object(), upload: false);

      expect(calls, ['auth', 'upload']);
    });

    test('invokes backend exactly once and returns its exact result', () {
      var backendCalls = 0;
      final result = Object();
      final adapter = FullUploadOrDownload<Object, Object, Object, Object>(
        FullUploadOrDownloadCallbacks(
          createRequestBuilder: Object.new,
          setAuth: (_, _) {},
          setServerUsn: (_, _) {},
          setUpload: (_, _) {},
          buildRequest: (_) => Object(),
          fullUploadOrDownload: (_) {
            backendCalls++;
            return result;
          },
        ),
      );

      expect(adapter.call(auth: Object(), upload: false), same(result));
      expect(backendCalls, 1);
    });

    test('propagates the exact host callback failure unchanged', () {
      final failure = StateError('host failure');
      final adapter = FullUploadOrDownload<Object, Object, Object, Object>(
        FullUploadOrDownloadCallbacks(
          createRequestBuilder: Object.new,
          setAuth: (_, _) {},
          setServerUsn: (_, _) {},
          setUpload: (_, _) {},
          buildRequest: (_) => Object(),
          fullUploadOrDownload: (_) => throw failure,
        ),
      );

      expect(
        () => adapter.call(auth: Object(), upload: false),
        throwsA(same(failure)),
      );
    });
  });
}
