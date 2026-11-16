/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:anki_dart/profile_onboarding.dart';
import 'package:anki_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding completion persists across runtime instances', () async {
    final storage = _MemoryStore();
    final firstRun = SharedProfileRuntime(storage);

    expect(await firstRun.isFirstRun(), isTrue);
    await firstRun.completeOnboarding();

    expect(await SharedProfileRuntime(storage).isFirstRun(), isFalse);
  });

  test(
    'default creation, profile changes, switching and reload persist',
    () async {
      final storage = _MemoryStore();
      final runtime = SharedProfileRuntime(storage);
      await runtime.completeOnboarding();
      final manager = ProfileManager(
        runtime,
        generateProfileId: () => const ProfileId('work'),
      );

      final initial = await manager.initializeActiveProfile();
      expect(initial.items, [
        const ProfileItem(id: ProfileId.defaultId, name: 'Default'),
      ]);
      expect(initial.active?.id, ProfileId.defaultId);

      final name = (ProfileName.validate('Personal') as ProfileNameValid).name;
      final profileId = await manager.createNewProfile(name);
      await manager.renameProfile(
        profileId,
        (ProfileName.validate('Work') as ProfileNameValid).name,
      );
      final switched = await manager.switchActiveProfile(profileId);
      expect(switched, isA<ProfileSwitchGuardSuccess>());

      final reloaded = await ProfileManager(SharedProfileRuntime(storage))
          .load();
      expect(reloaded.items, [
        const ProfileItem(id: ProfileId.defaultId, name: 'Default'),
        const ProfileItem(id: ProfileId('work'), name: 'Work'),
      ]);
      expect(reloaded.active?.id, profileId);
    },
  );

  test('malformed persisted data is surfaced without resetting it', () async {
    final storage = _MemoryStore()..values['anki.shared.runtime.v1'] = '{bad';

    await expectLater(
      SharedProfileRuntime(storage).load(),
      throwsA(isA<FormatException>()),
    );

    expect(storage.values['anki.shared.runtime.v1'], '{bad');
  });

  test('overlapping profile writes retain both updates', () async {
    final storage = _MemoryStore();
    final runtime = SharedProfileRuntime(storage);
    final first = (ProfileName.validate('First') as ProfileNameValid).name;
    final second = (ProfileName.validate('Second') as ProfileNameValid).name;

    await Future.wait([
      runtime.create(const ProfileId('first'), first),
      runtime.create(const ProfileId('second'), second),
    ]);

    expect((await runtime.load()).items, const [
      ProfileItem(id: ProfileId('first'), name: 'First'),
      ProfileItem(id: ProfileId('second'), name: 'Second'),
    ]);
  });

  test(
    'failed profile writes propagate without changing stored data',
    () async {
      final storage = _MemoryStore();
      final runtime = SharedProfileRuntime(storage);
      await runtime.completeOnboarding();
      await ProfileManager(runtime).initializeActiveProfile();
      final before = storage.values['anki.shared.runtime.v1'];
      storage.failNextWrite = true;

      await expectLater(
        runtime.rename(
          ProfileId.defaultId,
          (ProfileName.validate('Renamed') as ProfileNameValid).name,
        ),
        throwsA(isA<StateError>()),
      );

      expect(storage.values['anki.shared.runtime.v1'], before);
      expect(
        (await SharedProfileRuntime(storage).load()).items.single.name,
        'Default',
      );

      await runtime.rename(
        ProfileId.defaultId,
        (ProfileName.validate('Renamed') as ProfileNameValid).name,
      );
      expect((await runtime.load()).items.single.name, 'Renamed');
    },
  );
}

final class _MemoryStore implements AppKeyValueStore {
  final values = <String, String>{};
  bool failNextWrite = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated storage failure');
    }
    values[key] = value;
  }
}
