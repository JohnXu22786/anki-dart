// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:fixnum/fixnum.dart';
import 'package:anki_backend_models/anki_backend_models.dart'
    show decodeAnkiHtmlEntities;

/// Options for the in-memory Notes or Cards text export.
final class CollectionTextExportOptions {
  const CollectionTextExportOptions({
    required this.includeHtml,
    this.includeTags = false,
    this.includeDeckName = false,
    this.includeNotetypeName = false,
    this.includeGuid = false,
  });

  final bool includeHtml;
  final bool includeTags;
  final bool includeDeckName;
  final bool includeNotetypeName;
  final bool includeGuid;
}

/// Generated text and the number of records represented by it.
final class CollectionTextExportResult {
  const CollectionTextExportResult({required this.text, required this.count});
  final String text;
  final int count;
}

/// Serializes selected collection values to Core-compatible tab separated
/// records. Collection selection and rendering are supplied by the caller.
CollectionTextExportResult generateCollectionTextExport({
  required bool cards,
  required CollectionTextExportOptions options,
  required List<CollectionTextExportNote> notes,
  required List<CollectionTextExportCard> cardRecords,
  int fieldColumnCount = 0,
}) {
  final out = StringBuffer('#separator:tab\n#html:${options.includeHtml}\n');
  if (cards) {
    for (final record in cardRecords) {
      out.writeln('${_tsv(record.question)}\t${_tsv(record.answer)}');
    }
    return CollectionTextExportResult(
      text: out.toString(),
      count: cardRecords.length,
    );
  }
  final fieldColumns = notes.fold<int>(
    fieldColumnCount,
    (n, note) => note.fields.length > n ? note.fields.length : n,
  );
  int fieldStart = 0;
  if (options.includeGuid) {
    out.writeln('#guid column:1');
    fieldStart++;
  }
  if (options.includeNotetypeName) {
    out.writeln('#notetype column:${fieldStart + 1}');
    fieldStart++;
  }
  if (options.includeDeckName) {
    out.writeln('#deck column:${fieldStart + 1}');
    fieldStart++;
  }
  if (options.includeTags)
    out.writeln('#tags column:${fieldStart + fieldColumns + 1}');
  for (final note in notes) {
    final row = <String>[];
    if (options.includeGuid) row.add(note.guid);
    if (options.includeNotetypeName) row.add(note.notetypeName);
    if (options.includeDeckName) row.add(note.deckName);
    row.addAll(note.fields);
    while (row.length < fieldStart + fieldColumns) {
      row.add('');
    }
    if (options.includeTags) row.add(note.tags.join(' '));
    out.writeln(row.map(_tsv).join('\t'));
  }
  return CollectionTextExportResult(text: out.toString(), count: notes.length);
}

final class CollectionTextExportNote {
  const CollectionTextExportNote({
    required this.guid,
    required this.notetypeName,
    required this.deckName,
    required this.fields,
    required this.tags,
  });
  final String guid, notetypeName, deckName;
  final List<String> fields, tags;
}

final class CollectionTextExportCard {
  const CollectionTextExportCard({
    required this.id,
    required this.question,
    required this.answer,
  });
  final Int64 id;
  final String question, answer;
}

String _tsv(String value) {
  if (!value.contains(RegExp('[\\t\\r\\n"]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String exportTextField(String value, bool includeHtml) {
  final stripped = _stripRedundantSections(value);
  return _htmlToText(stripped, includeHtml);
}

/// Converts the answer side after removing the rendered question prefix.
String exportCardAnswer(String renderedAnswer, bool includeHtml) {
  final stripped = _stripRedundantSections(renderedAnswer).replaceFirst(
    RegExp(r'^.*<hr id=answer>\n*', caseSensitive: false, dotAll: true),
    '',
  );
  return _htmlToText(stripped, includeHtml);
}

String _stripRedundantSections(String value) => value
    .replaceAll(
      RegExp(r'<style>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    )
    .replaceAll(RegExp(r'\[\[type:[^\]]+\]\]', caseSensitive: false), '');

String _htmlToText(String stripped, bool includeHtml) {
  if (includeHtml) return stripped;
  final plainText = stripped
      .replaceAll(RegExp(r'<br\s*/?>|<div>|\n', caseSensitive: false), ' ')
      .replaceAll(
        RegExp(
          r'<!--.*?-->|<style.*?>.*?</style>|<script.*?>.*?</script>|<.*?>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'\[sound:[^]]+\]'), '');
  return decodeAnkiHtmlEntities(plainText).trim();
}
