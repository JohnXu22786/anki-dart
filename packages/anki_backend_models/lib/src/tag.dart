// SPDX-License-Identifier: AGPL-3.0-or-later

/// A collection tag's persisted sync and hierarchy display state.
class Tag {
  Tag({required this.name, int usn = 0, this.expanded = false})
      : usn = usn.toSigned(32);

  final String name;
  final int usn;
  final bool expanded;

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      other.name == name &&
      other.usn == usn &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(name, usn, expanded);
}
