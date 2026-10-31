/*
 Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 3 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this program. If not, see <http://www.gnu.org/licenses/>.

 SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 SPDX-License-Identifier: GPL-3.0-or-later

 Source-derived from TagsDialogViewModel.kt in AnkiDroid 2.25.3;
 see ANKIDROID_UPSTREAM.md.
 */

import 'dart:collection';

import 'tags_list.dart';

/// One progress value emitted by the source during initialization.
final class TagsDialogInitProgress {
  const TagsDialogInitProgress.processing()
    : kind = TagsDialogInitProgressKind.processing,
      noteNumber = null,
      noteCount = null;

  const TagsDialogInitProgress.fetchingNoteTags(this.noteNumber, this.noteCount)
    : kind = TagsDialogInitProgressKind.fetchingNoteTags;

  const TagsDialogInitProgress.finished()
    : kind = TagsDialogInitProgressKind.finished,
      noteNumber = null,
      noteCount = null;

  final TagsDialogInitProgressKind kind;
  final int? noteNumber;
  final int? noteCount;

  @override
  bool operator ==(Object other) =>
      other is TagsDialogInitProgress &&
      kind == other.kind &&
      noteNumber == other.noteNumber &&
      noteCount == other.noteCount;

  @override
  int get hashCode => Object.hash(kind, noteNumber, noteCount);
}

enum TagsDialogInitProgressKind { processing, fetchingNoteTags, finished }

/// The projected tags and progress values; the host owns asynchronous fetching
/// and publication.
final class TagsDialogInitializationProjection {
  TagsDialogInitializationProjection({
    required this.tags,
    required Iterable<TagsDialogInitProgress> progress,
  }) : progress = List.unmodifiable(progress);

  final TagsList tags;
  final List<TagsDialogInitProgress> progress;
}

/// Projects TagsDialogViewModel's tag construction from host-supplied inputs.
///
/// [selectedNoteTags] must be supplied in the same order as the selected note
/// IDs, including repeated positions when a note ID is repeated. Each inner
/// collection is that note's host-fetched tags. Collection membership and the
/// source's tag partitions use exact string equality; [TagsList] applies its
/// own case-insensitive identity when constructing selection states.
TagsDialogInitializationProjection projectTagsDialogInitialization({
  required Iterable<String> collectionTags,
  required Iterable<Iterable<String>> selectedNoteTags,
  Iterable<String> checkedTags = const [],
  bool isCustomStudying = false,
}) {
  final allTags = List<String>.of(collectionTags);
  final noteTagsList = selectedNoteTags.map(Set<String>.of).toList();
  final checkedTagsSet = LinkedHashSet<String>();
  final uncheckedTagsSet = LinkedHashSet<String>();
  final progress = <TagsDialogInitProgress>[
    const TagsDialogInitProgress.processing(),
  ];

  for (var index = 0; index < noteTagsList.length; index++) {
    final noteTags = noteTagsList[index];
    for (final tag in allTags) {
      if (noteTags.contains(tag)) {
        checkedTagsSet.add(tag);
      } else {
        uncheckedTagsSet.add(tag);
      }
    }
    progress.add(
      TagsDialogInitProgress.fetchingNoteTags(index + 1, noteTagsList.length),
    );
  }

  final extraCheckedTags = LinkedHashSet<String>.of(checkedTags);
  checkedTagsSet.addAll(extraCheckedTags);
  uncheckedTagsSet.removeAll(extraCheckedTags);
  progress.add(const TagsDialogInitProgress.processing());

  final tags = isCustomStudying
      ? TagsList(checkedTagsSet, const [], checkedTagsSet)
      : TagsList(allTags, checkedTagsSet, uncheckedTagsSet);
  progress.add(const TagsDialogInitProgress.finished());
  return TagsDialogInitializationProjection(tags: tags, progress: progress);
}
