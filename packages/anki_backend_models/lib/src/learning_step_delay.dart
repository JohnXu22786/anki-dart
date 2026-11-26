// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

/// Resolves the current Learning/Relearning step delay in seconds.
///
/// This follows Anki Core's `LearningSteps::current_delay_secs()`: the
/// remaining-step count selects a step from the end, minutes are rounded to
/// f32 before multiplication, and the resulting f32 seconds are cast to u32.
int resolveCurrentLearningStepDelaySecs({
  required List<double> steps,
  required int remainingSteps,
}) {
  if (steps.isEmpty) return 0;

  final remaining = remainingSteps % 1000;
  final index = (steps.length - remaining).clamp(0, steps.length - 1);
  final minutes = _toFloat32(steps[index]);
  final seconds = _toFloat32(minutes * 60.0);

  // Rust's float-to-u32 cast saturates, unlike Dart's toInt() behavior for
  // non-finite and out-of-range values.
  if (seconds.isNaN || seconds <= 0) return 0;
  if (!seconds.isFinite || seconds >= 0xffffffff) return 0xffffffff;
  return seconds.toInt();
}

double _toFloat32(double value) => (Float32List(1)..[0] = value)[0];
