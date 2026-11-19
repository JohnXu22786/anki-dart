// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/collection.pb.dart' as proto;

/// The result of adding a note through the collection operation boundary.
///
/// [changes] reports the state touched by this operation. It does not expose
/// or create a generic collection undo record.
final class AddNoteResult {
  const AddNoteResult({
    required this.note,
    required this.generatedCardCount,
    required this.changes,
  });

  final Note note;
  final int generatedCardCount;
  final proto.OpChanges changes;
}
