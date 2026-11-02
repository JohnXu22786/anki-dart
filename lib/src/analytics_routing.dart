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
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from Analytics.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'analytics_event.dart';

/// Opt-in usage analytics, implemented by the application host.
///
/// Android context, consent storage, and analytics backends remain host-side.
abstract class UsageAnalytics {
  /// Key used by the host to persist the user's analytics opt-in.
  static const analyticsOptInKey = 'analytics_opt_in_v2';

  /// Reports [event].
  void send(AnalyticsEvent event);

  /// Records a screen view under [screenName].
  void sendAnalyticsScreenView(String screenName);

  /// Records a screen view named after [screen]'s host-provided class name.
  ///
  /// Dart has no portable equivalent of Java's `Class.simpleName`, so the host
  /// provides [simpleClassName].
  void sendAnalyticsScreenViewObject(
    Object screen, {
    required String Function(Object screen) simpleClassName,
  }) {
    sendAnalyticsScreenView(simpleClassName(screen));
  }

  /// Reports the root cause of [exception].
  void sendAnalyticsException(Object exception, {required bool fatal});
}

/// Dispatches analytics through the implementation registered at startup.
///
/// Calls made before [setAnalytics] are safely dropped. The singleton has no
/// reset operation, matching the source contract.
final class Analytics {
  Analytics._();

  static UsageAnalytics _instance = _UnregisteredUsageAnalytics();

  /// Registers the host's analytics implementation.
  static void setAnalytics(UsageAnalytics analytics) {
    _instance = analytics;
  }

  /// Sends an analytics [event].
  static void send(AnalyticsEvent event) => _instance.send(event);

  /// Records a screen view under an explicit [screenName].
  static void sendAnalyticsScreenView(String screenName) =>
      _instance.sendAnalyticsScreenView(screenName);

  /// Records a screen view using the host-provided simple class name.
  static void sendAnalyticsScreenViewObject(
    Object screen, {
    required String Function(Object screen) simpleClassName,
  }) => _instance.sendAnalyticsScreenViewObject(
    screen,
    simpleClassName: simpleClassName,
  );

  /// Reports the root cause of [exception].
  static void sendAnalyticsException(Object exception, {required bool fatal}) =>
      _instance.sendAnalyticsException(exception, fatal: fatal);
}

final class _UnregisteredUsageAnalytics extends UsageAnalytics {
  @override
  void send(AnalyticsEvent event) {}

  @override
  void sendAnalyticsScreenView(String screenName) {}

  @override
  void sendAnalyticsScreenViewObject(
    Object screen, {
    required String Function(Object screen) simpleClassName,
  }) {}

  @override
  void sendAnalyticsException(Object exception, {required bool fatal}) {}
}
