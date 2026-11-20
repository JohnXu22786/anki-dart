/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

final class DeckDescription {
  const DeckDescription({required this.description, required this.markdown});

  final String description;
  final bool markdown;
}

/// Shared editor for the stored description and Markdown flag of a deck.
final class DeckDescriptionEditor extends StatefulWidget {
  const DeckDescriptionEditor({
    required this.initial,
    required this.onSave,
    super.key,
  });

  final DeckDescription initial;
  final Future<void> Function(String description, bool markdown) onSave;

  @override
  State<DeckDescriptionEditor> createState() => _DeckDescriptionEditorState();
}

final class _DeckDescriptionEditorState extends State<DeckDescriptionEditor> {
  late final TextEditingController _description = TextEditingController(
    text: widget.initial.description,
  );
  late bool _markdown = widget.initial.markdown;
  bool _saving = false;
  String? _error;

  bool get _hasChanges =>
      _description.text != widget.initial.description ||
      _markdown != widget.initial.markdown;

  @override
  void initState() {
    super.initState();
    _description.addListener(_descriptionChanged);
  }

  void _descriptionChanged() => setState(() => _error = null);

  @override
  void dispose() {
    _description.removeListener(_descriptionChanged);
    _description.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }
    final strings = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deckDescriptionDiscardTitle),
        content: Text(strings.deckDescriptionDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deckDescriptionDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_description.text, _markdown);
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context)!.deckDescriptionSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _requestClose();
      },
      child: AlertDialog(
        title: Text(strings.editDeckDescription),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('deck-description-input'),
                  controller: _description,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 12,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: strings.deckDescriptionLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                CheckboxListTile(
                  key: const ValueKey('deck-description-markdown'),
                  contentPadding: EdgeInsets.zero,
                  value: _markdown,
                  title: Text(strings.deckDescriptionMarkdown),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _markdown = value ?? false;
                          _error = null;
                        }),
                ),
                if (_error case final error?)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _requestClose,
            child: Text(strings.close),
          ),
          FilledButton(
            onPressed: _saving || !_hasChanges ? null : _save,
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }
}
