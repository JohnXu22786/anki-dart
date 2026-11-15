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
/// semantics. Millisecond callbacks use [BigInt] to retain the full JVM Long
/// range on JavaScript. The clock is read before date creation; failures
/// propagate.
TDate currentDate<TTime, TDate>(
  TTime time, {
  required BigInt Function(TTime time) intTimeMS,
  required TDate Function(BigInt milliseconds) createDate,
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
  required BigInt Function(TTime time) intTimeMS,
  required TDate Function(BigInt milliseconds) createDate,
  required void Function(TCalendar calendar, TDate date) setTime,
}) {
  final cal = createCalendar();
  final date = currentDate(time, intTimeMS: intTimeMS, createDate: createDate);
  setTime(cal, date);
  return cal;
}

/// Creates a host Gregorian calendar and assigns [timeInMS] to it.
///
/// Calendar creation precedes the single millisecond assignment, and the same
/// calendar is returned. JVM Gregorian calendar and default time-zone behavior
/// remain host-provided; the timestamp crosses the API as [BigInt] so the JVM
/// Long value stays exact on JavaScript. Callback failures propagate unchanged.
TCalendar gregorianCalendar<TCalendar>(
  BigInt timeInMS, {
  required TCalendar Function() createGregorianCalendar,
  required void Function(TCalendar calendar, BigInt milliseconds)
  setTimeInMillis,
}) {
  final calendar = createGregorianCalendar();
  setTimeInMillis(calendar, timeInMS);
  return calendar;
}

/// Returns AnkiDroid's UTC offset in seconds as a [double].
///
/// The host creates one default calendar and reads its zone and DST offsets in
/// source order. Signed Int32 wrapping and truncating division match Kotlin/JVM;
/// calendar, time-zone, and DST behavior remain host-provided.
double utcOffset<TCalendar>({
  required TCalendar Function() createCalendar,
  required int Function(TCalendar calendar) getZoneOffset,
  required int Function(TCalendar calendar) getDstOffset,
}) {
  final cal = createCalendar();
  final zoneOffset = getZoneOffset(cal);
  final dstOffset = getDstOffset(cal);
  final offsetSeconds = _wrapSignedInt32(zoneOffset + dstOffset) ~/ 1000;
  return _wrapSignedInt32(14_400 - offsetSeconds).toDouble();
}

int _wrapSignedInt32(int value) =>
    ((value + 0x80000000) % 0x100000000) - 0x80000000;

/// Returns AnkiDroid's effective SQL date for [utcOffset] seconds.
///
/// Host callbacks provide the JVM formatter, time zone, Gregorian calendar,
/// Date, and `java.sql.Date.valueOf` behavior. The source reads the clock once,
/// converts the offset with Kotlin/JVM `Double.toLong()` semantics, and uses
/// wrapping signed 64-bit arithmetic before assigning the calendar time. All
/// Long-valued callbacks use [BigInt].
TSqlDate genToday<TTime, TFormatter, TTimeZone, TCalendar, TDate, TSqlDate>(
  TTime time,
  double utcOffset, {
  required TFormatter Function(String pattern, String locale)
  createSimpleDateFormat,
  required TTimeZone Function(String id) getTimeZone,
  required void Function(TFormatter formatter, TTimeZone timeZone) setTimeZone,
  required BigInt Function(TTime time) intTimeMS,
  required TCalendar Function() createGregorianCalendar,
  required void Function(TCalendar calendar, BigInt milliseconds)
  setTimeInMillis,
  required TDate Function(TCalendar calendar) getTime,
  required String Function(TFormatter formatter, TDate date) format,
  required TSqlDate Function(String value) sqlDateValueOf,
}) {
  final formatter = createSimpleDateFormat('yyyy-MM-dd', 'US');
  final timeZone = getTimeZone('GMT');
  setTimeZone(formatter, timeZone);
  final currentTimeMS = intTimeMS(time);
  final offsetMS = _wrapSignedInt64(
    _kotlinDoubleToLong(utcOffset) * BigInt.from(1000),
  );
  final calendarTimeMS = _wrapSignedInt64(currentTimeMS - offsetMS);
  final calendar = createGregorianCalendar();
  setTimeInMillis(calendar, calendarTimeMS);
  final date = getTime(calendar);
  final formattedDate = format(formatter, date);
  return sqlDateValueOf(formattedDate);
}

