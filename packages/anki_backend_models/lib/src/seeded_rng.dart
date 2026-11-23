// SPDX-License-Identifier: AGPL-3.0-or-later
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
  return _SeededStdRng(seed).takeWords(count);
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

class _SeededStdRng {
  _SeededStdRng(BigInt seed) : _key = _expandSeed(seed);

  final List<int> _key;
  List<int> _words = [];
  int _index = 0;
  int _block = 0;

  List<int> takeWords(int count) {
    final result = <int>[];
    while (result.length < count) {
      if (_index == _words.length) {
        _words = _chacha12Words(_key, block: _block++);
        _index = 0;
      }
      result.add(_words[_index++]);
    }
    return result;
  }
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

List<int> _chacha12Words(List<int> seedWords, {int block = 0}) {
  final state = <int>[
    0x61707865,
    0x3320646e,
    0x79622d32,
    0x6b206574,
    ...seedWords,
    block & _wordMask,
    (block >> 32) & _wordMask,
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
