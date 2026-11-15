/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:anki_dart/profile_onboarding.dart';
import 'package:anki_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'first-run setup opens profiles and supports create, rename, switch, and cancel',
    (tester) async {
      final events = <String>[];
      final profiles = _Profiles(events);
      await tester.pumpWidget(
        AppRouter(
          config: const AppConfig(appName: 'Anki Test'),
          services: AppServices(
            startup: _Startup(firstRun: true, events: events),
            profiles: profiles,
            generateProfileId: () => ProfileId('p1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        'Anki Test',
      );

      expect(find.text('Welcome to Anki'), findsOneWidget);
      await tester.tap(find.text('Set up Anki'));
      await tester.pumpAndSettle();
      expect(find.text('Active profile: Default'), findsOneWidget);
      expect(events.take(3), ['inspect', 'complete', 'load']);

      await tester.tap(find.text('Profiles'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Active profile: Default'), findsOneWidget);
      await tester.tap(find.text('Profiles'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile-name')), '   ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Profile name can’t be empty'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('profile-name')), 'a' * 51);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(
        find.text('Profile name must be 50 characters or fewer'),
        findsOneWidget,
      );

      profiles.failNextCreate = true;
      await tester.enterText(find.byKey(const Key('profile-name')), 'Ignored');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Profile could not be saved'), findsOneWidget);
      expect(profiles.items.any((item) => item.name == 'Ignored'), isFalse);

      await tester.tap(find.byKey(const Key('add-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile-name')), 'Work');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(profiles.items.any((item) => item.name == 'Work'), isTrue);

      profiles.failNextRename = true;
      await tester.tap(find.byKey(const Key('rename-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile-name')), 'Ignored');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Profile could not be saved'), findsOneWidget);
      expect(profiles.items.any((item) => item.name == 'Work'), isTrue);

      await tester.tap(find.byKey(const Key('rename-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('profile-name')), 'Study');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(profiles.items.any((item) => item.name == 'Study'), isTrue);

      profiles.failNextSwitch = true;
      await tester.tap(find.byKey(const Key('select-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Profile could not be switched'), findsOneWidget);
      expect(profiles.active.id.value, 'default');

      await tester.tap(find.byKey(const Key('select-p1')));
      await tester.pumpAndSettle();
      expect(profiles.active.id.value, 'p1');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profiles'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-name')), findsNothing);
    },
  );

  testWidgets('storage failure is surfaced and setup can be retried', (
    tester,
  ) async {
    final startup = _Startup(firstRun: true, events: <String>[])
      ..failOnce = true;
    await tester.pumpWidget(
      AppRouter(
        services: AppServices(
          startup: startup,
          profiles: _Profiles(startup.events),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up Anki'));
    await tester.pumpAndSettle();
    expect(find.text('Storage setup failed'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Active profile: Default'), findsOneWidget);
  });

  testWidgets('startup inspection failure has a specific retry path', (
    tester,
  ) async {
    final events = <String>[];
    final startup = _Startup(firstRun: true, events: events)
      ..failInspectOnce = true;
    await tester.pumpWidget(
      AppRouter(
        services: AppServices(startup: startup, profiles: _Profiles(events)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Startup setup status could not be checked'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Anki'), findsOneWidget);
  });

  testWidgets('profile-load failure retries without repeating storage setup', (
    tester,
  ) async {
    final events = <String>[];
    final startup = _Startup(firstRun: true, events: events);
    final profiles = _Profiles(events)..failNextLoad = true;
    await tester.pumpWidget(
      AppRouter(
        services: AppServices(startup: startup, profiles: profiles),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set up Anki'));
    await tester.pumpAndSettle();
    expect(find.text('Profiles could not be loaded'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Active profile: Default'), findsOneWidget);
    expect(startup.completionCount, 1);
    expect(events.where((event) => event == 'load').length, 2);
  });

  testWidgets('switch refresh failure hides the stale profile until retry', (
    tester,
  ) async {
    final events = <String>[];
    final profiles = _Profiles(events)
      ..items.add(const ProfileItem(id: ProfileId('p1'), name: 'Work'));
    await tester.pumpWidget(
      AppRouter(
        services: AppServices(
          startup: _Startup(firstRun: false, events: events),
          profiles: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profiles'));
    await tester.pumpAndSettle();

    profiles.failNextLoad = true;
    await tester.tap(find.byKey(const Key('select-p1')));
    await tester.pumpAndSettle();
    expect(find.text('Profiles could not be loaded'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListTile>(find.byKey(const Key('select-p1'))).selected,
      isTrue,
    );
  });

  testWidgets('short onboarding viewport keeps setup reachable by scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    final events = <String>[];
    await tester.pumpWidget(
      AppRouter(
        services: AppServices(
          startup: _Startup(firstRun: true, events: events),
          profiles: _Profiles(events),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Set up Anki'));
    await tester.tap(find.text('Set up Anki'));
    await tester.pumpAndSettle();
    expect(find.text('Active profile: Default'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'active profile opens the portable deck picker and returns home',
    (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        AppRouter(
          services: AppServices(
            startup: _Startup(firstRun: false, events: events),
            profiles: _Profiles(events),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open decks'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Decks are unavailable until a collection service is connected.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Active profile: Default'), findsOneWidget);
    },
  );

  test('Flutter UI keeps its dependency on the separate pure Dart package', () {
    final appManifest = File('pubspec.yaml').readAsStringSync();
    final domainManifest = File('../../pubspec.yaml').readAsStringSync();

    expect(appManifest, contains('anki_dart:'));
    expect(appManifest, contains('path: ../..'));
    expect(domainManifest, isNot(contains('flutter:')));
  });
}

final class _Startup implements StartupService {
  _Startup({required this.firstRun, required this.events});
  final bool firstRun;
  final List<String> events;
  bool failOnce = false;
  bool failInspectOnce = false;
  bool _completed = false;
  int completionCount = 0;

  @override
  Future<bool> isFirstRun() async {
    events.add('inspect');
    if (failInspectOnce) {
      failInspectOnce = false;
      throw StateError('startup state unavailable');
    }
    return firstRun && !_completed;
  }

  @override
  Future<void> completeOnboarding() async {
    events.add('complete');
    completionCount++;
    if (failOnce) {
      failOnce = false;
      throw StateError('storage unavailable');
    }
    _completed = true;
  }
}

final class _Profiles implements ProfileRepository {
  _Profiles(this.events);

  final List<String> events;
  bool failNextLoad = false;
  bool failNextCreate = false;
  bool failNextRename = false;
  bool failNextSwitch = false;
  final items = <ProfileItem>[
    const ProfileItem(id: ProfileId.defaultId, name: 'Default'),
  ];
  ProfileItem active = const ProfileItem(
    id: ProfileId.defaultId,
    name: 'Default',
  );

  @override
  Future<ProfileSnapshot> load() async {
    events.add('load');
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('profile registry unavailable');
    }
    return ProfileSnapshot(items: items, active: active);
  }

  @override
  Future<void> create(
    ProfileId id,
    ProfileName name, {
    bool isActive = false,
  }) async {
    if (failNextCreate) {
      failNextCreate = false;
      throw StateError('profile create failed');
    }
    final item = ProfileItem(id: id, name: name.value);
    final index = items.indexWhere((profile) => profile.id == id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    if (isActive) active = item;
  }

  @override
  Future<void> rename(ProfileId id, ProfileName name) async {
    if (failNextRename) {
      failNextRename = false;
      throw StateError('profile rename failed');
    }
    final index = items.indexWhere((item) => item.id == id);
    items[index] = ProfileItem(id: id, name: name.value);
    if (active.id == id) active = items[index];
  }

  @override
  Future<void> persistActiveProfile(ProfileId id) async {
    if (failNextSwitch) {
      failNextSwitch = false;
      throw StateError('profile switch failed');
    }
    active = items.singleWhere((item) => item.id == id);
  }

  @override
  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks => const [];
}
