/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/anki_dart.dart';
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

/// Shared, responsive editor for an existing note's fields and tags.
final class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    required this.port,
    this.noteId,
    this.resolveNoteId,
    this.onCancel,
    super.key,
  }) : assert(noteId != null || resolveNoteId != null);

  final Int64? noteId;
  final Future<Int64> Function()? resolveNoteId;
  final NoteEditorPort port;
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
  String? _loadError;
  String? _saveError;
  Int64? _resolvedNoteId;

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
        oldWidget.port != widget.port) {
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
    });
    try {
      final noteId = widget.noteId ?? await widget.resolveNoteId!();
      final content = await widget.port.loadNote(noteId);
      if (!mounted) return;
      _disposeFields();
      _content = content;
      _resolvedNoteId = noteId;
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
      await widget.port.saveNote(
        _resolvedNoteId!,
        _fields.map((field) => field.text).toList(growable: false),
        List.of(_tags),
      );
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
      setState(() {
        _saving = false;
        _saveError = AppLocalizations.of(context)!.noteEditorSaveError;
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
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.noteEditorTitle),
          leading: IconButton(
            tooltip: strings.cancel,
            onPressed: _saving ? null : _cancel,
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
            for (var index = 0; index < _content!.labels.length; index++) ...[
              TextField(
                key: Key('note-field-$index'),
                controller: _fields[index],
                enabled: !_saving,
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
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _tags.remove(tag)),
                  ),
                OutlinedButton.icon(
                  key: const Key('note-editor-tags'),
                  onPressed: _saving ? null : _editTags,
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
                  onPressed: _saving ? null : _cancel,
                  child: Text(strings.cancel),
                ),
                FilledButton.icon(
                  key: const Key('note-editor-save'),
                  onPressed: _saving ? null : _save,
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