final _longMin = BigInt.parse('-9223372036854775808');
final _longMax = BigInt.parse('9223372036854775807');
const _longMinAsDouble = -9223372036854775808.0;
const _longMaxExclusiveAsDouble = 9223372036854775808.0;

BigInt _kotlinDoubleToLong(double value) {
  if (value.isNaN) return BigInt.zero;
  if (value <= _longMinAsDouble) return _longMin;
  if (value >= _longMaxExclusiveAsDouble) return _longMax;
  return BigInt.from(value);
}

BigInt _wrapSignedInt64(BigInt value) {
  final modulus = BigInt.one << 64;
  final unsigned = value % modulus;
  final signed = unsigned >= (BigInt.one << 63) ? unsigned - modulus : unsigned;
  return signed;
}

/// A test clock backed by an exact signed Long value.
///
/// Values and arithmetic follow the source's signed JVM `Long` wraparound;
/// the initial time, return value, and Long additions use [BigInt]. [step] is
/// first narrowed to the source's signed 32-bit `Int`. The host
/// supplies the time zone and Gregorian calendar used by [timeStamp], so JVM
/// calendar normalization, defaults, and failures remain host-side.
final class MockTime<TTimeZone, TCalendar> {
  MockTime(BigInt initialMilliseconds, {int step = 0})
    : _time = _wrapSignedInt64(initialMilliseconds),
      _step = _wrapSignedInt32(step);

  /// Creates a clock from date components using the source GMT calendar path.
  MockTime.fromComponents({
    required int year,
    required int month,
    required int date,
    required int hourOfDay,
    required int minute,
    required int second,
    int milliseconds = 0,
    int step = 0,
    required TTimeZone Function(String id) getTimeZone,
    required TCalendar Function(
      int year,
      int month,
      int date,
      int hourOfDay,
      int minute,
      int second,
    )
    createGregorianCalendar,
    required void Function(TCalendar calendar, TTimeZone timeZone) setTimeZone,
    required void Function(TCalendar calendar, int milliseconds) setMillisecond,
    required BigInt Function(TCalendar calendar) getTimeInMillis,
  }) : this(
         timeStamp(
           year,
           month,
           date,
           hourOfDay,
           minute,
           second,
           milliseconds: milliseconds,
           getTimeZone: getTimeZone,
           createGregorianCalendar: createGregorianCalendar,
           setTimeZone: setTimeZone,
           setMillisecond: setMillisecond,
           getTimeInMillis: getTimeInMillis,
         ),
         step: step,
       );

  final int _step;
  BigInt _time;

  /// Returns the current milliseconds, then advances by the configured step.
  BigInt intTimeMS() {
    final currentTime = _time;
    _time = _wrapSignedInt64(_time + BigInt.from(_step));
    return currentTime;
  }

  /// Adds [minutes] using the source's nested Long multiplications.
  void addM(BigInt minutes) {
    final seconds = _wrapSignedInt64(minutes * BigInt.from(60));
    final milliseconds = _wrapSignedInt64(seconds * BigInt.from(1000));
    _time = _wrapSignedInt64(_time + milliseconds);
  }

  /// Adds [days] using the source's nested Long multiplications.
  void addD(BigInt days) {
    final hours = _wrapSignedInt64(days * BigInt.from(24));
    final minutes = _wrapSignedInt64(hours * BigInt.from(60));
    final seconds = _wrapSignedInt64(minutes * BigInt.from(60));
    final milliseconds = _wrapSignedInt64(seconds * BigInt.from(1000));
    _time = _wrapSignedInt64(_time + milliseconds);
  }

