// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:sqlite3/common.dart';

/// Registers the Unicode 12.1 case-insensitive collation used by Anki Core.
void registerUnicaseCollation(CommonDatabase database) {
  database.createCollation(name: 'unicase', function: compareUniCase);
}

/// Compares strings after the pinned `unicase` 2.6.0 Unicode simple fold.
int compareUniCase(String? left, String? right) {
  final foldedLeft = unicodeCaseFold(left ?? '');
  final foldedRight = unicodeCaseFold(right ?? '');
  final leftRunes = foldedLeft.runes.iterator;
  final rightRunes = foldedRight.runes.iterator;
  while (true) {
    final hasLeft = leftRunes.moveNext();
    final hasRight = rightRunes.moveNext();
    if (!hasLeft || !hasRight) {
      if (hasLeft) return 1;
      if (hasRight) return -1;
      return 0;
    }
    final comparison = leftRunes.current.compareTo(rightRunes.current);
    if (comparison != 0) return comparison;
  }
}
