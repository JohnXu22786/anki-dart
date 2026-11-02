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
 * SPDX-FileCopyrightText: 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 * SPDX-FileCopyrightText: 2024 Ashish Yadav <mailtoashish693@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from MultimediaViewModel.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Portable value state from AnkiDroid's `MultimediaViewModel`.
///
/// [UriValue] and [PathValue] are opaque host values, so this state does not
/// parse URIs or construct platform paths. The host retains SharedFlow action
/// emission and coroutines, String-to-File conversion, Android media/file/URI
/// operations, lifecycle, and UI.
final class MultimediaViewModelState<
  UriValue extends Object,
  PathValue extends Object
> {
  UriValue? _currentMultimediaUri;
  PathValue? _currentMultimediaPath;

  UriValue? _previousMultimediaUri;
  PathValue? _previousMultimediaPath;

  UriValue? get currentMultimediaUri => _currentMultimediaUri;

  PathValue? get currentMultimediaPath => _currentMultimediaPath;

  int selectedMediaFileSize = 0;

  /// Saves the supplied host values unchanged, in source argument order.
  void saveMultimediaForRevert(PathValue? imagePath, UriValue? imageUri) {
    _previousMultimediaPath = imagePath;
    _previousMultimediaUri = imageUri;
  }

  /// Restores the saved URI and then path, preserving their exact values.
  void restoreMultimedia() {
    _currentMultimediaUri = _previousMultimediaUri;
    _currentMultimediaPath = _previousMultimediaPath;
  }

  /// Stores the supplied signed media length without conversion.
  void updateMediaFileLength(int length) {
    selectedMediaFileSize = length;
  }

  /// Stores the supplied host URI value unchanged.
  void updateCurrentMultimediaUri(UriValue? uri) {
    _currentMultimediaUri = uri;
  }

  /// Stores the supplied host path value unchanged.
  void updateCurrentMultimediaPath(PathValue? path) {
    _currentMultimediaPath = path;
  }
}
