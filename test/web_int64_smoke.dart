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
 */

import 'package:anki_dart/anki_dart.dart';

void main() {
  final longMax = BigInt.parse('9223372036854775807');
  final longMin = BigInt.parse('-9223372036854775808');
  final beyondJsSafeInteger = BigInt.parse('9007199254740993');

  _expect(wholeAndFraction(double.infinity).whole, longMax);
  _expect(wholeAndFraction(double.negativeInfinity).whole, longMin);
  _expect(wholeAndFraction(9.223372036854776e18 + 2048.0).fraction, 2048.0);
  _expect(libankiNoteHashCode(BigInt.parse('9223372032559808513')), 0x7ffffffe);

  final clock = MockTime(longMax);
  _expect(clock.intTimeMS(), longMax);
  clock.addM(BigInt.one);
  _expect(clock.intTimeMS(), BigInt.parse('-9223372036854715809'));
  _expect(
    intTime(Object(), intTimeMS: (_) => beyondJsSafeInteger),
    BigInt.from(9007199254740),
  );

  var assigned = BigInt.zero;
  genToday(
    Object(),
    0,
    createSimpleDateFormat: (_, _) => Object(),
    getTimeZone: (_) => Object(),
    setTimeZone: (_, _) {},
    intTimeMS: (_) => longMax,
    createGregorianCalendar: Object.new,
    setTimeInMillis: (_, value) => assigned = value,
    getTime: (_) => Object(),
    format: (_, _) => '9999-12-31',
    sqlDateValueOf: (_) => Object(),
  );
  _expect(assigned, longMax);

  const serialized =
      '{"7":{"id":7,"time":{"hour":1,"minute":2},'
      '"cardTriggerThreshold":0,"scope":{"type":"com.ichi2.anki.'
      'reviewreminders.ReviewReminderScope.DeckSpecific",'
      '"did":9223372036854775807},"enabled":true,'
      '"latestNotifTime":9007199254740993,"profileID":"",'
      '"onlyNotifyIfNoReviews":false}}';
  final reminder = ReviewReminderGroup.fromJsonString(serialized);
  _expect(reminder[ReviewReminderId(7)]!.latestNotifTime, beyondJsSafeInteger);
  _expect(reminder.serializeToString(), serialized);
}

void _expect(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected $expected, got $actual');
  }
}
