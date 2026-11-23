// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  test('finds sibling days in every preset', () {
    final days = _daysWithSibling(7, 42);

    expect(
      calculateSiblingModifiers(
        {Int64(1): _emptyDays(), Int64(2): days},
        beforeDays: 2,
        afterDays: 8,
        noteId: Int64(42),
      ),
      calculateSiblingDayModifiers(2, 8, [7]),
    );
  });

  test('applies a day shared by multiple presets only once', () {
    final first = _daysWithSibling(5, 42);
    final second = _daysWithSibling(5, 42);

    expect(
      calculateSiblingModifiers(
        {Int64(1): first, Int64(2): second},
        beforeDays: 0,
        afterDays: 10,
        noteId: Int64(42),
      ),
      calculateSiblingDayModifiers(0, 10, [5]),
    );
  });

  test('a null note ID leaves the interval unmodified', () {
    expect(
      calculateSiblingModifiers(
        {Int64(1): _daysWithSibling(5, 42)},
        beforeDays: 2,
        afterDays: 3,
        noteId: null,
      ),
      [1.0, 1.0],
    );
  });

  test('empty preset maps and missing siblings leave intervals unmodified', () {
    expect(
      calculateSiblingModifiers(
        {},
        beforeDays: 2,
        afterDays: 3,
        noteId: Int64(42),
      ),
      [1.0, 1.0],
    );
    expect(
      calculateSiblingModifiers(
        {Int64(1): _daysWithSibling(5, 11)},
        beforeDays: 2,
        afterDays: 3,
        noteId: Int64(42),
      ),
      [1.0, 1.0],
    );
  });

  test('clips sibling modifiers to the requested interval window', () {
    expect(
      calculateSiblingModifiers(
        {Int64(1): _daysWithSibling(0, 42)},
        beforeDays: 3,
        afterDays: 5,
        noteId: Int64(42),
      ),
      calculateSiblingDayModifiers(3, 5, [0]),
    );
  });

  test('rejects invalid interval windows and malformed preset buckets', () {
    expect(
      () => calculateSiblingModifiers(
        {},
        beforeDays: 0,
        afterDays: 99,
        noteId: Int64(42),
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateSiblingModifiers(
        {Int64(1): _emptyDays()..removeLast()},
        beforeDays: 0,
        afterDays: 1,
        noteId: Int64(42),
      ),
      throwsArgumentError,
    );
  });
}

List<LoadBalancerDay> _emptyDays() =>
    List<LoadBalancerDay>.generate(99, (_) => LoadBalancerDay());

List<LoadBalancerDay> _daysWithSibling(int day, int noteId) {
  final days = _emptyDays();
  days[day].add(Int64(day), Int64(noteId));
  return days;
}
