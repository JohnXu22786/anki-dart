// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:html/parser.dart' show parseFragment;

final _htmlTags = RegExp(
  r'<!--.*?-->|<style.*?>.*?</style>|<script.*?>.*?</script>|<.*?>',
  caseSensitive: false,
  dotAll: true,
);

final _mediaTag = RegExp(
  r"""<\b(?:img|audio|video|object|source)\b(?:[^>]|"[^"]+?"|'[^']+?')+?\b(?:src|data)\b=(?:"([^"]+?)"[^>]*>|'([^']+?)'[^>]*>|([^ >]+?)(?:\x20[^>]*>|>))""",
  caseSensitive: false,
  dotAll: true,
);

/// Removes HTML while retaining media filenames as searchable field text.
///
/// Media tags with `src` or `data` values become a space, the filename, and a
/// space before remaining markup is removed. HTML character references in the
/// resulting text are decoded, matching Anki Core's field preparation path.
String stripHtmlPreservingMediaFilenames(String html) {
  final withMediaNames = html.replaceAllMapped(_mediaTag, (match) {
    for (var group = 1; group <= 3; group++) {
      final filename = match.group(group);
      if (filename != null) return ' $filename ';
    }
    return match.group(0)!;
  });
  final withoutMarkup = withMediaNames.replaceAll(_htmlTags, '');
  const sentinel = '\uE000';
  final decoded = (parseFragment('$withoutMarkup$sentinel').text ?? '')
      .replaceAll('\u00a0', ' ');
  return decoded.endsWith(sentinel)
      ? decoded.substring(0, decoded.length - sentinel.length)
      : decoded;
}
