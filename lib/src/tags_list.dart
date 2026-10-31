/*
 Copyright (c) 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 3 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this program. If not, see <http://www.gnu.org/licenses/>.

 SPDX-FileCopyrightText: 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>
 SPDX-License-Identifier: GPL-3.0-or-later

 Source-derived from TagsList.kt, TagsUtil.kt, and UniqueArrayList.kt in
 AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Decomposes a hierarchical tag, mapping empty components to `blank`.
List<String> getTagParts(String tag) =>
    tag.split('::').map((part) => part.isEmpty ? 'blank' : part).toList();

/// Returns all tag ancestors in root-to-leaf order.
List<String> getTagAncestors(String tag) {
  final parts = getTagParts(tag);
  return [
    for (var index = 0; index < parts.length - 1; index++)
      parts.sublist(0, index + 1).join('::'),
  ];
}

/// Returns the root component, using `blank` for an empty first component.
String getTagRoot(String tag) {
  final root = tag.split('::').first;
  return root.isEmpty ? 'blank' : root;
}

/// Compares hierarchical paths depth-first, ignoring component casing.
int compareTag(String lhs, String rhs) {
  final lhsParts = lhs.split('::');
  final rhsParts = rhs.split('::');
  final sharedLength = lhsParts.length < rhsParts.length
      ? lhsParts.length
      : rhsParts.length;
  for (var index = 0; index < sharedLength; index++) {
    final comparison = _compareCaseInsensitive(
      lhsParts[index],
      rhsParts[index],
    );
    if (comparison != 0) {
      return comparison;
    }
  }
  return lhsParts.length.compareTo(rhsParts.length);
}

int _foldCaseCodeUnit(int codeUnit) {
  final character = String.fromCharCode(codeUnit);
  final uppercase = character.toUpperCase();
  // Java's Character mapping is one code unit at a time; avoid accepting
  // Dart's multi-character uppercase expansions as new equivalences.
  if (uppercase.codeUnits.length != 1) {
    return codeUnit;
  }
  return uppercase.toLowerCase().codeUnits.first;
}

int _compareCaseInsensitive(String lhs, String rhs) {
  final sharedLength = lhs.length < rhs.length ? lhs.length : rhs.length;
  for (var index = 0; index < sharedLength; index++) {
    final comparison = _foldCaseCodeUnit(
      lhs.codeUnitAt(index),
    ).compareTo(_foldCaseCodeUnit(rhs.codeUnitAt(index)));
    if (comparison != 0) {
      return comparison;
    }
  }
  return lhs.length.compareTo(rhs.length);
}

bool _startsWithCaseInsensitive(String value, String prefix) =>
    value.length >= prefix.length &&
    _compareCaseInsensitive(value.substring(0, prefix.length), prefix) == 0;

/// An ordered, case-insensitive selection model for tags and their hierarchy.
///
/// The first spelling of a tag is retained in [allTags], while its selection
/// sets use case-insensitive identity and ordering like the source TreeSets.
final class TagsList extends Iterable<String> {
  TagsList(
    Iterable<String> allTags,
    Iterable<String> checkedTags, [
    Iterable<String>? uncheckedTags,
  ]) {
    for (final tag in checkedTags) {
      _addToSet(_checkedTags, tag);
    }
    for (final tag in allTags) {
      _addAll(tag);
    }
    for (final tag in _checkedTags) {
      _addAll(tag);
    }

    if (uncheckedTags != null) {
      final uncheckedSet = <String>[];
      for (final tag in uncheckedTags) {
        _addAll(tag);
        _addToSet(uncheckedSet, tag);
      }
      for (final tag in _checkedTags) {
        if (_contains(uncheckedSet, tag)) {
          _addToSet(_indeterminateTags, tag);
        }
      }
      for (final tag in _indeterminateTags) {
        _removeFromSet(_checkedTags, tag);
      }
    }
    for (final tag in _indeterminateTags) {
      _addToSet(_partiallySelectedTags, tag);
    }
    _prepareTagHierarchy();
  }

  final List<String> _allTags = [];
  final List<String> _checkedTags = [];
  final List<String> _indeterminateTags = [];
  final List<String> _partiallySelectedTags = [];

  bool _addToSet(List<String> values, String value) {
    if (_contains(values, value)) {
      return false;
    }
    values.add(value);
    values.sort(_compareCaseInsensitive);
    return true;
  }

  bool _removeFromSet(List<String> values, String value) {
    final index = values.indexWhere(
      (existing) => _compareCaseInsensitive(existing, value) == 0,
    );
    if (index < 0) {
      return false;
    }
    values.removeAt(index);
    return true;
  }

  bool _contains(Iterable<String> values, String value) =>
      values.any((existing) => _compareCaseInsensitive(existing, value) == 0);

  bool _addAllToSet(List<String> values, Iterable<String> additions) {
    var changed = false;
    for (final value in additions) {
      changed = _addToSet(values, value) || changed;
    }
    return changed;
  }

  bool _addAll(String tag) {
    if (_contains(_allTags, tag)) {
      return false;
    }
    _allTags.add(tag);
    return true;
  }

  /// Whether [tag] is partially selected on its own, excluding display-only
  /// indeterminate ancestors.
  bool isPartiallySelected(String tag) =>
      _contains(_partiallySelectedTags, tag);

  /// Whether a selected or partially selected descendant exists below [tag].
  bool hasSelectedDescendants(String tag) {
    final prefix = '$tag::';
    for (final candidates in [_checkedTags, _partiallySelectedTags]) {
      final matches =
          candidates
              .where(
                (candidate) => _compareCaseInsensitive(candidate, prefix) >= 0,
              )
              .toList()
            ..sort(_compareCaseInsensitive);
      if (matches.isNotEmpty &&
          _startsWithCaseInsensitive(matches.first, prefix)) {
        return true;
      }
    }
    return false;
  }

  /// Adds [tag] and its missing ancestors, returning whether [tag] was new.
  bool add(String tag) {
    if (!_addAll(tag)) {
      return false;
    }
    for (final ancestor in getTagAncestors(tag)) {
      _addAll(ancestor);
    }
    return true;
  }

  /// Marks an existing tag checked and, by default, propagates indeterminate
  /// state to unchecked ancestors.
  bool check(String tag, {bool processAncestors = true}) {
    if (!_contains(_allTags, tag)) {
      return false;
    }
    _removeFromSet(_indeterminateTags, tag);
    _removeFromSet(_partiallySelectedTags, tag);
    if (!_addToSet(_checkedTags, tag)) {
      return false;
    }
    if (processAncestors) {
      _markAncestorsIndeterminate(tag);
    }
    return true;
  }

  /// Marks [tag] unchecked, returning whether it had a selected state.
  bool uncheck(String tag) {
    _removeFromSet(_partiallySelectedTags, tag);
    return _removeFromSet(_indeterminateTags, tag) ||
        _removeFromSet(_checkedTags, tag);
  }

  /// Marks an existing tag indeterminate and removes its checked state.
  bool setIndeterminate(String tag) {
    if (!_contains(_allTags, tag)) {
      return false;
    }
    _removeFromSet(_checkedTags, tag);
    return _addToSet(_indeterminateTags, tag);
  }

  /// Checks all tags unless all are checked, in which case it unchecks all.
  bool toggleAllCheckedStatuses() {
    _indeterminateTags.clear();
    _partiallySelectedTags.clear();
    if (_allTags.length == _checkedTags.length) {
      _checkedTags.clear();
      return true;
    }
    return _addAllToSet(_checkedTags, _allTags);
  }

  /// Number of tags in the list.
  int size() => _allTags.length;

  /// Tag at [index], throwing [RangeError] when out of range.
  String operator [](int index) => _allTags[index];

  /// Whether this list contains no tags.
  bool get isEmpty => _allTags.isEmpty;

  /// A copy of the checked tags in case-insensitive sort order.
  List<String> copyOfCheckedTagList() => List.of(_checkedTags);

  /// A copy of the indeterminate tags in case-insensitive sort order.
  List<String> copyOfIndeterminateTagList() => List.of(_indeterminateTags);

  /// A copy of tags initially selected on some notes.
  List<String> copyOfPartiallySelectedTagList() =>
      List.of(_partiallySelectedTags);

  /// A copy of all tags in their insertion order.
  List<String> copyOfAllTagList() => List.of(_allTags);

  /// Whether a tag is checked, by index or case-insensitive name.
  bool isChecked(Object tagOrIndex) => switch (tagOrIndex) {
    int index => isCheckedAt(index),
    String tag => _contains(_checkedTags, tag),
    _ => throw ArgumentError.value(tagOrIndex, 'tagOrIndex'),
  };

  /// Returns whether the tag at [index] is checked.
  bool isCheckedAt(int index) => isChecked(_allTags[index]);

  /// Whether a tag is indeterminate, by index or case-insensitive name.
  bool isIndeterminate(Object tagOrIndex) => switch (tagOrIndex) {
    int index => isIndeterminateAt(index),
    String tag => _contains(_indeterminateTags, tag),
    _ => throw ArgumentError.value(tagOrIndex, 'tagOrIndex'),
  };

  /// Returns whether the tag at [index] is indeterminate.
  bool isIndeterminateAt(int index) => isIndeterminate(_allTags[index]);

  /// Sorts all tags by selected root priority, then hierarchy path order.
  void sort() {
    _allTags.sort((lhs, rhs) {
      final lhsRoot = getTagRoot(lhs);
      final rhsRoot = getTagRoot(rhs);
      final lhsSelected = isChecked(lhsRoot) || isIndeterminate(lhsRoot);
      final rhsSelected = isChecked(rhsRoot) || isIndeterminate(rhsRoot);
      if (lhsSelected != rhsSelected) {
        return lhsSelected ? -1 : 1;
      }
      return compareTag(lhs, rhs);
    });
  }

  void _prepareTagHierarchy() {
    for (final tag in List.of(_allTags)) {
      for (final ancestor in getTagAncestors(tag)) {
        _addAll(ancestor);
      }
    }
    for (final tag in [..._checkedTags, ..._indeterminateTags]) {
      _markAncestorsIndeterminate(tag);
    }
  }

  void _markAncestorsIndeterminate(String tag) {
    if (!_contains(_allTags, tag)) {
      return;
    }
    for (final ancestor in getTagAncestors(tag)) {
      if (!isChecked(ancestor)) {
        setIndeterminate(ancestor);
      }
    }
  }

  @override
  Iterator<String> get iterator => _allTags.iterator;
}
