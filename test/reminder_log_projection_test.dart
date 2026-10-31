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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral references: ReminderLogTreeTest.kt and ByteArrayTest.kt in
 * AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reminder log prefix and header', () {
    test('formats a missing or present reminder ID', () {
      expect(reminderLogPrefix(), '[Reminders]');
      expect(reminderLogPrefix(7), '[Reminders:7]');
    });

    test(
      'accepts only the exact anchored header with optional ID and one space',
      () {
        expect(
          formatReminderLogLine(
            timestamp: '2026-09-05 08:30:00.123',
            priority: reminderLogInfoPriority,
            message: '[Reminders:007]event',
            ellipsize: (text, _) => text,
          ),
          '2026-09-05 08:30:00.123 I #007 event\n',
        );
        expect(
          formatReminderLogLine(
            timestamp: 'time',
            priority: reminderLogInfoPriority,
            message: '[Reminders]  event',
            ellipsize: (text, _) => text,
          ),
          'time I #--  event\n',
        );
        for (final message in [
          'prefix [Reminders] event',
          '[RemindersFoo] event',
          '[reminders] event',
          '[Reminders:-1] event',
          '[Reminders:1x] event',
        ]) {
          expect(
            formatReminderLogLine(
              timestamp: 'time',
              priority: reminderLogInfoPriority,
              message: message,
              ellipsize: (text, _) => text,
            ),
            isNull,
            reason: message,
          );
        }
      },
    );
  });

  group('Reminder log line projection', () {
    test('gates below INFO and maps upstream level characters', () {
      expect(isReminderLoggable(reminderLogInfoPriority - 1), isFalse);
      expect(isReminderLoggable(reminderLogInfoPriority), isTrue);
      expect(isReminderLoggable(reminderLogAssertPriority + 1), isTrue);
      expect(
        [
          reminderLogInfoPriority,
          reminderLogWarnPriority,
          reminderLogErrorPriority,
          reminderLogAssertPriority,
          reminderLogAssertPriority + 1,
        ].map(reminderLogLevelCharacter).join(),
        'IWEEX',
      );
    });

    test(
      'escapes LF, strips the matched header, and receives the host timestamp',
      () {
        expect(
          formatReminderLogLine(
            timestamp: 'host timestamp',
            priority: reminderLogWarnPriority,
            message: '[Reminders] first\nsecond',
            ellipsize: (text, _) => text,
          ),
          'host timestamp W #-- first\\nsecond\n',
        );
      },
    );

    test('passes projected text and source maximum to host ellipsizer', () {
      String? seenText;
      int? seenMaximum;
      final output = formatReminderLogLine(
        timestamp: 'time',
        priority: reminderLogInfoPriority,
        message: '[Reminders] ${'a' * (reminderLogMaxLineLength + 1)}',
        ellipsize: (text, maximum) {
          seenText = text;
          seenMaximum = maximum;
          return 'host-ellipsized';
        },
      );
      expect(seenText, 'a' * (reminderLogMaxLineLength + 1));
      expect(seenMaximum, reminderLogMaxLineLength);
      expect(output, 'time I #-- host-ellipsized\n');
    });
  });

  group('Reminder log byte projection', () {
    test('finds newline at or after a clamped index', () {
      final bytes = 'ab\ncd\n'.codeUnits;
      expect(indexOfNewlineAtOrAfter(bytes, 2), 2);
      expect(indexOfNewlineAtOrAfter(bytes, 3), 5);
      expect(indexOfNewlineAtOrAfter(bytes, -100), 2);
      expect(indexOfNewlineAtOrAfter(bytes, bytes.length), isNull);
      expect(indexOfNewlineAtOrAfter(<int>[], 0), isNull);
      expect(indexOfNewlineAtOrAfter('abcd'.codeUnits, 0), isNull);
    });

    test('does not trim below the trigger', () {
      final bytes = List<int>.filled(reminderLogTrimTriggerBytes - 1, 0x61);
      expect(trimReminderLogBytes(bytes), bytes);
    });

    test(
      'trims at the equal trigger through the newline at or after target offset',
      () {
        final bytes = List<int>.filled(reminderLogTrimTriggerBytes, 0x61);
        final targetOffset = bytes.length - reminderLogTrimTargetBytes;
        bytes[targetOffset] = 0x0a;
        bytes[targetOffset + 4] = 0x0a;
        expect(trimReminderLogBytes(bytes), bytes.sublist(targetOffset + 1));
      },
    );

    test('discards all bytes when triggered input has no newline', () {
      final bytes = List<int>.filled(reminderLogTrimTriggerBytes, 0x61);
      expect(trimReminderLogBytes(bytes), isEmpty);
    });
  });
}
