/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:anki_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('neutral startup shell shows the configured app name', (
    tester,
  ) async {
    await tester.pumpWidget(const AppRouter());

    expect(find.text('Anki'), findsOneWidget);
  });

  test('Flutter UI depends on the existing pure Dart package boundary', () {
    final appManifest = File('pubspec.yaml').readAsStringSync();
    final domainManifest = File('../../pubspec.yaml').readAsStringSync();

    expect(appManifest, contains('anki_dart:'));
    expect(appManifest, contains('path: ../..'));
    expect(domainManifest, isNot(contains('flutter:')));
  });
}
