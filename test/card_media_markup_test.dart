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
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived assertions for `SoundUtils.expandSounds`; pinned AnkiDroid
 * tests do not directly assert its markup output.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('resolved card media markup', () {
    test('renders the exact audio button with the supplied play reference', () {
      expect(
        cardAudioPlayButtonMarkup(
          showAudioPlayButtons: true,
          side: 'q',
          index: 3,
        ),
        '''<a class="replay-button soundLink" href=playsound:q:3><span>
                        <svg class="playImage" viewBox="0 0 64 64" version="1.1">
                            <circle cx="32" cy="32" r="29" fill="lightgrey"/>
                            <path d="M56.502,32.301l-37.502,20.101l0.329,-40.804l37.173,20.703Z" fill="black"/>Replay
                        </svg>
                    </span></a>''',
      );
    });

    test('suppresses the audio button when the source option is disabled', () {
      expect(
        cardAudioPlayButtonMarkup(
          showAudioPlayButtons: false,
          side: 'a',
          index: 0,
        ),
        '',
      );
    });

    test('renders exact video markup from host-resolved URI and filename', () {
      expect(
        cardVideoTagMarkup(
          side: 'a',
          index: 2,
          uri: 'file:///collection/media/video%20one.mp4',
          htmlEscapedFilename: 'video &amp; one.mp4',
        ),
        '<video\n'
        ' src="file:///collection/media/video%20one.mp4"\n'
        ' controls\n'
        ' data-file="video &amp; one.mp4"\n'
        ' onended=\'window.location.href = "videoended:a:2";\'\n'
        ' onpause=\'if (this.currentTime != this.duration) { window.location.href = "videopause:a:2"; }\'\n'
        ' data-play="a:2" controlsList="nodownload"></video>',
      );
    });
  });
}
