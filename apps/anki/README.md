<!--
Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
SPDX-License-Identifier: GPL-3.0-or-later
-->

# Anki Flutter app foundation

This is a neutral Flutter startup shell for Android, iOS, web, Windows, macOS,
and Linux. The existing root `anki_dart` package remains a headless pure Dart
package; `apps/anki` depends on it through a local path dependency. Product
behavior and feature screens have not been implemented in this foundation.

## Development

Use Flutter **3.47.9** with its bundled Dart **3.13.7**. From the repository
root:

```sh
cd apps/anki
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

To run the shell, use `flutter run -d <device>` with a device reported by
`flutter devices`. For example, `flutter run -d chrome` runs the Flutter shell
on web; it does not make the existing root Dart package's platform-dependent
helpers web-compatible.

Build commands are `flutter build apk --debug`, `flutter build web`,
`flutter build linux --debug`, `flutter build windows --debug`,
`flutter build macos --debug`, and `flutter build ios --no-codesign`.

Platform builds need the matching host tooling: Android SDK and JDK for
Android, Xcode on macOS for iOS and macOS, GTK 3 development libraries plus
Clang/CMake/Ninja for Linux, and Visual Studio with the Desktop development
with C++ workload for Windows. GitHub Actions uses matching hosted runners;
Linux installs its GTK and build dependencies in the workflow.
