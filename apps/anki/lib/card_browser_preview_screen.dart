/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:anki_dart/anki_dart.dart' show PreviewerNavigationModel;

import 'card_browser_preview.dart';
import 'l10n/app_localizations.dart';

/// Cross-platform Card Browser card preview with source-compatible navigation.
final class CardBrowserPreviewScreen extends StatefulWidget {
  const CardBrowserPreviewScreen({required this.controller, super.key});

  final Future<CardBrowserPreviewSession> Function() controller;

  @override
  State<CardBrowserPreviewScreen> createState() =>
      _CardBrowserPreviewScreenState();
}

final class _CardBrowserPreviewScreenState
    extends State<CardBrowserPreviewScreen> {
  late Future<CardBrowserPreviewSession> _load;
  PreviewerNavigationModel? _navigation;

  @override
  void initState() {
    super.initState();
    _load = widget.controller();
  }

  void _retry() => setState(() {
    _navigation = null;
    _load = widget.controller();
  });

  void _next() {
    final navigation = _navigation;
    if (navigation == null || !navigation.isNextButtonEnabled) return;
    setState(() {
      navigation.onNextButtonClick();
    });
  }

  void _previous() {
    final navigation = _navigation;
    if (navigation == null || !navigation.isBackButtonEnabled) return;
    setState(() {
      navigation.onPreviousButtonClick();
    });
  }

  void _toggleBackSideOnly(bool value) {
    final navigation = _navigation;
    if (navigation == null || navigation.backSideOnly == value) return;
    setState(() {
      navigation.toggleBackSideOnly();
    });
  }

  void _selectIndex(double position) {
    final navigation = _navigation;
    if (navigation == null) return;
    setState(() => navigation.onSliderChange(position.round()));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviewPreviousIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _PreviewNextIntent(),
        SingleActivator(LogicalKeyboardKey.space): _PreviewNextIntent(),
      },
      child: Actions(
        actions: {
          _PreviewPreviousIntent: CallbackAction<_PreviewPreviousIntent>(
            onInvoke: (_) {
              _previous();
              return null;
            },
          ),
          _PreviewNextIntent: CallbackAction<_PreviewNextIntent>(
            onInvoke: (_) {
              _next();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(title: Text(strings.browserPreviewTitle)),
            body: FutureBuilder<CardBrowserPreviewSession>(
              future: _load,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _PreviewError(
                    message: strings.browserPreviewLoadFailed,
                    retryLabel: strings.browserPreviewRetry,
                    onRetry: _retry,
                  );
                }
                final session = snapshot.requireData;
                if (session.cards.isEmpty ||
                    session.currentIndex < 0 ||
                    session.currentIndex >= session.cards.length) {
                  return _PreviewError(
                    message: strings.browserPreviewLoadFailed,
                    retryLabel: strings.browserPreviewRetry,
                    onRetry: _retry,
                  );
                }
                _navigation ??= PreviewerNavigationModel(
                  cardsCount: session.cards.length,
                  initialIndex: session.currentIndex,
                );
                final navigation = _navigation!;
                final card = session.cards[navigation.currentIndex];
                final html = navigation.showingAnswer
                    ? card.answerHtml
                    : card.questionHtml;
                return Column(
                  children: [
                    if (session.cards.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Text(
                          strings.browserPreviewProgress(
                            navigation.currentIndex + 1,
                            session.cards.length,
                          ),
                          key: const ValueKey('browser-preview-progress'),
                        ),
                      ),
                      Slider(
                        min: 1,
                        max: session.cards.length.toDouble(),
                        divisions: session.cards.length - 1,
                        value: (navigation.currentIndex + 1).toDouble(),
                        label: '${navigation.currentIndex + 1}',
                        semanticFormatterCallback: (value) =>
                            strings.browserPreviewProgress(
                              value.round(),
                              session.cards.length,
                            ),
                        onChanged: _selectIndex,
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Html(data: html),
                      ),
                    ),
                    SwitchListTile(
                      title: Text(strings.browserPreviewBackSideOnly),
                      value: navigation.backSideOnly,
                      onChanged: _toggleBackSideOnly,
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: strings.browserPreviewPrevious,
                              onPressed: navigation.isBackButtonEnabled
                                  ? _previous
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            FilledButton.tonal(
                              onPressed: navigation.isNextButtonEnabled
                                  ? _next
                                  : null,
                              child: Text(
                                navigation.showingAnswer
                                    ? strings.browserPreviewNext
                                    : strings.browserPreviewShowAnswer,
                              ),
                            ),
                            IconButton(
                              tooltip: strings.browserPreviewNext,
                              onPressed: navigation.isNextButtonEnabled
                                  ? _next
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _PreviewError extends StatelessWidget {
  const _PreviewError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}

final class _PreviewPreviousIntent extends Intent {
  const _PreviewPreviousIntent();
}

final class _PreviewNextIntent extends Intent {
  const _PreviewNextIntent();
}
