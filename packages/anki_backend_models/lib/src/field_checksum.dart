// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Returns Anki's u32 checksum for already HTML-stripped field text.
///
/// The caller must apply Anki Core's `strip_html_preserving_media_filenames`
/// behavior before passing text here.
int fieldChecksum(String text) {
  final digest = sha1.convert(utf8.encode(text)).bytes;
  return digest.take(4).fold(0, (value, byte) => (value << 8) | byte);
}
