/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// A field-only view of one existing collection note.
final class NoteEditorContent {
  NoteEditorContent({
    required List<String> labels,
    required List<String> values,
  }) : labels = List.unmodifiable(labels),
       values = List.unmodifiable(values) {
    if (labels.length != values.length) {
      throw ArgumentError(
        'Note field labels and values must have equal length.',
      );
    }
  }

  final List<String> labels;
  final List<String> values;
}

/// Collection boundary used by the shared editor screen and its widget tests.
abstract interface class NoteEditorPort {
  Future<NoteEditorContent> loadNote(Int64 noteId);
  Future<void> saveFields(Int64 noteId, List<String> fields);
}

/// Shared, responsive editor for the existing fields on one note.
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
      await widget.port.saveFields(
        _resolvedNoteId!,
        _fields.map((field) => field.text).toList(growable: false),
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
}
