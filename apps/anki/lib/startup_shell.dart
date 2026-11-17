/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'app_collection_callbacks.dart';
import 'app_services.dart';
import 'card_browser_screen.dart';
import 'deck_picker_screen.dart';
import 'l10n/app_localizations.dart';

/// First-run setup, the active-profile home, and the shared profile manager.
final class StartupShell extends StatefulWidget {
  const StartupShell({required this.config, required this.services, super.key});

  final AppConfig config;
  final AppServices services;

  @override
  State<StartupShell> createState() => _StartupShellState();
}

final class _StartupShellState extends State<StartupShell> {
  bool _loading = true;
  bool _firstRun = false;
  String? _error;
  ProfileSnapshot? _snapshot;
  bool _showProfiles = false;
  bool _showDeckPicker = false;
  bool _showCardBrowser = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    late final bool firstRun;
    try {
      firstRun = await widget.services.startup.isFirstRun();
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.startupCheckFailed;
        _loading = false;
      });
      return;
    }

    if (!firstRun) {
      try {
        _snapshot = await widget.services.profileManager
            .initializeActiveProfile();
      } on Object {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context)!.profileLoadFailed;
          _loading = false;
        });
        return;
      }
      try {
        await _openActiveCollection(_snapshot!);
      } on Object {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context)!.collectionOpenFailed;
          _loading = false;
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _firstRun = firstRun;
      _loading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.services.startup.completeOnboarding();
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.storageSetupFailed;
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _firstRun = false);

    late final ProfileSnapshot snapshot;
    try {
      snapshot = await widget.services.profileManager.initializeActiveProfile();
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.profileLoadFailed;
        _loading = false;
      });
      return;
    }
    try {
      await _openActiveCollection(snapshot);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.collectionOpenFailed;
        _loading = false;
      });
    }
  }

  Future<void> _refreshProfiles() async {
    final snapshot = await widget.services.profileManager.load();
    if (snapshot.active == null) {
      throw StateError('Profile load returned no active profile.');
    }
    if (mounted) setState(() => _snapshot = snapshot);
  }

  Future<void> _openActiveCollection(ProfileSnapshot snapshot) async {
    if (!widget.services.collectionRuntimeConfigured) return;
    final active = snapshot.active;
    if (active == null) {
      throw StateError('Profile load returned no active profile.');
    }
    final strings = AppLocalizations.of(context)!;
    await widget.services.collections.openOrCreate(
      active.id,
      callbacks: (storage) => appCollectionOpenCallbacks(storage, strings),
    );
  }

  void _showProfileLoadError() {
    if (!mounted) return;
    setState(() => _error = AppLocalizations.of(context)!.profileLoadFailed);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_showProfiles && !_showDeckPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showProfiles) {
          setState(() => _showProfiles = false);
        } else if (!didPop && _showCardBrowser) {
          setState(() => _showCardBrowser = false);
        } else if (!didPop && _showDeckPicker) {
          setState(() => _showDeckPicker = false);
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _firstRun) {
      return _onboarding(strings);
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _initialize,
                child: Text(strings.tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (_firstRun) return _onboarding(strings);

    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();
    final active = snapshot.active;
    if (active == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.profileLoadFailed),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _initialize,
                child: Text(strings.tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (_showProfiles) {
      return _profileManager(snapshot, strings);
    }
    if (_showCardBrowser) {
      return CardBrowserScreen(
        controller: widget.services.cardBrowser,
        onClose: () => setState(() => _showCardBrowser = false),
      );
    }
    if (_showDeckPicker) {
      return DeckPickerScreen(
        repository: widget.services.deckPicker,
        onClose: () => setState(() => _showDeckPicker = false),
        onBrowseCards: (_) => setState(() => _showCardBrowser = true),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.appName)),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.activeProfile(active.name)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() => _showDeckPicker = true),
                    icon: const Icon(Icons.style),
                    label: Text(strings.openDecks),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => setState(() => _showProfiles = true),
                    icon: const Icon(Icons.switch_account),
                    label: Text(strings.profiles),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _onboarding(AppLocalizations strings) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.style, size: 52),
                    const SizedBox(height: 20),
                    Text(
                      strings.welcomeTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(strings.welcomeBody, textAlign: TextAlign.center),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        _error == null ? strings.setupAnki : strings.tryAgain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _profileManager(ProfileSnapshot snapshot, AppLocalizations strings) =>
      Scaffold(
        appBar: AppBar(
          title: Text(strings.switchProfileTitle),
          leading: IconButton(
            tooltip: strings.close,
            onPressed: () => setState(() => _showProfiles = false),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add-profile'),
          onPressed: () => _editName(),
          icon: const Icon(Icons.add),
          label: Text(strings.addProfile),
        ),
        body: ListView(
          children: [
            for (final profile in snapshot.items)
              ListTile(
                key: Key('select-${profile.id.value}'),
                leading: CircleAvatar(
                  child: Text(
                    profile.initial(firstGraphemeOrNull: _firstGrapheme),
                  ),
                ),
                title: Text(profile.name),
                selected: profile.id == snapshot.active?.id,
                onTap: () => _switchProfile(profile.id),
                trailing: IconButton(
                  key: Key('rename-${profile.id.value}'),
                  tooltip: strings.editProfile(profile.name),
                  onPressed: () => _editName(profile: profile),
                  icon: const Icon(Icons.edit),
                ),
              ),
          ],
        ),
      );

  Future<void> _switchProfile(ProfileId id) async {
    try {
      final result = await widget.services.profileManager.switchActiveProfile(
        id,
      );
      if (!mounted) return;
      if (result is ProfileSwitchGuardBlocked) {
        _showError(AppLocalizations.of(context)!.profileSwitchBlocked);
        return;
      }
    } on Object {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.profileSwitchFailed);
      }
      return;
    }
    late final ProfileSnapshot snapshot;
    try {
      snapshot = await widget.services.profileManager.load();
      if (snapshot.active == null) {
        throw StateError('Profile load returned no active profile.');
      }
    } on Object {
      _showProfileLoadError();
      return;
    }
    try {
      await _openActiveCollection(snapshot);
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.collectionOpenFailed;
        _loading = false;
      });
      return;
    }
    if (mounted) setState(() => _snapshot = snapshot);
  }

  Future<void> _editName({ProfileItem? profile}) async {
    final strings = AppLocalizations.of(context)!;
    final result = await showDialog<ProfileName>(
      context: context,
      builder: (_) => _ProfileNameDialog(
        initialName: profile?.name,
        title: profile == null ? strings.addProfile : strings.rename,
        submitLabel: profile == null ? strings.add : strings.save,
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (profile == null) {
        await widget.services.profileManager.createNewProfile(result);
      } else {
        await widget.services.profileManager.renameProfile(profile.id, result);
      }
    } on Object {
      if (mounted) _showError(strings.profileOperationFailed);
      return;
    }
    try {
      await _refreshProfiles();
    } on Object {
      _showProfileLoadError();
    }
  }
}

final class _ProfileNameDialog extends StatefulWidget {
  const _ProfileNameDialog({
    required this.title,
    required this.submitLabel,
    this.initialName,
  });

  final String title;
  final String submitLabel;
  final String? initialName;

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

final class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations strings) {
    final validation = ProfileName.validate(_controller.text);
    if (validation is ProfileNameEmpty) {
      setState(() => _error = strings.profileNameEmptyError);
    } else if (validation is ProfileNameTooLong) {
      setState(
        () => _error = strings.profileNameTooLongError(ProfileName.maxLength),
      );
    } else {
      Navigator.of(context).pop((validation as ProfileNameValid).name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('profile-name'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(strings),
        decoration: InputDecoration(
          labelText: strings.profileName,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => _submit(strings),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

String? _firstGrapheme(String value) =>
    value.isEmpty ? null : value.characters.first;
