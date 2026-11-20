/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

final class DeckDailyLimits {
  const DeckDailyLimits({required this.newPerDay, required this.reviewsPerDay});

  final int newPerDay;
  final int reviewsPerDay;
}

/// Shared editor for the new-card and review-card limits in a deck preset.
final class DeckOptionsEditor extends StatefulWidget {
  const DeckOptionsEditor({
    required this.deckName,
    required this.initialNewPerDay,
    required this.initialReviewsPerDay,
    required this.onSave,
    this.onSaved,
    super.key,
  });

  final String deckName;
  final int initialNewPerDay;
  final int initialReviewsPerDay;
  final Future<void> Function(int newPerDay, int reviewsPerDay) onSave;
  final VoidCallback? onSaved;

  @override
  State<DeckOptionsEditor> createState() => _DeckOptionsEditorState();
}

final class _DeckOptionsEditorState extends State<DeckOptionsEditor> {
  late final TextEditingController _newLimit = TextEditingController(
    text: widget.initialNewPerDay.toString(),
  );
  late final TextEditingController _reviewLimit = TextEditingController(
    text: widget.initialReviewsPerDay.toString(),
  );
  bool _saving = false;
  String? _error;
  late int _savedNewPerDay = widget.initialNewPerDay;
  late int _savedReviewsPerDay = widget.initialReviewsPerDay;

  bool get _hasChanges =>
      int.tryParse(_newLimit.text) != _savedNewPerDay ||
      int.tryParse(_reviewLimit.text) != _savedReviewsPerDay;

  @override
  void initState() {
    super.initState();
    _newLimit.addListener(_inputChanged);
    _reviewLimit.addListener(_inputChanged);
  }

  void _inputChanged() => setState(() => _error = null);

  @override
  void dispose() {
    _newLimit.removeListener(_inputChanged);
    _reviewLimit.removeListener(_inputChanged);
    _newLimit.dispose();
    _reviewLimit.dispose();
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
        title: Text(strings.deckOptionsDiscardTitle),
        content: Text(strings.deckOptionsDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deckOptionsDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    final newPerDay = int.tryParse(_newLimit.text);
    final reviewsPerDay = int.tryParse(_reviewLimit.text);
    if (newPerDay == null ||
        reviewsPerDay == null ||
        newPerDay < 0 ||
        newPerDay > 9999 ||
        reviewsPerDay < 0 ||
        reviewsPerDay > 9999) {
      setState(() => _error = AppLocalizations.of(context)!.deckOptionsInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(newPerDay, reviewsPerDay);
      if (mounted) {
        setState(() {
          _savedNewPerDay = newPerDay;
          _savedReviewsPerDay = reviewsPerDay;
          _saving = false;
        });
        widget.onSaved?.call();
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context)!.deckOptionsSaveFailed;
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
        title: Text('${strings.deckOptions}: ${widget.deckName}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('deck-new-limit'),
                controller: _newLimit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.deckOptionsNewLimit,
                ),
              ),
              TextField(
                key: const ValueKey('deck-review-limit'),
                controller: _reviewLimit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.deckOptionsReviewLimit,
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
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
            ],
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
