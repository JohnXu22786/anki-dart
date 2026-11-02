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
 * Behavioral reference: `fetchSyncIconState` and `SyncIconState` in
 * DeckPickerViewModel.kt, AnkiDroid 2.25.3; see ANKIDROID_UPSTREAM.md.
 */

/// Sync icon states exposed by AnkiDroid's Deck Picker.
enum DeckPickerSyncIconState { normal, pendingChanges, oneWay, notLoggedIn }

/// The result of the host's sync-auth lookup.
enum DeckPickerSyncAuthState { notChecked, available, unavailable }

/// Required states in the backend sync-status response.
///
/// [unrecognized] represents the generated backend enum's UNRECOGNIZED value.
enum DeckPickerSyncRequiredStatus {
  noChanges,
  normalSync,
  fullSync,
  unrecognized,
}

/// The host's source-ordered auth and backend request decisions.
final class DeckPickerSyncIconFetchPlan {
  const DeckPickerSyncIconFetchPlan({
    required this.shouldLookupAuth,
    required this.shouldRequestStatus,
    required this.finalState,
  });

  /// Whether the host should perform `syncAuth()` next.
  final bool shouldLookupAuth;

  /// Whether the host should query the backend after auth is available.
  final bool shouldRequestStatus;

  /// A terminal icon state when the source returns before querying the backend.
  final DeckPickerSyncIconState? finalState;
}

/// Plans the source's display-status and sync-auth gates.
///
/// The host should call `syncAuth()` only when [shouldLookupAuth] is true, then
/// re-plan with its result. It should call the backend only when
/// [shouldRequestStatus] is true.
DeckPickerSyncIconFetchPlan planDeckPickerSyncIconFetch({
  required bool displaySyncStatus,
  required DeckPickerSyncAuthState authState,
}) {
  if (!displaySyncStatus) {
    return const DeckPickerSyncIconFetchPlan(
      shouldLookupAuth: false,
      shouldRequestStatus: false,
      finalState: DeckPickerSyncIconState.normal,
    );
  }

  switch (authState) {
    case DeckPickerSyncAuthState.notChecked:
      return const DeckPickerSyncIconFetchPlan(
        shouldLookupAuth: true,
        shouldRequestStatus: false,
        finalState: null,
      );
    case DeckPickerSyncAuthState.unavailable:
      return const DeckPickerSyncIconFetchPlan(
        shouldLookupAuth: false,
        shouldRequestStatus: false,
        finalState: DeckPickerSyncIconState.notLoggedIn,
      );
    case DeckPickerSyncAuthState.available:
      return const DeckPickerSyncIconFetchPlan(
        shouldLookupAuth: false,
        shouldRequestStatus: true,
        finalState: null,
      );
  }
}

/// A source-ordered effect from a successful sync-status response.
sealed class DeckPickerSyncIconEffect {
  const DeckPickerSyncIconEffect();
}

/// Requests persistence of the backend's newly advertised sync endpoint.
final class PersistDeckPickerSyncEndpointEffect
    extends DeckPickerSyncIconEffect {
  const PersistDeckPickerSyncEndpointEffect(this.endpoint);

  final String endpoint;

  @override
  bool operator ==(Object other) =>
      other is PersistDeckPickerSyncEndpointEffect &&
      other.endpoint == endpoint;

  @override
  int get hashCode => endpoint.hashCode;
}

/// Publishes the resulting Deck Picker sync icon state.
final class SetDeckPickerSyncIconEffect extends DeckPickerSyncIconEffect {
  const SetDeckPickerSyncIconEffect(this.state);

  final DeckPickerSyncIconState state;

  @override
  bool operator ==(Object other) =>
      other is SetDeckPickerSyncIconEffect && other.state == state;

  @override
  int get hashCode => state.hashCode;
}

/// The host-adapted result of the backend status request.
sealed class DeckPickerSyncStatusResponse {
  const DeckPickerSyncStatusResponse();
}

/// A successful response, including the backend's required status and endpoint.
final class DeckPickerSyncStatusSuccess extends DeckPickerSyncStatusResponse {
  const DeckPickerSyncStatusSuccess({
    required this.requiredStatus,
    this.hasNewEndpoint = false,
    this.newEndpoint = '',
  });

  final DeckPickerSyncRequiredStatus? requiredStatus;
  final bool hasNewEndpoint;
  final String newEndpoint;
}

/// A backend exception caught by the source's Exception handlers.
final class DeckPickerSyncStatusFailure extends DeckPickerSyncStatusResponse {
  const DeckPickerSyncStatusFailure();
}

/// Projects a backend result into the source's ordered endpoint and icon work.
///
/// The host handles the backend call and translates exceptions caught by the
/// source into [DeckPickerSyncStatusFailure]. Those caught exceptions return
/// the Normal icon. A null or unrecognized required status instead reproduces
/// the source `TODO("unexpected required response")` as [UnimplementedError],
/// which is an [Error] and must not be converted to the caught-exception
/// fallback. This is a lazy iterable: the host must apply each yielded effect
/// before requesting the next, so an endpoint update is applied before status
/// mapping can throw on an unrecognized response.
Iterable<DeckPickerSyncIconEffect> projectDeckPickerSyncIconResponse(
  DeckPickerSyncStatusResponse response,
) sync* {
  if (response is DeckPickerSyncStatusFailure) {
    yield const SetDeckPickerSyncIconEffect(DeckPickerSyncIconState.normal);
    return;
  }

  final success = response as DeckPickerSyncStatusSuccess;
  if (success.hasNewEndpoint && success.newEndpoint.isNotEmpty) {
    yield PersistDeckPickerSyncEndpointEffect(success.newEndpoint);
  }

  final state = switch (success.requiredStatus) {
    DeckPickerSyncRequiredStatus.noChanges => DeckPickerSyncIconState.normal,
    DeckPickerSyncRequiredStatus.normalSync =>
      DeckPickerSyncIconState.pendingChanges,
    DeckPickerSyncRequiredStatus.fullSync => DeckPickerSyncIconState.oneWay,
    DeckPickerSyncRequiredStatus.unrecognized ||
    null => throw UnimplementedError('unexpected required response'),
  };
  yield SetDeckPickerSyncIconEffect(state);
}
