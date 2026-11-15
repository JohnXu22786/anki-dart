/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-FileCopyrightText: 2009 Daniel Svärd <daniel.svard@gmail.com>
 * SPDX-FileCopyrightText: 2011 Norbert Nagold <norbert.nagold@gmail.com>
 * SPDX-FileCopyrightText: 2014 Houssam Salem <houssam.salem.au@gmail.com>
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Card.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('loadCardFromBackend', () {
    test('preserves source getter, decoder, cache, and target order', () {
      final events = <String>[];
      final targetValues = <String, Object?>{};
      final source = _source(events, optionalFieldsPresent: true);
      final target = _target(events, targetValues);

      loadCardFromBackend<String, String>(
        source: source,
        target: target,
        decodeCardType: (code) {
          events.add('decodeCardType:$code');
          return 'type:$code';
        },
        decodeQueue: (code) {
          events.add('decodeQueue:$code');
          return 'queue:$code';
        },
      );

      expect(events, <String>[
        'clearRenderOutput',
        'clearCachedNote',
        'id',
        'setId:100',
        'noteId',
        'setNoteId:101',
        'deckId',
        'setDeckId:102',
        'templateIdx',
        'setTemplateIdx:103',
        'mtimeSecs',
        'setMtimeSecs:104',
        'usn',
        'setUsn:105',
        'cardTypeCode',
        'decodeCardType:106',
        'setType:type:106',
        'queueCode',
        'decodeQueue:107',
        'setQueue:queue:107',
        'due',
        'setDue:108',
        'interval',
        'setInterval:109',
        'easeFactor',
        'setEaseFactor:110',
        'reps',
        'setReps:111',
        'lapses',
        'setLapses:112',
        'remainingSteps',
        'setRemainingSteps:113',
        'originalDue',
        'setOriginalDue:114',
        'originalDeckId',
        'setOriginalDeckId:115',
        'flags',
        'setFlags:116',
        'hasOriginalPosition',
        'originalPosition',
        'setOriginalPosition:117',
        'customData',
        'setCustomData:data',
        'hasMemoryState',
        'memoryState',
        'setMemoryState:memory',
        'hasDesiredRetention',
        'desiredRetention',
        'setDesiredRetention:0.9',
        'hasDecay',
        'decay',
        'setDecay:0.2',
        'hasLastReviewTimeSecs',
        'lastReviewTimeSecs',
        'setLastReviewTimeSecs:118',
      ]);
      expect(targetValues, <String, Object?>{
        'id': 100,
        'noteId': 101,
        'deckId': 102,
        'templateIdx': 103,
        'mtimeSecs': 104,
        'usn': 105,
        'type': 'type:106',
        'queue': 'queue:107',
        'due': 108,
        'interval': 109,
        'easeFactor': 110,
        'reps': 111,
        'lapses': 112,
        'remainingSteps': 113,
        'originalDue': 114,
        'originalDeckId': 115,
        'flags': 116,
        'originalPosition': 117,
        'customData': 'data',
        'memoryState': 'memory',
        'desiredRetention': 0.9,
        'decay': 0.2,
        'lastReviewTimeSecs': 118,
      });
    });

    test('assigns null without reading absent optional values', () {
      final events = <String>[];
      final targetValues = <String, Object?>{};
      loadCardFromBackend<String, String>(
        source: _source(events, optionalFieldsPresent: false),
        target: _target(events, targetValues),
        decodeCardType: (code) => 'type:$code',
        decodeQueue: (code) => 'queue:$code',
      );

      expect(events.where((event) => event.startsWith('has')), <String>[
        'hasOriginalPosition',
        'hasMemoryState',
        'hasDesiredRetention',
        'hasDecay',
        'hasLastReviewTimeSecs',
      ]);
      expect(
        events.where((event) => _optionalValueGetters.contains(event)),
        isEmpty,
      );
      expect(targetValues, containsPair('originalPosition', isNull));
      expect(targetValues, containsPair('memoryState', isNull));
      expect(targetValues, containsPair('desiredRetention', isNull));
      expect(targetValues, containsPair('decay', isNull));
      expect(targetValues, containsPair('lastReviewTimeSecs', isNull));
    });

    test('stops at first failure and retains earlier target mutations', () {
      final events = <String>[];
      final targetValues = <String, Object?>{};
      final source = _source(events, optionalFieldsPresent: true);
      final target = _target(events, targetValues, failOn: 'due');

      expect(
        () => loadCardFromBackend<String, String>(
          source: source,
          target: target,
          decodeCardType: (code) => 'type:$code',
          decodeQueue: (code) => 'queue:$code',
        ),
        throwsA(same(_callbackFailure)),
      );

      expect(targetValues.keys, <String>[
        'id',
        'noteId',
        'deckId',
        'templateIdx',
        'mtimeSecs',
        'usn',
        'type',
        'queue',
      ]);
      expect(events.last, 'setDue:108');
      expect(events, isNot(contains('interval')));
    });
  });
}