  /// Returns a timestamp from a host Gregorian calendar set to GMT.
  ///
  /// The time zone is resolved before constructing the calendar. That exact
  /// zone object is assigned before the millisecond field is set and the
  /// calendar time is read. Callback failures propagate and skip later calls.
  static BigInt timeStamp<TTimeZone, TCalendar>(
    int year,
    int month,
    int date,
    int hourOfDay,
    int minute,
    int second, {
    int milliseconds = 0,
    required TTimeZone Function(String id) getTimeZone,
    required TCalendar Function(
      int year,
      int month,
      int date,
      int hourOfDay,
      int minute,
      int second,
    )
    createGregorianCalendar,
    required void Function(TCalendar calendar, TTimeZone timeZone) setTimeZone,
    required void Function(TCalendar calendar, int milliseconds) setMillisecond,
    required BigInt Function(TCalendar calendar) getTimeInMillis,
  }) {
    final timeZone = getTimeZone('GMT');
    final calendar = createGregorianCalendar(
      year,
      month,
      date,
      hourOfDay,
      minute,
      second,
    );
    setTimeZone(calendar, timeZone);
    setMillisecond(calendar, milliseconds);
    return getTimeInMillis(calendar);
  }
}

/// Returns the host-provided current time in whole seconds as an exact [BigInt].
///
/// The host supplies epoch milliseconds as [BigInt]. Its clock is read once,
/// then division preserves the source's signed truncation toward zero.
BigInt intTime<TTime>(
  TTime time, {
  required BigInt Function(TTime time) intTimeMS,
}) => intTimeMS(time) ~/ BigInt.from(1000);

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
/// The host must return Kotlin `Duration.inWholeMilliseconds` as [BigInt] and perform the
/// source pattern formatting (`String.format`) in its runtime locale. The
/// conversion and formatter each run once. Negative values and hour wrapping
/// follow the source, including its quirks.
String formatAsString<TDuration>(
  TDuration duration, {
  required BigInt Function(TDuration duration) inWholeMilliseconds,
  required String Function(String pattern, List<int> values) format,
}) {
  final milliseconds = inWholeMilliseconds(duration);
  final ms = _signedRemainder(milliseconds, BigInt.from(1000)).toInt();
  final s = _signedRemainder(
    milliseconds ~/ BigInt.from(1000),
    BigInt.from(60),
  ).toInt();
  final m = _signedRemainder(
    milliseconds ~/ BigInt.from(1000 * 60),
    BigInt.from(60),
  ).toInt();
  final h = _signedRemainder(
    milliseconds ~/ BigInt.from(1000 * 60 * 60),
    BigInt.from(60),
  ).toInt();
  if (h > 0) {
    return format('%02d:%02d:%02d.%02d', [h, m, s, ms ~/ 10]);
  }
  return format('%02d:%02d.%02d', [m, s, ms ~/ 10]);
}

BigInt _signedRemainder(BigInt dividend, BigInt divisor) =>
    dividend - (dividend ~/ divisor) * divisor;

/// Returns 4 AM at the start of [time]'s day, as defined by its host calendar.
///
/// The calendar, time zone, DST rules, and Gregorian behavior remain
/// host-provided. The returned epoch milliseconds use [BigInt]. Each host
/// callback runs in the same order as the Kotlin source and failures stop
/// subsequent operations.
BigInt getDayStart<TTime, TCalendar>(
  TTime time, {
  required TCalendar Function(TTime time) calendar,
  required int Function(TCalendar calendar) getHourOfDay,
  required void Function(TCalendar calendar, int amount) addDayOfYear,
  required void Function(TCalendar calendar, int value) setHourOfDay,
  required void Function(TCalendar calendar, int value) setMinute,
  required void Function(TCalendar calendar, int value) setSecond,
  required void Function(TCalendar calendar, int value) setMillisecond,
  required BigInt Function(TCalendar calendar) getTimeInMillis,
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
