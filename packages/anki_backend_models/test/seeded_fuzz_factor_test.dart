// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  test('matches pinned rand 0.9.4 f32 random_range reference vectors', () {
    // Reference vectors use StdRng::seed_from_u64() from rand 0.9.4,
    // rand_chacha 0.9.0, and rand_core 0.9.3. The samples exercise several
    // high-23-bit mantissas, including the zero seed and a near-one sample.
    expect(seededStdRngFuzzFactor(BigInt.zero), 0.8014591932296753);
    expect(seededStdRngFuzzFactor(BigInt.one), 0.8249526023864746);
    expect(seededStdRngFuzzFactor(BigInt.from(58205158)), 0.9099999666213989);
    expect(
      seededStdRngFuzzFactor(BigInt.parse('ffffffffffffffff', radix: 16)),
      0.1806238889694214,
    );
  });

  test('rejects seeds outside the pinned u64 range', () {
    expect(() => seededStdRngFuzzFactor(BigInt.from(-1)), throwsArgumentError);
    expect(() => seededStdRngFuzzFactor(BigInt.one << 64), throwsArgumentError);
  });
}
