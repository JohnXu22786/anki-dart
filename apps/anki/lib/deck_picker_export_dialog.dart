/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_app/l10n/app_localizations.dart';
import 'package:anki_app/deck_picker_screen.dart' show DeckPickerDeck;
import 'package:anki_dart/deck_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

/// Shared configuration dialog for exporting a Deck Picker deck.
final class DeckPickerExportDialog extends StatefulWidget {
  const DeckPickerExportDialog({
    required this.decks,
    required this.selectedDeckId,
    required this.onExport,
    super.key,
  });

  final List<DeckPickerDeck> decks;
  final Int64? selectedDeckId;
  final ValueChanged<DeckPickerExportDeckRequest> onExport;

  @override
  State<DeckPickerExportDialog> createState() => _DeckPickerExportDialogState();
}

final class _DeckPickerExportDialogState extends State<DeckPickerExportDialog> {
  late DeckPickerExportFormat _format;
  late DeckPickerExportOptions _options;
  late int _deckChoice;
  late List<DeckPickerDeck> _flatDecks;

  @override
  void initState() {
    super.initState();
    _format = DeckPickerExportFormat.apkg;
    _options = DeckPickerExportOptions.defaultsFor(_format);
    _flatDecks = _flatten(widget.decks);
    final selectedIndex = _flatDecks.indexWhere(
      (deck) => _deckId(deck) == widget.selectedDeckId,
    );
    _deckChoice = selectedIndex < 0 ? 0 : selectedIndex + 1;
  }

  static List<DeckPickerDeck> _flatten(List<DeckPickerDeck> decks) => [
    for (final deck in decks) ...[deck, ..._flatten(deck.children)],
  ];

  static Int64 _deckId(DeckPickerDeck deck) => deck.exactId ?? Int64(deck.id);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.exportDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<DeckPickerExportFormat>(
              key: const ValueKey('export-format'),
              initialValue: _format,
              decoration: InputDecoration(labelText: strings.exportFormat),
              items: [
                for (final format in DeckPickerExportFormat.values)
                  DropdownMenuItem(
                    value: format,
                    child: Text(_formatLabel(strings, format)),
                  ),
              ],
              onChanged: (format) {
                if (format == null) return;
                setState(() {
                  _format = format;
                  _options = DeckPickerExportOptions.defaultsFor(format);
                });
              },
            ),
            if (_format != DeckPickerExportFormat.collection) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const ValueKey('export-deck'),
                initialValue: _deckChoice,
                decoration: InputDecoration(labelText: strings.exportScope),
                items: [
                  DropdownMenuItem(value: 0, child: Text(strings.allDecks)),
                  for (var index = 0; index < _flatDecks.length; index++)
                    DropdownMenuItem(
                      value: index + 1,
                      child: Text(_flatDecks[index].name),
                    ),
                ],
                onChanged: (choice) {
                  if (choice != null) setState(() => _deckChoice = choice);
                },
              ),
            ],
            const SizedBox(height: 8),
            for (final option in _format.visibleOptions)
              CheckboxListTile(
                key: ValueKey(_optionKey(option)),
                contentPadding: EdgeInsets.zero,
                title: Text(_optionLabel(strings, option)),
                value: _optionValue(option),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) {
                  if (checked == null) return;
                  setState(() => _options = _setOption(option, checked));
                },
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
          onPressed: () {
            final allDecks =
                _format == DeckPickerExportFormat.collection ||
                _deckChoice == 0;
            final exactDeckId = allDecks
                ? null
                : _deckId(_flatDecks[_deckChoice - 1]);
            final request = projectDeckPickerExportDeck(
              legacyDeckId: exactDeckId?.toInt() ?? 0,
              exactDeckId: exactDeckId,
              allDecks: allDecks,
              format: _format,
              options: _options,
            );
            widget.onExport(request);
            Navigator.pop(context);
          },
          child: Text(strings.export),
        ),
      ],
    );
  }

  bool _optionValue(DeckPickerExportOption option) => switch (option) {
    DeckPickerExportOption.includeScheduling => _options.includeScheduling,
    DeckPickerExportOption.includeDeckConfigs => _options.includeDeckConfigs,
    DeckPickerExportOption.includeMedia => _options.includeMedia,
    DeckPickerExportOption.includeLegacy => _options.includeLegacy,
    DeckPickerExportOption.includeHtml => _options.includeHtml,
    DeckPickerExportOption.includeTags => _options.includeTags,
    DeckPickerExportOption.includeDeckName => _options.includeDeckName,
    DeckPickerExportOption.includeNotetypeName => _options.includeNotetypeName,
    DeckPickerExportOption.includeGuid => _options.includeGuid,
  };

  DeckPickerExportOptions _setOption(
    DeckPickerExportOption option,
    bool value,
  ) => switch (option) {
    DeckPickerExportOption.includeScheduling => _options.copyWith(
      includeScheduling: value,
    ),
    DeckPickerExportOption.includeDeckConfigs => _options.copyWith(
      includeDeckConfigs: value,
    ),
    DeckPickerExportOption.includeMedia => _options.copyWith(
      includeMedia: value,
    ),
    DeckPickerExportOption.includeLegacy => _options.copyWith(
      includeLegacy: value,
    ),
    DeckPickerExportOption.includeHtml => _options.copyWith(includeHtml: value),
    DeckPickerExportOption.includeTags => _options.copyWith(includeTags: value),
    DeckPickerExportOption.includeDeckName => _options.copyWith(
      includeDeckName: value,
    ),
    DeckPickerExportOption.includeNotetypeName => _options.copyWith(
      includeNotetypeName: value,
    ),
    DeckPickerExportOption.includeGuid => _options.copyWith(includeGuid: value),
  };

  static String _formatLabel(
    AppLocalizations strings,
    DeckPickerExportFormat format,
  ) => switch (format) {
    DeckPickerExportFormat.collection => strings.exportCollection,
    DeckPickerExportFormat.apkg => strings.exportApkg,
    DeckPickerExportFormat.notes => strings.exportNotes,
    DeckPickerExportFormat.cards => strings.exportCards,
  };

  static String _optionLabel(
    AppLocalizations strings,
    DeckPickerExportOption option,
  ) => switch (option) {
    DeckPickerExportOption.includeScheduling => strings.includeScheduling,
    DeckPickerExportOption.includeDeckConfigs => strings.includeDeckConfigs,
    DeckPickerExportOption.includeMedia => strings.includeMedia,
    DeckPickerExportOption.includeLegacy => strings.includeLegacy,
    DeckPickerExportOption.includeHtml => strings.includeHtml,
    DeckPickerExportOption.includeTags => strings.includeTags,
    DeckPickerExportOption.includeDeckName => strings.includeDeckName,
    DeckPickerExportOption.includeNotetypeName => strings.includeNotetypeName,
    DeckPickerExportOption.includeGuid => strings.includeGuid,
  };

  static String _optionKey(DeckPickerExportOption option) => switch (option) {
    DeckPickerExportOption.includeScheduling => 'include-scheduling',
    DeckPickerExportOption.includeDeckConfigs => 'include-deck-configs',
    DeckPickerExportOption.includeMedia => 'include-media',
    DeckPickerExportOption.includeLegacy => 'include-legacy',
    DeckPickerExportOption.includeHtml => 'include-html',
    DeckPickerExportOption.includeTags => 'include-tags',
    DeckPickerExportOption.includeDeckName => 'include-deck-name',
    DeckPickerExportOption.includeNotetypeName => 'include-notetype-name',
    DeckPickerExportOption.includeGuid => 'include-guid',
  };
}