const _optionalValueGetters = <String>{
  'originalPosition',
  'memoryState',
  'desiredRetention',
  'decay',
  'lastReviewTimeSecs',
};

final _callbackFailure = StateError('setter failed');

CardBackendLoadSource _source(
  List<String> events, {
  required bool optionalFieldsPresent,
}) {
  int readInt(String name, int value) {
    events.add(name);
    return value;
  }

  T read<T>(String name, T value) {
    events.add(name);
    return value;
  }

  bool has(String name) {
    events.add(name);
    return optionalFieldsPresent;
  }

  return CardBackendLoadSource(
    id: () => readInt('id', 100),
    noteId: () => readInt('noteId', 101),
    deckId: () => readInt('deckId', 102),
    templateIdx: () => readInt('templateIdx', 103),
    mtimeSecs: () => readInt('mtimeSecs', 104),
    usn: () => readInt('usn', 105),
    cardTypeCode: () => readInt('cardTypeCode', 106),
    queueCode: () => readInt('queueCode', 107),
    due: () => readInt('due', 108),
    interval: () => readInt('interval', 109),
    easeFactor: () => readInt('easeFactor', 110),
    reps: () => readInt('reps', 111),
    lapses: () => readInt('lapses', 112),
    remainingSteps: () => readInt('remainingSteps', 113),
    originalDue: () => readInt('originalDue', 114),
    originalDeckId: () => readInt('originalDeckId', 115),
    flags: () => readInt('flags', 116),
    hasOriginalPosition: () => has('hasOriginalPosition'),
    originalPosition: () => readInt('originalPosition', 117),
    customData: () => read('customData', 'data'),
    hasMemoryState: () => has('hasMemoryState'),
    memoryState: () => read('memoryState', 'memory'),
    hasDesiredRetention: () => has('hasDesiredRetention'),
    desiredRetention: () => read('desiredRetention', 0.9),
    hasDecay: () => has('hasDecay'),
    decay: () => read('decay', 0.2),
    hasLastReviewTimeSecs: () => has('hasLastReviewTimeSecs'),
    lastReviewTimeSecs: () => readInt('lastReviewTimeSecs', 118),
  );
}

CardBackendLoadTarget<String, String> _target(
  List<String> events,
  Map<String, Object?> values, {
  String? failOn,
}) {
  void set(String name, Object? value) {
    events.add('set${name[0].toUpperCase()}${name.substring(1)}:$value');
    if (name == failOn) throw _callbackFailure;
    values[name] = value;
  }

  return CardBackendLoadTarget(
    clearRenderOutput: () => events.add('clearRenderOutput'),
    clearCachedNote: () => events.add('clearCachedNote'),
    setId: (value) => set('id', value),
    setNoteId: (value) => set('noteId', value),
    setDeckId: (value) => set('deckId', value),
    setTemplateIdx: (value) => set('templateIdx', value),
    setMtimeSecs: (value) => set('mtimeSecs', value),
    setUsn: (value) => set('usn', value),
    setType: (value) => set('type', value),
    setQueue: (value) => set('queue', value),
    setDue: (value) => set('due', value),
    setInterval: (value) => set('interval', value),
    setEaseFactor: (value) => set('easeFactor', value),
    setReps: (value) => set('reps', value),
    setLapses: (value) => set('lapses', value),
    setRemainingSteps: (value) => set('remainingSteps', value),
    setOriginalDue: (value) => set('originalDue', value),
    setOriginalDeckId: (value) => set('originalDeckId', value),
    setFlags: (value) => set('flags', value),
    setOriginalPosition: (value) => set('originalPosition', value),
    setCustomData: (value) => set('customData', value),
    setMemoryState: (value) => set('memoryState', value),
    setDesiredRetention: (value) => set('desiredRetention', value),
    setDecay: (value) => set('decay', value),
    setLastReviewTimeSecs: (value) => set('lastReviewTimeSecs', value),
  );
}
