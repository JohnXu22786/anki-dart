// SPDX-License-Identifier: AGPL-3.0-or-later
import 'html_entities.dart';

final _decimalEntity = RegExp(r'^#[0-9]+$');
final _hexEntity = RegExp(r'^#x[0-9a-fA-F]+$');

/// Decodes only semicolon-terminated entities recognized by htmlescape 0.3.1.
///
/// Anki Core leaves the entire input unchanged if any reference is malformed,
/// unknown, or incomplete, so validation completes before decoded text is
/// returned.
String decodeAnkiHtmlEntities(String text) {
  if (!text.contains('&')) return text;

  final output = StringBuffer();
  var offset = 0;
  while (offset < text.length) {
    final ampersand = text.indexOf('&', offset);
    if (ampersand < 0) {
      output.write(text.substring(offset));
      break;
    }
    output.write(text.substring(offset, ampersand));

    final semicolon = text.indexOf(';', ampersand + 1);
    if (semicolon < 0) return text;
    final entity = text.substring(ampersand + 1, semicolon);
    final codePoint = _decodeEntity(entity);
    if (codePoint == null) return text;
    output.writeCharCode(codePoint);
    offset = semicolon + 1;
  }
  return output.toString().replaceAll('\u00a0', ' ');
}

int? _decodeEntity(String entity) {
  if (_decimalEntity.hasMatch(entity)) {
    return _validCodePoint(int.tryParse(entity.substring(1)));
  }
  if (_hexEntity.hasMatch(entity)) {
    return _validCodePoint(int.tryParse(entity.substring(2), radix: 16));
  }
  return namedHtmlEntities[entity];
}

int? _validCodePoint(int? value) {
  if (value == null || value > 0x10ffff) return null;
  if (value >= 0xd800 && value <= 0xdfff) return null;
  return value;
}
