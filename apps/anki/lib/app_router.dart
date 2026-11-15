/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'startup_shell.dart';

/// Application routes shared by all Flutter targets.
final class AppRouter extends StatelessWidget {
  const AppRouter({this.config = const AppConfig(), super.key});

  static const homeRoute = '/';

  final AppConfig config;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: config.appName,
    initialRoute: homeRoute,
    routes: {homeRoute: (_) => StartupShell(config: config)},
  );
}
