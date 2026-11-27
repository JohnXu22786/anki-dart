// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

/// Returns words from the pinned rand 0.9.4 StdRng stream.
///
/// This package reproduces rand_core 0.9.3's `seed_from_u64` expansion and
/// rand_chacha 0.9.0's ChaCha12 stream. StdRng is version-sensitive, so this
/// helper intentionally describes those pinned versions only.
List<int> seededStdRngWords(BigInt seed, {int count = 1}) {
  _validateSeed(seed);
  if (count < 0) {
    throw ArgumentError.value(count, 'count', 'must be nonnegative');
  }
  return SeededStdRng(seed).takeWords(count);
}

/// Stateful rand 0.9.4 `StdRng` word stream for package-internal adapters.
///
/// This reuses the pinned rand_core 0.9.3 seed expansion and rand_chacha 0.9.0
/// ChaCha12 implementation used by the stateless helpers in this file.
class SeededStdRng {
  SeededStdRng(
    BigInt seed, {
    int blockLow = 0,
    int blockHigh = 0,
  })  : _key = _expandSeed(_validatedSeed(seed)),
        _blockLow = _validateBlockWord(blockLow, 'blockLow'),
        _blockHigh = _validateBlockWord(blockHigh, 'blockHigh');

  final List<int> _key;
  List<int> _words = [];
  int _index = 0;
  int _blockLow;
  int _blockHigh;

  int nextWord() {
    if (_index == _words.length) {
      _words = _chacha12Words(
        _key,
        blockLow: _blockLow,
        blockHigh: _blockHigh,
      );
      _blockLow = (_blockLow + 1) & _wordMask;
      if (_blockLow == 0) _blockHigh = (_blockHigh + 1) & _wordMask;
      _index = 0;
    }
    return _words[_index++];
  }

  List<int> takeWords(int count) =>
      List<int>.generate(count, (_) => nextWord(), growable: false);
}

/// Returns rand 0.9.4's seeded `random_range(0.0f32..1.0f32)` sample.
///
/// `UniformFloat<f32>::sample_single_inclusive()` discards the low nine bits
/// of one generated word, inserts the remaining 23 bits into a `[1, 2)` f32,
/// then subtracts one. The constructed fraction is exactly representable as
/// f32, so the subtraction preserves Core's Float32 rounding.
double seededStdRngFuzzFactor(BigInt seed) {
  _validateSeed(seed);
  final mantissa = seededStdRngWords(seed).single >> 9;
  final floatBits = 0x3f800000 | mantissa;
  final bytes = ByteData(4)..setUint32(0, floatBits, Endian.little);
  return bytes.getFloat32(0, Endian.little) - 1.0;
}

const _wordMask = 0xffffffff;
final _u64Mask = BigInt.parse('ffffffffffffffff', radix: 16);
final _pcgMultiplier = BigInt.parse('5851f42d4c957f2d', radix: 16);
final _pcgIncrement = BigInt.parse('a17654e46fbe17f3', radix: 16);

void _validateSeed(BigInt seed) {
  if (seed < BigInt.zero || seed > _u64Mask) {
    throw ArgumentError.value(
      seed,
      'seed',
      'must fit in an unsigned 64-bit integer',
    );
  }
}

BigInt _validatedSeed(BigInt seed) {
  _validateSeed(seed);
  return seed;
}

int _validateBlockWord(int word, String name) {
  if (word < 0 || word > _wordMask) {
    throw ArgumentError.value(
        word, name, 'must fit in an unsigned 32-bit word');
  }
  return word;
}

/// Samples from `0..bound` using rand 0.9.4's default biased Canon sampler.
///
/// `IncreasingUniform` uses this `u32 random_range` path to create each
/// factorial chunk. Keep the extra-word correction exactly aligned with the
/// pinned rand source; it is deliberately not replaced by modulo sampling.
int rand094RandomRangeU32(int bound, int Function() nextWord) {
  if (bound < 1 || bound > _wordMask) {
    throw ArgumentError.value(bound, 'bound', 'must be in 1..u32::MAX');
  }
  final (result, low) = _multiplyU32(nextWord(), bound);
  var sample = result;
  final threshold = (-bound) & _wordMask;
  if (low > threshold) {
    final (correctionHigh, _) = _multiplyU32(nextWord(), bound);
    if (low + correctionHigh > _wordMask) sample++;
  }
  return sample;
}

/// Exact 32-by-32 widening multiplication using 16-bit limbs.
///
/// Keeping each intermediate below 2^53 also preserves exact integer results
/// when this package is compiled to JavaScript.
(int, int) _multiplyU32(int left, int right) {
  final leftLow = left & 0xffff;
  final leftHigh = left >> 16;
  final rightLow = right & 0xffff;
  final rightHigh = right >> 16;
  final lowProduct = leftLow * rightLow;
  final crossA = leftHigh * rightLow;
  final crossB = leftLow * rightHigh;
  final highProduct = leftHigh * rightHigh;
  final middle = (lowProduct >> 16) + (crossA & 0xffff) + (crossB & 0xffff);
  final low = ((middle & 0xffff) << 16) | (lowProduct & 0xffff);
  final high = highProduct + (crossA >> 16) + (crossB >> 16) + (middle >> 16);
  return (high, low);
}

List<int> _expandSeed(BigInt seed) {
  var state = seed;
  final words = <int>[];
  for (var i = 0; i < 8; i++) {
    state = (state * _pcgMultiplier + _pcgIncrement) & _u64Mask;
    final xorshifted =
        ((((state >> 18) ^ state) >> 27) & BigInt.from(_wordMask)).toInt();
    final rotation = (state >> 59).toInt();
    final word = _rotateRight32(xorshifted, rotation);
    words.add(word & _wordMask);
  }
  return words;
}

List<int> _chacha12Words(
  List<int> seedWords, {
  required int blockLow,
  required int blockHigh,
}) {
  final state = <int>[
    0x61707865,
    0x3320646e,
    0x79622d32,
    0x6b206574,
    ...seedWords,
    blockLow,
    blockHigh,
    0,
    0,
  ];
  final working = List<int>.of(state);
  for (var round = 0; round < 6; round++) {
    _quarterRound(working, 0, 4, 8, 12);
    _quarterRound(working, 1, 5, 9, 13);
    _quarterRound(working, 2, 6, 10, 14);
    _quarterRound(working, 3, 7, 11, 15);
    _quarterRound(working, 0, 5, 10, 15);
    _quarterRound(working, 1, 6, 11, 12);
    _quarterRound(working, 2, 7, 8, 13);
    _quarterRound(working, 3, 4, 9, 14);
  }
  return [for (var i = 0; i < 16; i++) (working[i] + state[i]) & _wordMask];
}

void _quarterRound(List<int> state, int a, int b, int c, int d) {
  state[a] = (state[a] + state[b]) & _wordMask;
  state[d] = _rotateLeft32(state[d] ^ state[a], 16);
  state[c] = (state[c] + state[d]) & _wordMask;
  state[b] = _rotateLeft32(state[b] ^ state[c], 12);
  state[a] = (state[a] + state[b]) & _wordMask;
  state[d] = _rotateLeft32(state[d] ^ state[a], 8);
  state[c] = (state[c] + state[d]) & _wordMask;
  state[b] = _rotateLeft32(state[b] ^ state[c], 7);
}

int _rotateLeft32(int value, int amount) =>
    ((value << amount) | (value >> (32 - amount))) & _wordMask;

int _rotateRight32(int value, int amount) {
  if (amount == 0) return value & _wordMask;
  return ((value >> amount) | (value << (32 - amount))) & _wordMask;
}
