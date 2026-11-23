// SPDX-License-Identifier: AGPL-3.0-or-later
/// Applies Core's short-term FSRS option rule to a global FSRS setting and
/// already-resolved deck parameter list.
bool allowsFsrsShortTerm({
  required bool fsrsEnabled,
  required List<double> params,
}) {
  if (!fsrsEnabled) return false;
  if (params.length >= 19) return params[17] > 0.0 && params[18] > 0.0;
  return params.isEmpty;
}
