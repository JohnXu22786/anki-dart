// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Removes invalid ASCII controls and optionally NFC-normalizes note field text.
///
/// Line feed and horizontal tab are preserved, matching Anki Core's field
/// cleanup before note persistence.
String normalizeNoteField(String value, {required bool normalizeText}) {
  final withoutControls = String.fromCharCodes(value.runes.where(
      (rune) => (rune > 0x1f && rune != 0x7f) || rune == 0x0a || rune == 0x09));
  return normalizeText ? unorm.nfc(withoutControls) : withoutControls;
}
