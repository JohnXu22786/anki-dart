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
 * Source-derived from CardTemplateFragment.showOrphanNoteDialog in
 * AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('show orphan note dialog', () {
    test(
      'configures and shows one builder in source order without a result',
      () {
        final events = <String>[];
        final context = _Handle();
        final builder = _Handle();
        final titleResource = _Handle('R.string.orphan_note_title');
        final messageResource = _Handle('R.string.orphan_note_message');
        final okResource = _Handle('android.R.string.ok');
        final callbacks = _callbacks(
          events: events,
          context: context,
          builder: builder,
          titleResource: titleResource,
          messageResource: messageResource,
          okResource: okResource,
        );

        final dynamic invoke =
            ({
              required callbacks,
              required titleResource,
              required messageResource,
              required okResource,
            }) =>
                cardTemplateFragmentShowOrphanNoteDialog<
                  _Handle,
                  _Handle,
                  _Handle,
                  _Handle,
                  _Handle
                >(
                  callbacks: callbacks,
                  titleResource: titleResource,
                  messageResource: messageResource,
                  okResource: okResource,
                );
        final result = Function.apply(invoke, const [], {
          #callbacks: callbacks,
          #titleResource: titleResource,
          #messageResource: messageResource,
          #okResource: okResource,
        });

        expect(result, isNull);
        expect(events, [
          'require-context',
          'create-builder',
          'set-title',
          'set-message',
          'set-positive-button',
          'show',
        ]);
      },
    );

    test('callback failures propagate unchanged and stop later effects', () {
      for (final failedStage in [
        'require-context',
        'create-builder',
        'set-title',
        'set-message',
        'set-positive-button',
        'show',
      ]) {
        final events = <String>[];
        final failure = StateError('$failedStage failed');

        expect(
          () => cardTemplateFragmentShowOrphanNoteDialog(
            callbacks: _callbacks(
              events: events,
              failedStage: failedStage,
              failure: failure,
            ),
            titleResource: _Handle('R.string.orphan_note_title'),
            messageResource: _Handle('R.string.orphan_note_message'),
            okResource: _Handle('android.R.string.ok'),
          ),
          throwsA(same(failure)),
          reason: failedStage,
        );
        expect(events, [
          'require-context',
          if (failedStage != 'require-context') 'create-builder',
          if (failedStage == 'set-title' ||
              failedStage == 'set-message' ||
              failedStage == 'set-positive-button' ||
              failedStage == 'show') ...[
            'set-title',
          ],
          if (failedStage == 'set-message' ||
              failedStage == 'set-positive-button' ||
              failedStage == 'show') ...[
            'set-message',
          ],
          if (failedStage == 'set-positive-button' || failedStage == 'show')
            'set-positive-button',
          if (failedStage == 'show') 'show',
        ], reason: failedStage);
      }
    });
  });
}

CardTemplateFragmentShowOrphanNoteDialogCallbacks<
  _Handle,
  _Handle,
  _Handle,
  _Handle,
  _Handle
>
_callbacks({
  required List<String> events,
  _Handle? context,
  _Handle? builder,
  _Handle? titleResource,
  _Handle? messageResource,
  _Handle? okResource,
  String? failedStage,
  StateError? failure,
}) => CardTemplateFragmentShowOrphanNoteDialogCallbacks(
  requireContext: () {
    events.add('require-context');
    if (failedStage == 'require-context') throw failure!;
    return context ?? _Handle();
  },
  createBuilder: (actualContext) {
    events.add('create-builder');
    if (context != null) expect(actualContext, same(context));
    if (failedStage == 'create-builder') throw failure!;
    return builder ?? _Handle();
  },
  setTitle: (actualBuilder, actualResource) {
    events.add('set-title');
    if (builder != null) expect(actualBuilder, same(builder));
    expect(actualResource.label, 'R.string.orphan_note_title');
    if (titleResource != null) expect(actualResource, same(titleResource));
    if (failedStage == 'set-title') throw failure!;
  },
  setMessage: (actualBuilder, actualResource) {
    events.add('set-message');
    if (builder != null) expect(actualBuilder, same(builder));
    expect(actualResource.label, 'R.string.orphan_note_message');
    if (messageResource != null) expect(actualResource, same(messageResource));
    if (failedStage == 'set-message') throw failure!;
  },
  setPositiveButton: (actualBuilder, actualResource, listener) {
    events.add('set-positive-button');
    if (builder != null) expect(actualBuilder, same(builder));
    expect(actualResource.label, 'android.R.string.ok');
    if (okResource != null) expect(actualResource, same(okResource));
    expect(listener, isNull);
    if (failedStage == 'set-positive-button') throw failure!;
  },
  show: (actualBuilder) {
    events.add('show');
    if (builder != null) expect(actualBuilder, same(builder));
    if (failedStage == 'show') throw failure!;
  },
);

final class _Handle {
  _Handle([this.label]);

  final String? label;
}
