/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:anki_backend_models/anki_backend_models.dart' as models;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// The fields and tag choices shown for one existing collection note.
final class NoteEditorContent {
  NoteEditorContent({
    required List<String> labels,
    required List<String> values,
    List<String> tags = const [],
    List<String> availableTags = const [],
  }) : labels = List.unmodifiable(labels),
       values = List.unmodifiable(values),
       tags = List.unmodifiable(tags),
       availableTags = List.unmodifiable(availableTags) {
    if (labels.length != values.length) {
      throw ArgumentError(
        'Note field labels and values must have equal length.',
      );
    }
  }

  final List<String> labels;
  final List<String> values;
  final List<String> tags;
  final List<String> availableTags;
}

/// Collection boundary used by the shared editor screen and its widget tests.
abstract interface class NoteEditorPort {
  Future<NoteEditorContent> loadNote(Int64 noteId);
  Future<void> saveNote(Int64 noteId, List<String> fields, List<String> tags);
}

final class NewNoteEditorDraft {
  const NewNoteEditorDraft({
    required this.notetypeId,
    required this.deckId,
    required this.content,
    this.noteTypes = const [],
    this.deckName = '',
    this.note,
  });

  final Int64 notetypeId;
  final Int64 deckId;
  final String deckName;
  final NoteEditorContent content;
  final List<NewNoteEditorNoteType> noteTypes;
  final models.Note? note;

  NewNoteEditorDraft copyWith({
    required Int64 deckId,
    required String deckName,
  }) => NewNoteEditorDraft(
    notetypeId: notetypeId,
    deckId: deckId,
    deckName: deckName,
    content: content,
    noteTypes: noteTypes,
    note: note,
  );
}

/// A selectable note type for the shared new-note editor.
final class NewNoteEditorNoteType {
  const NewNoteEditorNoteType({required this.id, required this.name});

  final Int64 id;
  final String name;
}

/// A selectable regular deck for the shared new-note editor.
final class NewNoteEditorDeck {
  const NewNoteEditorDeck({required this.id, required this.name});

  final Int64 id;
  final String name;
}

abstract interface class NewNoteEditorPort implements NoteEditorPort {
  Future<NewNoteEditorDraft> loadNewNote();
  Future<NewNoteEditorDraft> changeNewNoteType({
    required NewNoteEditorDraft draft,
    required Int64 notetypeId,
    required List<String> fields,
    required List<String> tags,
  });
  Future<List<NewNoteEditorDeck>> loadSelectableDecks();
  Future<NoteFieldsCheckResult> validateNewNote(
    Int64 notetypeId,
    List<String> fields,
  );
  Future<int> saveNewNote({
    required NewNoteEditorDraft draft,
    required List<String> fields,
    required List<String> tags,
  });
}

/// Shared, responsive editor for an existing note's fields and tags.
final class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    required this.port,
    this.noteId,
    this.resolveNoteId,
    this.onCancel,
    super.key,
  }) : assert(noteId != null || resolveNoteId != null),
       _isNewNote = false;

  const NoteEditorScreen.newNote({
    required NewNoteEditorPort newNotePort,
    this.onCancel,
    super.key,
  }) : noteId = null,
       resolveNoteId = null,
       port = newNotePort,
       _isNewNote = true;

  final Int64? noteId;
  final Future<Int64> Function()? resolveNoteId;
  final NoteEditorPort port;
  final bool _isNewNote;
  final VoidCallback? onCancel;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

