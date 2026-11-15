/*
 * Copyright (c) 2009 Edu Zamora <edu.zasu@gmail.com>
 * Copyright (c) 2014 Timothy rae <perceptualchaos2@gmail.com>
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
 * SPDX-FileCopyrightText: 2009 Edu Zamora
 * SPDX-FileCopyrightText: 2014 Timothy rae
 * SPDX-FileCopyrightText: 2026 John Tsui
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from SoundUtils.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// The media kind selected by AnkiDroid's `SoundOrVideoTag.getTagType()`.
enum CardMediaTagType { audio, video }

/// Projects the source's tag-kind decision from host supplied file facts.
///
/// [extension] is the case-sensitive extension after the last period, as
/// returned by the host `File.extension`. The extension sets are also supplied
/// by the host, keeping the upstream `Sound` constants outside this port.
/// Existence is queried only for audio/video containers. Thumbnail detection is
/// queried only when such a file exists. The source treats a definite lack of a
/// video thumbnail as audio-only; a present or unknown thumbnail result selects
/// video.
CardMediaTagType cardMediaTagType({
  required String extension,
  required Set<String> videoOnlyExtensions,
  required Set<String> audioOrVideoExtensions,
  required bool Function() fileExists,
  required bool? Function() hasVideoThumbnail,
}) {
  if (videoOnlyExtensions.contains(extension)) return CardMediaTagType.video;

  if (audioOrVideoExtensions.contains(extension)) {
    if (!fileExists()) return CardMediaTagType.video;
    return hasVideoThumbnail() == false
        ? CardMediaTagType.audio
        : CardMediaTagType.video;
  }

  // Unknown extensions are assumed to be audio because the HTML audio path is
  // more resilient than HTML video playback.
  return CardMediaTagType.audio;
}
