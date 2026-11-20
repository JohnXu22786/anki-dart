/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:anki_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'text_export_delivery.dart';

/// Shared result flow. A failed or dismissed OS action leaves the result ready
/// so the user can retry either action or close the result surface.
final class TextExportReadyDialog extends StatefulWidget {
  const TextExportReadyDialog({
    required this.artifact,
    required this.delivery,
    super.key,
  });

  final TextExportArtifact artifact;
  final TextExportDelivery delivery;

  @override
  State<TextExportReadyDialog> createState() => _TextExportReadyDialogState();
}

final class _TextExportReadyDialogState extends State<TextExportReadyDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _deliver(Future<bool> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final handled = await action();
      if (!mounted) return;
      if (handled) Navigator.pop(context, true);
    } on TextExportShareTooLargeException {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.exportShareTooLarge,
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.exportDeliveryFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.exportReadyTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.artifact.fileName),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, key: const ValueKey('export-delivery-error')),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _deliver(() => widget.delivery.share(widget.artifact)),
          child: Text(strings.exportShare),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _deliver(() => widget.delivery.save(widget.artifact)),
          child: Text(strings.exportSave),
        ),
      ],
    );
  }
}
