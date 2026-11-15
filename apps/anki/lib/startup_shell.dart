/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'app_config.dart';

/// Neutral landing shell shown until product screens are implemented.
final class StartupShell extends StatelessWidget {
  const StartupShell({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(
        config.appName,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    ),
  );
}
