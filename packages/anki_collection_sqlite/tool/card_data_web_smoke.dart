// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/card_data_functions.dart';
import 'package:anki_collection_sqlite/src/fsrs_variable_function.dart';
import 'package:anki_collection_sqlite/src/fsrs_retrievability_functions.dart';
import 'package:anki_collection_sqlite/src/regex_functions.dart';
import 'package:anki_collection_sqlite/src/unicase_collation.dart';

void main() {
  if (!coreRegexHasMatch(r'(?i)needle', 'hay NEEDLE')) {
    throw StateError('Web Core regex case-insensitive prefix failed');
  }
  if (!coreRegexHasMatch(r'(?is)^a.b$', 'a\nb')) {
    throw StateError('Web Core regex dot-all prefix failed');
  }
  if (!coreRegexHasMatch(r'\d+\b', '١٢٣')) {
    throw StateError('Web Core regex Unicode decimal class failed');
  }
  if (!coreRegexHasMatch(r'(?i)a+(?-i)b+', 'AAAbbb') ||
      coreRegexHasMatch(r'(?i)a+(?-i)b+', 'AAABBB')) {
    throw StateError('Web Core regex inline case flags failed');
  }
  if (!coreRegexHasMatch(r'\b{start}\p{Greek}+', ' αβ') ||
      !coreRegexHasMatch(r'[\W]+', '☃')) {
    throw StateError(
      'Web Core regex Unicode boundary/class translation failed',
    );
  }
  if (!coreRegexHasMatch(r'(?m)^foo$', 'x\nfoo\ny') ||
      !coreRegexHasMatch(r'(?s)a.b', 'a\nb')) {
    throw StateError('Web Core regex line/dot flag translation failed');
  }
  if (!coreRegexHasMatch(r'(?i)Σ', 'ς') ||
      !coreRegexHasMatch(r'(?x)a b', 'ab') ||
      !coreRegexHasMatch(r'\P{Greek}+', 'abc') ||
      !coreRegexHasMatch(r'[\p{Greek}--[α]]+', 'β')) {
    throw StateError('Web Core regex Unicode and set syntax failed');
  }
  if (!coreRegexHasMatch(r'(?i)[α]', 'Α') ||
      !coreRegexHasMatch(r'(?i)\p{Lu}', 'a') ||
      coreRegexHasMatch(r'(?i)\p{Lu}', '漢') ||
      !coreRegexHasMatch(r'\p{XID_Start}+', 'abc') ||
      !coreRegexHasMatch(r'(?-u:\w+)', 'abc') ||
      coreRegexHasMatch(r'(?x)[a b]', ' ') ||
      !coreRegexHasMatch(r'[a-g~~b-h]', 'h') ||
      coreRegexHasMatch(r'[\W&&a]', 'a') ||
      coreRegexHasMatch(r'[\W&&\p{Greek}]', 'α') ||
      coreRegexHasMatch(r'\w', '²') ||
      !coreRegexHasMatch(r'\w', 'Ⅷ') ||
      !coreRegexHasMatch(r'\w', '٣') ||
      !coreRegexHasMatch(r'\p{gc=Lu}', 'A') ||
      !coreRegexHasMatch(r'\p{sc=Grek}', 'α') ||
      !coreRegexHasMatch(r'\p{digit}', '7') ||
      !coreRegexHasMatch(r'\p{greek}', 'α') ||
      !coreRegexHasMatch(r'\p{Alpha}', 'α') ||
      !coreRegexHasMatch(r'(?-u:[\S])', '\u00a0') ||
      !coreRegexHasMatch(r'[a[b]]', 'b') ||
      !coreRegexHasMatch(r'[\\W]', r'\') ||
      !coreRegexHasMatch(r'\x41', 'A') ||
      !coreRegexHasMatch(r'[\x41]', 'A') ||
      coreRegexHasMatch(r'(?mR)$foo', 'x\r\nfoo') ||
      !coreRegexHasMatch(r'\(?i:foo\)', 'i:foo)') ||
      !coreRegexHasMatch(r'[\x{1F600}]', '😀') ||
      !coreRegexHasMatch(r'\a', '\x07')) {
    throw StateError('Web Core regex escaped and mode syntax failed');
  }
  if (extractOriginalPosition('{"pos":4294967295}') != 4294967295) {
    throw StateError('Web card-data position lost unsigned 32-bit value');
  }
  if (extractOriginalPosition('{"pos":4294967296}') != null) {
    throw StateError('Web card-data position accepted value above u32');
  }
  if (extractOriginalPosition('{"pos":42,"s":1e999}') != null) {
    throw StateError('Web position ignored an invalid unrelated number');
  }
  if (extractOriginalPosition('{"pos":1,"pos":2}') != null) {
    throw StateError('Web position accepted a duplicate CardData field');
  }
  if (extractCustomData('{"cd":"{\\"z\\":1,\\"a\\":2}"}', 'a') != '2') {
    throw StateError('Web card-data custom JSON lookup failed');
  }
  if (extractCustomData('{"cd":"{\\"n\\":9007199254740993}"}', 'n') !=
      '9007199254740993') {
    throw StateError('Web custom JSON integer lost precision beyond 2^53');
  }
  if (extractCustomData('{"pos":1e999,"cd":"{\\"x\\":1}"}', 'x') != null) {
    throw StateError('Web CardData accepted an out-of-range unrelated number');
  }
  if (extractFsrsVariable('{"s":0.9}', 's') != 0.8999999761581421) {
    throw StateError('Web FSRS value did not retain Core f32 precision');
  }
  if (extractFsrsVariable('{"s":18014401730707455}', 's') !=
      18014400656965632.0) {
    throw StateError('Web FSRS integer did not round directly to Core f32');
  }
  if (extractFsrsVariable('{"s":1,"s":2}', 's') != null) {
    throw StateError('Web FSRS accepted a duplicate CardData field');
  }
  final retrievability = extractFsrsRetrievability(
    '{"s":10,"d":5,"lrt":1000}',
    100,
    10,
    110,
    0,
    87400,
  );
  if (retrievability == null || (retrievability - 0.98847395).abs() > 1e-7) {
    throw StateError('Web FSRS retrievability differs from Core f32 output');
  }
  if (extractFsrsRetrievability(
        '{"s":10,"d":5,"lrt":0}',
        100,
        10,
        110,
        0,
        BigInt.parse('4294967296'),
      ) !=
      1.0) {
    throw StateError('Web FSRS time conversion lost u32 wrapping semantics');
  }
  if (compareUniCase('Straße', 'STRASSE') != 0 ||
      compareUniCase('𐀀', '\ue000') <= 0) {
    throw StateError('Web unicase folding or Unicode ordering failed');
  }
}
