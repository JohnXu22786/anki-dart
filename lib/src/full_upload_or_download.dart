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
 * SPDX-FileCopyrightText: 2022 Ankitects Pty Ltd
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Sync.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Host operations needed to preserve `Collection.fullUploadOrDownload`.
///
/// The host owns protobuf auth/request/response values and backend transport.
/// This adapter only sequences the request builder assignments and backend call.
final class FullUploadOrDownloadCallbacks<TAuth, TBuilder, TRequest, TResult> {
  const FullUploadOrDownloadCallbacks({
    required this.createRequestBuilder,
    required this.setAuth,
    required this.setServerUsn,
    required this.setUpload,
    required this.buildRequest,
    required this.fullUploadOrDownload,
  });

  final TBuilder Function() createRequestBuilder;
  final void Function(TBuilder builder, TAuth auth) setAuth;
  final void Function(TBuilder builder, int serverUsn) setServerUsn;
  final void Function(TBuilder builder, bool upload) setUpload;
  final TRequest Function(TBuilder builder) buildRequest;
  final TResult Function(TRequest request) fullUploadOrDownload;
}

/// Portable wrapper for the source `Collection.fullUploadOrDownload` method.
///
/// Auth is assigned first, a non-null server USN second, and upload last.
/// The host backend is called once with the built request; its result and any
/// callback exceptions pass through unchanged.
final class FullUploadOrDownload<TAuth, TBuilder, TRequest, TResult> {
  const FullUploadOrDownload(this.callbacks);

  final FullUploadOrDownloadCallbacks<TAuth, TBuilder, TRequest, TResult>
  callbacks;

  TResult call({required TAuth auth, required bool upload, int? serverUsn}) {
    final builder = callbacks.createRequestBuilder();
    callbacks.setAuth(builder, auth);
    if (serverUsn != null) {
      callbacks.setServerUsn(builder, serverUsn);
    }
    callbacks.setUpload(builder, upload);
    final request = callbacks.buildRequest(builder);
    return callbacks.fullUploadOrDownload(request);
  }
}
