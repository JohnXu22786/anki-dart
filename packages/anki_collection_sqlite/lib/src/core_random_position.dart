// SPDX-License-Identifier: AGPL-3.0-or-later
// Adapted from the algorithms used by rand 0.9.4, rand_core 0.9.3, and
// rand_chacha 0.9.0 under their Apache-2.0/MIT dual license. This implements
// only the ChaCha12/seed/range path used by Anki Core's random_position().

const _u32Mask = 0xffffffff;
final _u64Mask = BigInt.parse('18446744073709551615');

/// Anki Core's `random_position()` using `StdRng::seed_from_u64()` and rand
/// 0.9's `random_range()` behavior.
int coreRandomPosition(int highestPosition) {
  final upperBound = highestPosition < 1000 ? 1000 : highestPosition;
  final range = upperBound - 1;
  final rng = _CoreStdRng(highestPosition);
  final first = rng.nextUint32();
  final product = BigInt.from(first) * BigInt.from(range);
  var result = (product >> 32).toInt();
  final low = (product & BigInt.from(_u32Mask)).toInt();
  if (low > ((_u32Mask + 1) - range)) {
    final second = rng.nextUint32();
    final nextHigh = ((BigInt.from(second) * BigInt.from(range)) >> 32).toInt();
    if (low + nextHigh > _u32Mask) result++;
  }
  return result + 1;
}

final class _CoreStdRng {
  _CoreStdRng(int seed) : _key = _seedWords(seed);

  final List<int> _key;
  int _counter = 0;
  List<int> _words = const [];
  int _index = 0;

  int nextUint32() {
    if (_index >= _words.length) {
      _words = _chacha12Block(_key, _counter++);
      _index = 0;
    }
    return _words[_index++];
  }
}

List<int> _seedWords(int seed) {
  var state = BigInt.from(seed) & _u64Mask;
  final seedBytes = <int>[];
  for (var index = 0; index < 8; index++) {
    state =
        (state * BigInt.parse('6364136223846793005') +
            BigInt.parse('11634580027462260723')) &
        _u64Mask;
    final shifted = (((state >> 18) ^ state) >> 27).toInt() & _u32Mask;
    final rotation = (state >> 59).toInt();
    final value =
        ((shifted >> rotation) | (shifted << ((32 - rotation) & 31))) &
        _u32Mask;
    for (var byte = 0; byte < 4; byte++) {
      seedBytes.add((value >> (byte * 8)) & 0xff);
    }
  }
  return [
    for (var word = 0; word < 8; word++)
      seedBytes[word * 4] |
          (seedBytes[word * 4 + 1] << 8) |
          (seedBytes[word * 4 + 2] << 16) |
          (seedBytes[word * 4 + 3] << 24),
  ];
}

List<int> _chacha12Block(List<int> key, int counter) {
  const constants = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];
  final initial = <int>[
    ...constants,
    ...key,
    counter & _u32Mask,
    (counter >> 32) & _u32Mask,
    0,
    0,
  ];
  final state = List<int>.of(initial);
  for (var round = 0; round < 6; round++) {
    _quarterRound(state, 0, 4, 8, 12);
    _quarterRound(state, 1, 5, 9, 13);
    _quarterRound(state, 2, 6, 10, 14);
    _quarterRound(state, 3, 7, 11, 15);
    _quarterRound(state, 0, 5, 10, 15);
    _quarterRound(state, 1, 6, 11, 12);
    _quarterRound(state, 2, 7, 8, 13);
    _quarterRound(state, 3, 4, 9, 14);
  }
  return [
    for (var index = 0; index < 16; index++)
      (state[index] + initial[index]) & _u32Mask,
  ];
}

void _quarterRound(List<int> state, int a, int b, int c, int d) {
  state[a] = (state[a] + state[b]) & _u32Mask;
  state[d] = _rotateLeft(state[d] ^ state[a], 16);
  state[c] = (state[c] + state[d]) & _u32Mask;
  state[b] = _rotateLeft(state[b] ^ state[c], 12);
  state[a] = (state[a] + state[b]) & _u32Mask;
  state[d] = _rotateLeft(state[d] ^ state[a], 8);
  state[c] = (state[c] + state[d]) & _u32Mask;
  state[b] = _rotateLeft(state[b] ^ state[c], 7);
}

int _rotateLeft(int value, int count) =>
    ((value << count) | (value >> (32 - count))) & _u32Mask;
