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
 * Source mapping: SoundUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Returns AnkiDroid's play-button HTML for a host-resolved audio/TTS tag.
///
/// The host resolves `[anki:play:...]` and supplies its side/index. When
/// `showAudioPlayButtons` is false, the source returns an empty string.
String cardAudioPlayButtonMarkup({
  required bool showAudioPlayButtons,
  required String side,
  required int index,
}) {
  if (!showAudioPlayButtons) return '';

  final playsound = 'playsound:$side:$index';
  return '''<a class="replay-button soundLink" href=$playsound><span>
                        <svg class="playImage" viewBox="0 0 64 64" version="1.1">
                            <circle cx="32" cy="32" r="29" fill="lightgrey"/>
                            <path d="M56.502,32.301l-37.502,20.101l0.329,-40.804l37.173,20.703Z" fill="black"/>Replay
                        </svg>
                    </span></a>''';
}

/// Returns AnkiDroid's `<video>` element for a host-resolved video tag.
///
/// [uri] and [htmlEscapedFilename] must already be resolved by the host, as
/// `expandSounds` obtains a file URI and applies `htmlEncode()` before
/// interpolating them. This fragment does not parse or replace media refs.
String cardVideoTagMarkup({
  required String side,
  required int index,
  required String uri,
  required String htmlEscapedFilename,
}) {
  final playsound = '$side:$index';
  final onEnded = 'window.location.href = "videoended:$playsound";';
  final onPause =
      'if (this.currentTime != this.duration) { window.location.href = '
      '"videopause:$playsound"; }';

  return '<video\n'
      ' src="$uri"\n'
      ' controls\n'
      ' data-file="$htmlEscapedFilename"\n'
      ' onended=\'$onEnded\'\n'
      ' onpause=\'$onPause\'\n'
      ' data-play="$playsound" controlsList="nodownload"></video>';
}
