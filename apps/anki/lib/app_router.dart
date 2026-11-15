/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_config.dart';
import 'app_services.dart';
import 'l10n/app_localizations.dart';
import 'startup_shell.dart';

/// Application routes shared by all Flutter targets.
final class AppRouter extends StatelessWidget {
  const AppRouter({this.config = const AppConfig(), this.services, super.key});

  static const homeRoute = '/';

  final AppConfig config;
  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    const unconfigured = UnconfiguredAppServices();
    return MaterialApp(
      title: config.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupShell(
        config: config,
        services:
            services ??
            const AppServices(startup: unconfigured, profiles: unconfigured),
      ),
    );
  }
}
