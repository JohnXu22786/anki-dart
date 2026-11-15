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
 * Source-derived from Exceptions.kt in AnkiDroid 2.25.3; see
 * ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('contextGetUserFriendlyErrorText', () {
    test('returns a translatable message directly, even when blank', () {
      final events = <String>[];
      final error = Object();

      final result = contextGetUserFriendlyErrorText(
        error: error,
        isTranslatableException: (value) {
          events.add('isTranslatable:${identical(value, error)}');
          return true;
        },
        getTranslatedMessage: (value) {
          events.add('translated:${identical(value, error)}');
          return '  ';
        },
        getLocalizedMessage: (_) => fail('unexpected localizedMessage read'),
        getMessage: (_) => fail('unexpected message read'),
        getExceptionSimpleName: (_) => fail('unexpected class name read'),
        isBlank: (_) => fail('translated messages are returned directly'),
        getUnknownErrorText: () => fail('unexpected resource read'),
      );

      expect(result, '  ');
      expect(events, ['isTranslatable:true', 'translated:true']);
    });

    test('returns nonblank localizedMessage before later fallbacks', () {
      final events = <String>[];
      final error = Object();

      final result = _resolve(
        error,
        events,
        localizedMessage: 'localized',
        message: 'message',
        simpleName: 'Error',
      );

      expect(result, 'localized');
      expect(events, [
        'isTranslatable',
        'localizedMessage',
        'isBlank:localized',
      ]);
    });

    test('uses nonblank message after a null or blank localizedMessage', () {
      for (final localized in <String?>[null, ' \t']) {
        final events = <String>[];
        final result = _resolve(
          Object(),
          events,
          localizedMessage: localized,
          message: 'message',
          simpleName: 'Error',
        );

        expect(result, 'message');
        expect(events, [
          'isTranslatable',
          'localizedMessage',
          if (localized != null) 'isBlank:$localized',
          'message',
          'isBlank:message',
        ]);
      }
    });

    test('uses nonblank exception simpleName after blank messages', () {
      final events = <String>[];
      final result = _resolve(
        Object(),
        events,
        localizedMessage: ' ',
        message: '\n',
        simpleName: 'IllegalStateException',
      );

      expect(result, 'IllegalStateException');
      expect(events, [
        'isTranslatable',
        'localizedMessage',
        'isBlank: ',
        'message',
        'isBlank:\n',
        'simpleName',
        'isBlank:IllegalStateException',
      ]);
    });

    test('uses localized unknown-error text after blank candidates', () {
      final events = <String>[];
      final result = _resolve(
        Object(),
        events,
        localizedMessage: ' ',
        message: '\t',
        simpleName: '\n',
      );

      expect(result, 'host localized unknown');
      expect(events, [
        'isTranslatable',
        'localizedMessage',
        'isBlank: ',
        'message',
        'isBlank:\t',
        'simpleName',
        'isBlank:\n',
        'unknownErrorText',
      ]);
    });

    test(
      'evaluates each source property and callback once in source order',
      () {
        final events = <String>[];
        var classifierCalls = 0;
        var localizedCalls = 0;
        var messageCalls = 0;
        var simpleNameCalls = 0;

        final result = contextGetUserFriendlyErrorText(
          error: Object(),
          isTranslatableException: (_) {
            classifierCalls++;
            events.add('isTranslatable');
            return false;
          },
          getTranslatedMessage: (_) => fail('unexpected translation'),
          getLocalizedMessage: (_) {
            localizedCalls++;
            events.add('localizedMessage');
            return null;
          },
          getMessage: (_) {
            messageCalls++;
            events.add('message');
            return 'message';
          },
          getExceptionSimpleName: (_) {
            simpleNameCalls++;
            events.add('simpleName');
            return 'Error';
          },
          isBlank: (text) {
            events.add('isBlank:$text');
            return false;
          },
          getUnknownErrorText: () => fail('unexpected resource read'),
        );

        expect(result, 'message');
        expect(classifierCalls, 1);
        expect(localizedCalls, 1);
        expect(messageCalls, 1);
        expect(simpleNameCalls, 0);
        expect(events, [
          'isTranslatable',
          'localizedMessage',
          'message',
          'isBlank:message',
        ]);
      },
    );

    test(
      'propagates callback failures unchanged and stops later operations',
      () {
        final failure = StateError('host callback failed');
        final error = Object();
        final events = <String>[];

        expect(
          () => contextGetUserFriendlyErrorText(
            error: error,
            isTranslatableException: (_) {
              events.add('isTranslatable');
              return false;
            },
            getTranslatedMessage: (_) => fail('unexpected translation'),
            getLocalizedMessage: (_) {
              events.add('localizedMessage');
              throw failure;
            },
            getMessage: (_) => fail('message read after failed getter'),
            getExceptionSimpleName: (_) =>
                fail('class read after failed getter'),
            isBlank: (_) => fail('blank check after failed getter'),
            getUnknownErrorText: () =>
                fail('resource read after failed getter'),
          ),
          throwsA(same(failure)),
        );
        expect(events, ['isTranslatable', 'localizedMessage']);

        expect(
          () => contextGetUserFriendlyErrorText(
            error: error,
            isTranslatableException: (_) => false,
            getTranslatedMessage: (_) => fail('unexpected translation'),
            getLocalizedMessage: (_) => 'localized',
            getMessage: (_) => fail('message after failed blank check'),
            getExceptionSimpleName: (_) =>
                fail('class after failed blank check'),
            isBlank: (_) => throw failure,
            getUnknownErrorText: () =>
                fail('resource after failed blank check'),
          ),
          throwsA(same(failure)),
        );
      },
    );
  });
}

String _resolve(
  Object error,
  List<String> events, {
  required String? localizedMessage,
  required String? message,
  required String? simpleName,
}) => contextGetUserFriendlyErrorText(
  error: error,
  isTranslatableException: (_) {
    events.add('isTranslatable');
    return false;
  },
  getTranslatedMessage: (_) => fail('unexpected translation'),
  getLocalizedMessage: (_) {
    events.add('localizedMessage');
    return localizedMessage;
  },
  getMessage: (_) {
    events.add('message');
    return message;
  },
  getExceptionSimpleName: (_) {
    events.add('simpleName');
    return simpleName;
  },
  isBlank: (text) {
    events.add('isBlank:$text');
    return text.trim().isEmpty;
  },
  getUnknownErrorText: () {
    events.add('unknownErrorText');
    return 'host localized unknown';
  },
);
