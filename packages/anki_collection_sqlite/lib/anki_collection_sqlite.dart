// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

export 'src/collection_sqlite_storage.dart';
export 'src/add_note.dart';
export 'src/deck_tree.dart' show buildCoreDeckTree;
export 'src/search_executor.dart';
export 'src/note_update.dart';
export 'src/text_export.dart';
export 'src/portable_package_io.dart';
export 'src/apkg_package_builder.dart';
export 'src/apkg_exporter.dart';

export 'package:anki_search_sql/anki_search_sql.dart'
    show CompiledSearchSqlWithSort;

export 'package:anki_collection_schema/anki_collection_schema.dart'
    show
        CollectionIntegrityException,
        CollectionOpenCallbacks,
        CollectionOpenResult,
        openOrCreateCollection;
