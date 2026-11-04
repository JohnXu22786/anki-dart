/*
 * Copyright (c) 2011 Kostas Spyropoulos <inigo.aldana@gmail.com>
 * Copyright (c) 2014 Houssam Salem <houssam.salem.au@gmail.com>
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
 * SPDX-FileCopyrightText: 2011 Kostas Spyropoulos
 * SPDX-FileCopyrightText: 2014 Houssam Salem
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Media.kt in AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

final class _Card {}

final class _Note {}

final class _Model {}

final class _Output {
  const _Output(
    this.questionText,
    this.answerText,
    this.questionAvTags,
    this.answerAvTags,
  );

  final String questionText;
  final String answerText;
  final List<Object> questionAvTags;
  final List<Object> answerAvTags;
}

final class _SoundTag implements _MediaTag {
  const _SoundTag(this.filename);

  final String filename;
}

final class _OtherTag implements _MediaTag {
  const _OtherTag();
}

sealed class _MediaTag {}

List<String> _files(
  String text, {
  bool includeRemote = false,
  List<Object> questionTags = const [],
  List<Object> answerTags = const [],
  List<String>? calls,
  String Function(String, _Model, Object)? latex,
}) {
  final card = _Card();
  final collection = Object();
  final note = _Note();
  final model = _Model();
  final output = _Output(text, '', questionTags, answerTags);
  return Media.filesInStr<_Card, Object, _Note, _Model, _Output, Object>(
    card,
    collection: collection,
    includeRemote: includeRemote,
    note: (value, col) {
      calls?.add('note');
      expect(identical(value, card), isTrue);
      expect(identical(col, collection), isTrue);
      return note;
    },
    notetype: (value) {
      calls?.add('notetype');
      expect(identical(value, note), isTrue);
      return model;
    },
    renderOutput: (value, col) {
      calls?.add('renderOutput');
      expect(identical(value, card), isTrue);
      expect(identical(col, collection), isTrue);
      return output;
    },
    questionText: (value) {
      calls?.add('questionText');
      return value.questionText;
    },
    answerText: (value) {
      calls?.add('answerText');
      return value.answerText;
    },
    renderLatex: (value, exactModel, col) {
      calls?.add('renderLatex');
      expect(identical(exactModel, model), isTrue);
      expect(identical(col, collection), isTrue);
      return latex?.call(value, exactModel, col) ?? value;
    },
    questionAvTags: (value) {
      calls?.add('questionAvTags');
      return value.questionAvTags;
    },
    answerAvTags: (value) {
      calls?.add('answerAvTags');
      return value.answerAvTags;
    },
    isSoundOrVideoTag: (value) {
      calls?.add('isSoundOrVideoTag:${value.runtimeType}');
      return value is _SoundTag;
    },
    soundOrVideoFilename: (value) {
      calls?.add('filename:${(value as _SoundTag).filename}');
      return (value as _SoundTag).filename;
    },
  );
}

void main() {
  group('Media.filesInStr', () {
    test(
      'matches quoted and unquoted src/data case-insensitively in source order',
      () {
        expect(
          _files('''
<IMG SRC="quoted-a.png"><audio src='quoted-b.mp3'>
<SOURCE SRC=bare-c.ogg><OBJECT DATA="quoted-d.bin">
<OBJECT DATA=bare-e.bin>
'''),
          [
            'quoted-a.png',
            'quoted-b.mp3',
            'bare-c.ogg',
            'quoted-d.bin',
            'bare-e.bin',
          ],
        );
        expect(Media.htmlMediaRegexps, hasLength(4));
      },
    );

    test(
      'uses ordered patterns before match order and reads capture group values',
      () {
        expect(
          _files('''
<img src="first.png"><object data="first-object.bin"><img src="second.png">
<object data=second-object.bin><img src=third.png>
'''),
          [
            'first.png',
            'second.png',
            'third.png',
            'first-object.bin',
            'second-object.bin',
          ],
        );
      },
    );

    test(
      'filters remote URL substrings by default and preserves first distinct occurrence',
      () {
        const text =
            '<img src="a.png"><img src="a.png">'
            '<img src="HTTPS://host/a.png"><img src=ftp://host/b.png>'
            '<object data="http://host/c.bin">';
        expect(_files(text), ['a.png']);
        expect(_files(text, includeRemote: true), [
          'a.png',
          'HTTPS://host/a.png',
          'ftp://host/b.png',
          'http://host/c.bin',
        ]);
      },
    );

    test(
      'appends only sound/video AV tags, question before answer, then distincts',
      () {
        expect(
          _files(
            '<img src="same.mp3">',
            questionTags: [
              const _OtherTag(),
              const _SoundTag('q.mp3'),
              const _SoundTag('same.mp3'),
            ],
            answerTags: [
              const _SoundTag('a.mp3'),
              const _OtherTag(),
              const _SoundTag('q.mp3'),
            ],
          ),
          ['same.mp3', 'q.mp3', 'a.mp3'],
        );
      },
    );

    test('checks every AV tag before reading any sound/video filename', () {
      final calls = <String>[];
      expect(
        _files(
          '',
          questionTags: [const _SoundTag('q.mp3'), const _OtherTag()],
          answerTags: [const _SoundTag('a.mp3')],
          calls: calls,
        ),
        ['q.mp3', 'a.mp3'],
      );
      expect(calls, [
        'note',
        'notetype',
        'renderOutput',
        'questionText',
        'answerText',
        'renderLatex',
        'questionAvTags',
        'answerAvTags',
        'isSoundOrVideoTag:_SoundTag',
        'isSoundOrVideoTag:_OtherTag',
        'isSoundOrVideoTag:_SoundTag',
        'filename:q.mp3',
        'filename:a.mp3',
      ]);
    });

    test('calls card, rendering and AV callbacks once in source order', () {
      final calls = <String>[];
      final output =
          Media.filesInStr<_Card, Object, _Note, _Model, _Output, Object>(
            _Card(),
            collection: Object(),
            note: (_, _) {
              calls.add('note');
              return _Note();
            },
            notetype: (_) {
              calls.add('notetype');
              return _Model();
            },
            renderOutput: (_, _) {
              calls.add('renderOutput');
              return const _Output('question', 'answer', [], []);
            },
            questionText: (value) {
              calls.add('questionText');
              return value.questionText;
            },
            answerText: (value) {
              calls.add('answerText');
              return value.answerText;
            },
            renderLatex: (text, _, _) {
              calls.add('renderLatex:$text');
              return '<img src="latex.png">';
            },
            questionAvTags: (value) {
              calls.add('questionAvTags');
              return value.questionAvTags;
            },
            answerAvTags: (value) {
              calls.add('answerAvTags');
              return value.answerAvTags;
            },
            isSoundOrVideoTag: (_) => false,
            soundOrVideoFilename: (_) => fail('no tag filename expected'),
          );

      expect(output, ['latex.png']);
      expect(calls, [
        'note',
        'notetype',
        'renderOutput',
        'questionText',
        'answerText',
        'renderLatex:questionanswer',
        'questionAvTags',
        'answerAvTags',
      ]);
    });

    test('propagates callback errors unchanged and stops later callbacks', () {
      final error = StateError('notetype failed');
      final calls = <String>[];
      expect(
        () => Media.filesInStr<_Card, Object, _Note, _Model, _Output, Object>(
          _Card(),
          collection: Object(),
          note: (_, _) {
            calls.add('note');
            return _Note();
          },
          notetype: (_) {
            calls.add('notetype');
            throw error;
          },
          renderOutput: (_, _) {
            calls.add('renderOutput');
            return const _Output('', '', [], []);
          },
          questionText: (_) => fail('question text after error'),
          answerText: (_) => fail('answer text after error'),
          renderLatex: (_, _, _) => fail('latex after error'),
          questionAvTags: (_) => fail('AV tags after error'),
          answerAvTags: (_) => fail('AV tags after error'),
          isSoundOrVideoTag: (_) => false,
          soundOrVideoFilename: (_) => fail('filename after error'),
        ),
        throwsA(same(error)),
      );
      expect(calls, ['note', 'notetype']);
    });
  });
}