final class _NoteEditorScreenState extends State<NoteEditorScreen> {
  NoteEditorContent? _content;
  List<TextEditingController> _fields = [];
  List<String> _tags = [];
  bool _loading = true;
  bool _saving = false;
  bool _changingType = false;
  int _noteTypeSelectionRevision = 0;
  bool _committedRetryPending = false;
  String? _loadError;
  String? _saveError;
  Int64? _resolvedNoteId;
  NewNoteEditorDraft? _newNoteDraft;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NoteEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId ||
        oldWidget.resolveNoteId != widget.resolveNoteId ||
        oldWidget.port != widget.port ||
        oldWidget._isNewNote != widget._isNewNote) {
      _disposeFields();
      _load();
    }
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  void _disposeFields() {
    for (final field in _fields) {
      field.dispose();
    }
    _fields = [];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _saveError = null;
      _committedRetryPending = false;
    });
    try {
      late final NoteEditorContent content;
      if (widget._isNewNote) {
        final draft = await (widget.port as NewNoteEditorPort).loadNewNote();
        _newNoteDraft = draft;
        content = draft.content;
      } else {
        final noteId = widget.noteId ?? await widget.resolveNoteId!();
        content = await widget.port.loadNote(noteId);
        _resolvedNoteId = noteId;
      }
      if (!mounted) return;
      _disposeFields();
      _content = content;
      _fields = [
        for (final value in content.values) TextEditingController(text: value),
      ];
      _tags = List.of(content.tags);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _content = null;
        _loadError = AppLocalizations.of(context)!.noteEditorLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _content == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final fields = _fields.map((field) => field.text).toList(growable: false);
      final tags = List<String>.of(_tags);
      if (widget._isNewNote) {
        final port = widget.port as NewNoteEditorPort;
        final draft = _newNoteDraft!;
        final result = await port.validateNewNote(draft.notetypeId, fields);
        if (result case NoteFieldsCheckFailure(:final localizedMessage)) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _saveError =
                localizedMessage ??
                AppLocalizations.of(context)!.noteEditorValidationError;
          });
          return;
        }
        final cardCount = await port.saveNewNote(
          draft: draft,
          fields: fields,
          tags: tags,
        );
        if (!mounted) return;
        final strings = AppLocalizations.of(context)!;
        setState(() {
          _saving = false;
          _committedRetryPending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.noteEditorAddedCards(cardCount))),
        );
        await _load();
        return;
      }
      await widget.port.saveNote(_resolvedNoteId!, fields, tags);
      if (!mounted) return;
      setState(() => _saving = false);
      final strings = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.noteEditorSaved)));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    } catch (_) {
      if (!mounted) return;
      final draftNoteId = _newNoteDraft?.note?.id;
      final committedButNotFlushed =
          widget._isNewNote && draftNoteId != null && draftNoteId != Int64.ZERO;
      final strings = AppLocalizations.of(context)!;
      setState(() {
        _saving = false;
        _committedRetryPending = committedButNotFlushed;
        _saveError = committedButNotFlushed
            ? strings.noteEditorCommittedRetryError
            : strings.noteEditorSaveError;
      });
    }
  }

  void _cancel() {
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_saving && !_committedRetryPending,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget._isNewNote
                ? strings.noteEditorAddTitle
                : strings.noteEditorTitle,
          ),
          leading: IconButton(
            tooltip: strings.cancel,
            onPressed: _saving || _committedRetryPending ? null : _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _buildLoadError(strings)
            : _buildFields(strings),
      ),
    );
  }

  Widget _buildLoadError(AppLocalizations strings) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_loadError!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: Text(strings.tryAgain)),
        ],
      ),
    ),
  );

  Widget _buildFields(AppLocalizations strings) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 600 ? 16 : 32,
            vertical: 24,
          ),
          children: [
            if (widget._isNewNote) ...[
              if (_newNoteDraft!.noteTypes.isNotEmpty) ...[
                Text(
                  strings.noteEditorNoteType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: const Key('note-editor-select-note-type'),
                  child: DropdownButtonFormField<Int64>(
                    key: ValueKey(
                      'note-editor-select-note-type-'
                      '${_newNoteDraft!.notetypeId}-$_noteTypeSelectionRevision',
                    ),
                    initialValue: _newNoteDraft!.notetypeId,
                    items: [
                      for (final type in _newNoteDraft!.noteTypes)
                        DropdownMenuItem(
                          value: type.id,
                          child: Text(type.name),
                        ),
                    ],
                    onChanged:
                        _saving || _changingType || _committedRetryPending
                        ? null
                        : (id) {
                            if (id != null) _selectNoteType(id);
                          },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                strings.noteEditorDeck,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('note-editor-select-deck'),
                onPressed: _saving || _changingType || _committedRetryPending
                    ? null
                    : _selectDeck,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(
                  _newNoteDraft!.deckName.isEmpty
                      ? strings.noteEditorChooseDeck
                      : _newNoteDraft!.deckName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
            ],
            for (var index = 0; index < _content!.labels.length; index++) ...[
              TextField(
                key: Key('note-field-$index'),
                controller: _fields[index],
                enabled: !_saving && !_changingType,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _content!.labels[index],
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              strings.noteEditorTags,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tag in _tags)
                  InputChip(
                    key: Key('note-editor-tag-$tag'),
                    label: Text(tag),
                    onDeleted: _saving || _changingType
                        ? null
                        : () => setState(() => _tags.remove(tag)),
                  ),
                OutlinedButton.icon(
                  key: const Key('note-editor-tags'),
                  onPressed: _saving || _changingType ? null : _editTags,
                  icon: const Icon(Icons.sell_outlined),
                  label: Text(strings.noteEditorEditTags),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_saveError case final error?) ...[
              Semantics(liveRegion: true, child: Text(error)),
              const SizedBox(height: 12),
            ],
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _saving || _committedRetryPending ? null : _cancel,
                  child: Text(strings.cancel),
                ),
                FilledButton.icon(
                  key: const Key('note-editor-save'),
                  onPressed: _saving || _changingType ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving ? strings.noteEditorSaving : strings.save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _editTags() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _NoteTagsDialog(
        selectedTags: _tags,
        allTags: _content!.availableTags,
      ),
    );
    if (result != null && mounted) {
      final unchangedSelection =
          result.length == _tags.length &&
          _tags.every(
            (tag) => result.any((selected) => compareTag(tag, selected) == 0),
          );
      setState(() => _tags = unchangedSelection ? List.of(_tags) : result);
    }
  }

  Future<void> _selectDeck() async {
    final port = widget.port as NewNoteEditorPort;
    final selected = await showDialog<NewNoteEditorDeck>(
      context: context,
      builder: (context) => _NewNoteDeckDialog(port: port),
    );
    if (selected != null && mounted) {
      setState(() {
        _newNoteDraft = _newNoteDraft!.copyWith(
          deckId: selected.id,
          deckName: selected.name,
        );
        _saveError = null;
      });
    }
  }

  Future<void> _selectNoteType(Int64 notetypeId) async {
    final draft = _newNoteDraft!;
    if (notetypeId == draft.notetypeId || _changingType) return;
    setState(() {
      _changingType = true;
      _saveError = null;
    });
    try {
      final fields = _fields.map((field) => field.text).toList(growable: false);
      final updated = await (widget.port as NewNoteEditorPort)
          .changeNewNoteType(
            draft: draft,
            notetypeId: notetypeId,
            fields: fields,
            tags: List<String>.of(_tags),
          );
      if (!mounted) return;
      _disposeFields();
      setState(() {
        _newNoteDraft = updated;
        _content = updated.content;
        _fields = [
          for (final value in updated.content.values)
            TextEditingController(text: value),
        ];
        _tags = List.of(updated.content.tags);
        _changingType = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _changingType = false;
        _noteTypeSelectionRevision++;
        _saveError = AppLocalizations.of(context)!.noteEditorSaveError;
      });
    }
  }
}

final class _NewNoteDeckDialog extends StatefulWidget {
  const _NewNoteDeckDialog({required this.port});
  final NewNoteEditorPort port;

  @override
  State<_NewNoteDeckDialog> createState() => _NewNoteDeckDialogState();
}

final class _NewNoteDeckDialogState extends State<_NewNoteDeckDialog> {
  late Future<List<NewNoteEditorDeck>> _decks;
  final _filter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _decks = widget.port.loadSelectableDecks();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _decks = widget.port.loadSelectableDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.noteEditorChooseDeck),
      content: SizedBox(
        width: 480,
        height: 420,
        child: FutureBuilder<List<NewNoteEditorDeck>>(
          future: _decks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.noteEditorDeckLoadError),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _reload, child: Text(strings.tryAgain)),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final decks = snapshot.data!;
            if (decks.isEmpty) return Text(strings.noteEditorNoDecks);
            final filter = _filter.text.trim().toLowerCase();
            final visible = decks
                .where((deck) => deck.name.toLowerCase().contains(filter))
                .toList(growable: false);
            return Column(
              children: [
                if (decks.length > 8)
                  TextField(
                    key: const Key('note-editor-deck-filter'),
                    controller: _filter,
                    decoration: InputDecoration(
                      labelText: strings.noteEditorFilterDecks,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final deck in visible)
                        ListTile(
                          key: Key('note-editor-deck-${deck.id}'),
                          title: Text(deck.name.split('::').last),
                          subtitle: deck.name.contains('::')
                              ? Text(deck.name)
                              : null,
                          onTap: () => Navigator.pop(context, deck),
                        ),
                      if (visible.isEmpty)
                        ListTile(title: Text(strings.noteEditorNoDeckMatches)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
      ],
    );
  }
}

final class _NoteTagsDialog extends StatefulWidget {
  const _NoteTagsDialog({required this.selectedTags, required this.allTags});
  final List<String> selectedTags;
  final List<String> allTags;

  @override
  State<_NoteTagsDialog> createState() => _NoteTagsDialogState();
}

final class _NoteTagsDialogState extends State<_NoteTagsDialog> {
  late final List<String> _allTags;
  late List<String> _selected;
  final _filter = TextEditingController();

  bool _hasTag(Iterable<String> tags, String tag) =>
      tags.any((existing) => compareTag(existing, tag) == 0);

  @override
  void initState() {
    super.initState();
    _allTags = [];
    for (final tag in [...widget.allTags, ...widget.selectedTags]) {
      if (!_hasTag(_allTags, tag)) _allTags.add(tag);
    }
    _selected = List.of(widget.selectedTags);
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    final strings = AppLocalizations.of(context)!;
    var input = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.noteEditorAddTag),
        content: TextField(
          key: const Key('new-tag-name'),
          autofocus: true,
          decoration: InputDecoration(labelText: strings.noteEditorTagName),
          onChanged: (value) => input = value,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input),
            child: Text(strings.add),
          ),
        ],
      ),
    );
    if (!mounted || value == null) return;
    if (value.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.noteEditorEmptyTag)));
      return;
    }
    final normalized = value
        .split('::')
        .map(
          (part) => part.replaceAll(RegExp(r'[\s\u3000]+'), '').isEmpty
              ? 'blank'
              : part.replaceAll(RegExp(r'[\s\u3000]+'), ''),
        )
        .join('::');
    if (normalized.isEmpty ||
        _hasTag(_selected, normalized) ||
        _hasTag(_allTags, normalized)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.noteEditorDuplicateTag)));
      return;
    }
    setState(() {
      _allTags.add(normalized);
      _selected.add(normalized);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final tags = TagsList(_allTags, _selected);
    tags.sort();
    final filter = _filter.text.trim().toLowerCase();
    final visible = tags.where((tag) {
      final folded = tag.toLowerCase();
      return filter.isEmpty ||
          folded.contains(filter) ||
          tags.any(
            (candidate) =>
                candidate.toLowerCase().startsWith('$folded::') &&
                candidate.toLowerCase().contains(filter),
          );
    }).toList();
    return AlertDialog(
      title: Text(strings.noteEditorEditTags),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const Key('tag-filter'),
              controller: _filter,
              decoration: InputDecoration(
                labelText: strings.noteEditorFilterTags,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final tag in visible)
                    CheckboxListTile(
                      key: Key('tag-select-$tag'),
                      tristate: true,
                      value: tags.isChecked(tag)
                          ? true
                          : tags.isIndeterminate(tag)
                          ? null
                          : false,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.only(
                        left: 16.0 * '::'.allMatches(tag).length,
                      ),
                      title: Text(tag.split('::').last),
                      subtitle: tag.contains('::') ? Text(tag) : null,
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          tags.check(tag);
                        } else {
                          tags.uncheck(tag);
                        }
                        _selected = tags.copyOfCheckedTagList();
                      }),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                label: Text(strings.noteEditorAddTag),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TagsList(_allTags, _selected).copyOfCheckedTagList(),
          ),
          child: Text(strings.done),
        ),
      ],
    );
  }
}
