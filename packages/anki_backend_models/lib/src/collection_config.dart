// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:fixnum/fixnum.dart';

import 'card.dart' show InvalidModelValue;

/// Anki Core's persisted scheduler implementation version.
enum SchedulerVersion {
  v1(1),
  v2(2);

  const SchedulerVersion(this.value);
  final int value;

  static SchedulerVersion fromRaw(int raw) => switch (raw) {
        1 => SchedulerVersion.v1,
        2 => SchedulerVersion.v2,
        _ => throw const InvalidModelValue('invalid scheduler version'),
      };
}

/// Raw stored collection config row used by update and undo operations.
class CollectionConfigEntry {
  CollectionConfigEntry({
    required this.key,
    required Iterable<int> value,
    required int usn,
    required this.mtime,
  })  : value = List.unmodifiable(value),
        usn = usn.toSigned(32) {
    if (this.value.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
          value, 'value', 'config bytes must be unsigned');
    }
  }

  final String key;
  final List<int> value;
  final int usn;
  final Int64 mtime;

  @override
  bool operator ==(Object other) =>
      other is CollectionConfigEntry &&
      other.key == key &&
      _sameConfigBytes(other.value, value) &&
      other.usn == usn &&
      other.mtime == mtime;

  @override
  int get hashCode => Object.hash(key, Object.hashAll(value), usn, mtime);
}

bool _sameConfigBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
