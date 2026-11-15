/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';
import 'package:anki_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initialization creates and activates the Default profile in order',
    () async {
      final repository = _Repository();
      final manager = ProfileManager(repository);

      final snapshot = await manager.initializeActiveProfile();

      expect(snapshot.active?.id, ProfileId.defaultId);
      expect(snapshot.active?.name, ProfileManager.defaultProfileName);
      expect(repository.events, [
        'load',
        'create:default:Default:true',
        'activate:default',
        'load',
      ]);
    },
  );

  test(
    'new profiles retry colliding IDs and persist the first unused ID',
    () async {
      final repository = _Repository()
        ..items.add(
          const ProfileItem(id: ProfileId('taken'), name: 'Existing'),
        );
      final candidates = [ProfileId('taken'), ProfileId('new')].iterator;
      final manager = ProfileManager(
        repository,
        generateProfileId: () {
          if (!candidates.moveNext()) throw StateError('generator exhausted');
          return candidates.current;
        },
      );

      final id = await manager.createNewProfile(
        (ProfileName.validate('Work') as ProfileNameValid).name,
      );

      expect(id, ProfileId('new'));
      expect(repository.events, ['load', 'create:new:Work:false']);
    },
  );

  test(
    'ID collisions stop after the source limit without persisting a profile',
    () async {
      final repository = _Repository()
        ..items.add(
          const ProfileItem(id: ProfileId('taken'), name: 'Existing'),
        );
      var generated = 0;
      final manager = ProfileManager(
        repository,
        generateProfileId: () {
          generated++;
          return ProfileId('taken');
        },
      );

      await expectLater(
        manager.createNewProfile(
          (ProfileName.validate('Work') as ProfileNameValid).name,
        ),
        throwsA(isA<StateError>()),
      );

      expect(generated, ProfileManager.maxIdGenerationAttempts);
      expect(repository.events, ['load']);
    },
  );

  test(
    'profile switching runs ordered safety checks before persisting',
    () async {
      final repository = _Repository()
        ..items.add(const ProfileItem(id: ProfileId('target'), name: 'Target'));
      repository.checks.addAll([
        () async {
          repository.events.add('check-one');
          return null;
        },
        () async {
          repository.events.add('check-two');
          return null;
        },
      ]);
      final manager = ProfileManager(repository);

      final result = await manager.switchActiveProfile(ProfileId('target'));

      expect(result, isA<ProfileSwitchGuardSuccess>());
      expect(repository.events, ['check-one', 'check-two', 'activate:target']);
    },
  );

  test(
    'profile switching collects blockers without persisting the target',
    () async {
      final repository = _Repository()
        ..items.add(const ProfileItem(id: ProfileId('target'), name: 'Target'));
      repository.checks.addAll([
        () async => ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
        () async => ProfileSwitchBlockReason.COLLECTION_BUSY,
      ]);
      final manager = ProfileManager(repository);

      final result = await manager.switchActiveProfile(ProfileId('target'));

      expect(result, isA<ProfileSwitchGuardBlocked>());
      expect((result as ProfileSwitchGuardBlocked).reasons, {
        ProfileSwitchBlockReason.BACKUP_IN_PROGRESS,
        ProfileSwitchBlockReason.COLLECTION_BUSY,
      });
      expect(repository.events, isEmpty);
    },
  );
}

final class _Repository implements ProfileRepository {
  final events = <String>[];
  final items = <ProfileItem>[];
  final checks = <Future<ProfileSwitchBlockReason?> Function()>[];
  ProfileItem? active;

  @override
  Future<ProfileSnapshot> load() async {
    events.add('load');
    return ProfileSnapshot(items: items, active: active);
  }

  @override
  Future<void> create(
    ProfileId id,
    ProfileName name, {
    bool isActive = false,
  }) async {
    events.add('create:${id.value}:${name.value}:$isActive');
    final item = ProfileItem(id: id, name: name.value);
    items.add(item);
    if (isActive) active = item;
  }

  @override
  Future<void> rename(ProfileId id, ProfileName name) async {}

  @override
  Future<void> persistActiveProfile(ProfileId id) async {
    events.add('activate:${id.value}');
    active = items.where((profile) => profile.id == id).first;
  }

  @override
  Iterable<Future<ProfileSwitchBlockReason?> Function()>
  get profileSwitchChecks => checks;
}
