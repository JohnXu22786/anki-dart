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
 * Source-derived from TimeUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

const SECONDS_PER_DAY = 86400;

// These are doubles on purpose because a rounded, not integer result is wanted
// later. Values are from Anki Desktop's scheduler.
const TIME_MINUTE = 60.0;
const TIME_HOUR = 60.0 * TIME_MINUTE;
const TIME_DAY = 24.0 * TIME_HOUR;

/// Creates the host date from exactly one host-provided millisecond read.
///
/// The host remains responsible for the concrete date type and its time-zone
/// semantics. The clock is read before date creation, and failures propagate.
TDate currentDate<TTime, TDate>(
  TTime time, {
  required int Function(TTime time) intTimeMS,
  required TDate Function(int milliseconds) createDate,
}) => createDate(intTimeMS(time));

/// Creates a host calendar and sets it to the single date returned by
/// [currentDate].
///
/// The calendar is created before the clock is read. Concrete calendar, date,
/// and time-zone semantics remain host-provided, and callback failures
/// propagate in source order.
TCalendar calendar<TTime, TDate, TCalendar>(
  TTime time, {
  required TCalendar Function() createCalendar,
  required int Function(TTime time) intTimeMS,
  required TDate Function(int milliseconds) createDate,
  required void Function(TCalendar calendar, TDate date) setTime,
}) {
  final cal = createCalendar();
  final date = currentDate(time, intTimeMS: intTimeMS, createDate: createDate);
  setTime(cal, date);
  return cal;
}

/// Returns the host-provided current time in whole seconds.
///
/// The host supplies epoch milliseconds. Its clock is read once, then Dart's
/// integer division preserves the source's signed truncation toward zero.
int intTime<TTime>(TTime time, {required int Function(TTime time) intTimeMS}) =>
    intTimeMS(time) ~/ 1000;

/// Formats [time]'s host-provided current date as `yyyyMMddHHmmss`.
///
/// The host creates a `SimpleDateFormat` with `Locale.US`; its default time
/// zone remains host-provided. The formatter is created before the single date
/// read, then that same date is formatted once.
String getTimestamp<TTime, TDate, TFormatter>(
  TTime time, {
  required TFormatter Function(String pattern, String locale)
  createSimpleDateFormat,
  required TDate Function(TTime time) currentDate,
  required String Function(TFormatter formatter, TDate date) format,
}) {
  final formatter = createSimpleDateFormat('yyyyMMddHHmmss', 'US');
  final date = currentDate(time);
  return format(formatter, date);
}

/// Formats the host-projected Kotlin duration using the source's signed Long
/// division and remainder behavior.
///
/// The host must return Kotlin `Duration.inWholeMilliseconds` and perform the
/// source pattern formatting (`String.format`) in its runtime locale. The
/// conversion and formatter each run once. Negative values and hour wrapping
/// follow the source, including its quirks.
String formatAsString<TDuration>(
  TDuration duration, {
  required int Function(TDuration duration) inWholeMilliseconds,
  required String Function(String pattern, List<int> values) format,
}) {
  final milliseconds = inWholeMilliseconds(duration);
  final ms = _signedRemainder(milliseconds, 1000);
  final s = _signedRemainder(milliseconds ~/ 1000, 60);
  final m = _signedRemainder(milliseconds ~/ (1000 * 60), 60);
  final h = _signedRemainder(milliseconds ~/ (1000 * 60 * 60), 60);
  if (h > 0) {
    return format('%02d:%02d:%02d.%02d', [h, m, s, ms ~/ 10]);
  }
  return format('%02d:%02d.%02d', [m, s, ms ~/ 10]);
}

int _signedRemainder(int dividend, int divisor) =>
    dividend - (dividend ~/ divisor) * divisor;

/// Returns 4 AM at the start of [time]'s day, as defined by its host calendar.
///
/// The calendar, time zone, DST rules, and Gregorian behavior remain
/// host-provided. Each host callback runs in the same order as the Kotlin
/// source and failures stop subsequent operations.
int getDayStart<TTime, TCalendar>(
  TTime time, {
  required TCalendar Function(TTime time) calendar,
  required int Function(TCalendar calendar) getHourOfDay,
  required void Function(TCalendar calendar, int amount) addDayOfYear,
  required void Function(TCalendar calendar, int value) setHourOfDay,
  required void Function(TCalendar calendar, int value) setMinute,
  required void Function(TCalendar calendar, int value) setSecond,
  required void Function(TCalendar calendar, int value) setMillisecond,
  required int Function(TCalendar calendar) getTimeInMillis,
}) {
  final cal = calendar(time);
  if (getHourOfDay(cal) < 4) {
    addDayOfYear(cal, -1);
  }
  setHourOfDay(cal, 4);
  setMinute(cal, 0);
  setSecond(cal, 0);
  setMillisecond(cal, 0);
  return getTimeInMillis(cal);
}
