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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Behavioral reference: CardTemplateNotetype.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md. Android and collection integration remain host-side.
 */

/// Whether a template change adds a template or removes one from a notetype.
enum ChangeType { add, delete }

/// A pending template change; its ordinal can shift when earlier changes compact.
final class TemplateChange {
  TemplateChange(this.ordinal, this.type);

  int ordinal;
  final ChangeType type;
}

/// Tracks pending template changes and projects their database ordinals.
///
/// The host owns notetype JSON, template values, persistence, and database
/// operations. This model preserves only the deterministic change history from
/// AnkiDroid's CardTemplateNotetype.
final class CardTemplateNotetype {
  final List<TemplateChange> templateChanges = [];

  /// Routes a newly added template to the pending change history.
  void addNewTemplate(int ordinal) =>
      addTemplateChange(ChangeType.add, ordinal);

  /// Routes a removed template to the pending change history.
  void removeTemplate(int ordinal) =>
      addTemplateChange(ChangeType.delete, ordinal);

  /// Records a change, compacting an unsaved add if it is subsequently deleted.
  void addTemplateChange(ChangeType type, int ordinal) {
    final change = TemplateChange(ordinal, type);

    if (type == ChangeType.delete) {
      var ordinalAdjustment = 0;
      for (var i = templateChanges.length - 1; i >= 0; i--) {
        final oldChange = templateChanges[i];
        switch (oldChange.type) {
          case ChangeType.delete:
            if (oldChange.ordinal - ordinalAdjustment <= ordinal) {
              ordinalAdjustment++;
              continue;
            }
          case ChangeType.add:
            if (ordinal == oldChange.ordinal - ordinalAdjustment) {
              _compactTemplateChanges(oldChange.ordinal);
              return;
            }
        }
      }
    }

    templateChanges.add(change);
  }

  /// Returns database-relative ordinals for pending deletes and [ordinal].
  List<int> getDeleteDbOrds(int ordinal) {
    final deletedDbOrds = <int>[];

    for (var i = 0; i <= templateChanges.length; i++) {
      var ordinalAdjustment = 0;
      var currentChange = TemplateChange(ordinal, ChangeType.delete);
      if (i < templateChanges.length) {
        currentChange = templateChanges[i];
      }

      if (currentChange.type != ChangeType.delete) {
        continue;
      }

      for (var j = 0; j < i; j++) {
        final previousChange = templateChanges[j];
        if (previousChange.type == ChangeType.delete &&
            previousChange.ordinal <= currentChange.ordinal) {
          ordinalAdjustment++;
        }
      }

      deletedDbOrds.add(currentChange.ordinal + ordinalAdjustment);
    }

    return deletedDbOrds;
  }

  /// Changes ready for persistence: adds are adjusted; deletes remain aliased.
  List<TemplateChange> get adjustedTemplateChanges {
    final adjustedChanges = <TemplateChange>[];
    for (var i = 0; i < templateChanges.length; i++) {
      final change = templateChanges[i];
      final adjustedChange = switch (change.type) {
        ChangeType.add => TemplateChange(
          getAdjustedAddOrdinalAtChangeIndex(this, i),
          ChangeType.add,
        ),
        ChangeType.delete => change,
      };
      adjustedChanges.add(adjustedChange);
    }
    return adjustedChanges;
  }

  void _compactTemplateChanges(int addedOrdinalToDelete) {
    var postChange = false;
    var ordinalAdjustment = 0;
    var i = 0;
    while (i < templateChanges.length) {
      final change = templateChanges[i];
      var ordinal = change.ordinal;
      final changeType = change.type;

      if (!postChange) {
        if (ordinal == addedOrdinalToDelete && changeType == ChangeType.add) {
          postChange = true;
          templateChanges.removeAt(i);
          i--;
        }
        i++;
        continue;
      }

      if (changeType == ChangeType.delete) {
        ordinalAdjustment++;
      }

      if (ordinal + ordinalAdjustment > addedOrdinalToDelete) {
        change.ordinal = --ordinal;
      }
      i++;
    }
  }
}

/// Returns the adjusted ordinal for an add at [changesIndex], or `-1` otherwise.
int getAdjustedAddOrdinalAtChangeIndex(
  CardTemplateNotetype noteType,
  int changesIndex,
) {
  if (changesIndex >= noteType.templateChanges.length) {
    return -1;
  }

  var ordinalAdjustment = 0;
  final change = noteType.templateChanges[changesIndex];
  final ordinalToInspect = change.ordinal;
  for (var i = noteType.templateChanges.length - 1; i >= changesIndex; i--) {
    final oldChange = noteType.templateChanges[i];
    final currentOrdinal = change.ordinal;
    switch (oldChange.type) {
      case ChangeType.delete:
        if (currentOrdinal - ordinalAdjustment <= ordinalToInspect) {
          ordinalAdjustment++;
          continue;
        }
      case ChangeType.add:
        if (changesIndex == i) {
          return currentOrdinal - ordinalAdjustment;
        }
    }
  }
  return -1;
}

/// Tests whether [ordinal] is a currently pending add.
bool isOrdinalPendingAdd(CardTemplateNotetype noteType, int ordinal) {
  for (var i = 0; i < noteType.templateChanges.length; i++) {
    final adjustedOrdinal = getAdjustedAddOrdinalAtChangeIndex(noteType, i);
    if (adjustedOrdinal == ordinal) {
      return true;
    }
  }
  return false;
}
