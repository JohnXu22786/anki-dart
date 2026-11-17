// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

const _iv = <int>[
  0x6a09e667,
  0xbb67ae85,
  0x3c6ef372,
  0xa54ff53a,
  0x510e527f,
  0x9b05688c,
  0x1f83d9ab,
  0x5be0cd19,
];
const _permutation = <int>[
  2,
  6,
  3,
  10,
  7,
  0,
  4,
  13,
  1,
  11,
  12,
  5,
  9,
  14,
  15,
  8
];
const _chunkStart = 1;
const _chunkEnd = 2;
const _parent = 4;
const _root = 8;
const _mask = 0xffffffff;

/// First eight bytes of a BLAKE3 digest, formatted as lowercase hex.
String blake3Prefix64Hex(String input) =>
    blake3Prefix64HexBytes(utf8.encode(input));

/// First eight bytes of a BLAKE3 digest for raw input bytes, formatted as hex.
String blake3Prefix64HexBytes(List<int> bytes) {
  final chunks = <_Output>[];
  for (var offset = 0; offset < bytes.length; offset += 1024) {
    final end = (offset + 1024).clamp(0, bytes.length);
    chunks.add(_chunkOutput(bytes.sublist(offset, end), chunks.length));
  }
  if (chunks.isEmpty) chunks.add(_chunkOutput(const [], 0));

  final stack = <List<int>>[];
  for (var index = 0; index < chunks.length - 1; index++) {
    var cv = chunks[index].chainingValue();
    var totalChunks = index + 1;
    while (totalChunks.isEven) {
      cv = _parentOutput(stack.removeLast(), cv).chainingValue();
      totalChunks >>= 1;
    }
    stack.add(cv);
  }
  var output = chunks.last;
  while (stack.isNotEmpty) {
    output = _parentOutput(stack.removeLast(), output.chainingValue());
  }
  final words = _compress(
    output.chainingValueInput,
    output.blockWords,
    0,
    output.blockLength,
    output.flags | _root,
  );
  final digestBytes = <int>[];
  for (final word in words.take(2)) {
    digestBytes
      ..add(word & 0xff)
      ..add((word >> 8) & 0xff)
      ..add((word >> 16) & 0xff)
      ..add((word >> 24) & 0xff);
  }
  return digestBytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

_Output _chunkOutput(List<int> chunk, int counter) {
  var cv = List<int>.of(_iv);
  final blocks = <List<int>>[];
  for (var offset = 0; offset < chunk.length; offset += 64) {
    blocks.add(chunk.sublist(offset, (offset + 64).clamp(0, chunk.length)));
  }
  if (blocks.isEmpty) blocks.add(const []);
  for (var index = 0; index < blocks.length - 1; index++) {
    final words = _blockWords(blocks[index]);
    cv = _compress(
      cv,
      words,
      counter,
      64,
      index == 0 ? _chunkStart : 0,
    ).take(8).toList(growable: false);
  }
  final last = blocks.last;
  return _Output(
    cv,
    _blockWords(last),
    counter,
    last.length,
    _chunkEnd | (blocks.length == 1 ? _chunkStart : 0),
  );
}

_Output _parentOutput(List<int> left, List<int> right) => _Output(
      List<int>.of(_iv),
      [...left, ...right],
      0,
      64,
      _parent,
    );

List<int> _blockWords(List<int> bytes) => List<int>.generate(16, (word) {
      final offset = word * 4;
      var value = 0;
      for (var byte = 0; byte < 4 && offset + byte < bytes.length; byte++) {
        value |= bytes[offset + byte] << (byte * 8);
      }
      return value;
    }, growable: false);

List<int> _compress(
    List<int> cv, List<int> block, int counter, int length, int flags) {
  var state = <int>[
    ...cv,
    ..._iv.take(4),
    counter & _mask,
    (counter >> 32) & _mask,
    length,
    flags,
  ];
  var message = List<int>.of(block);
  for (var round = 0; round < 7; round++) {
    _round(state, message);
    if (round < 6) message = [for (final index in _permutation) message[index]];
  }
  return [
    for (var index = 0; index < 8; index++)
      (state[index] ^ state[index + 8]) & _mask,
    for (var index = 0; index < 8; index++)
      (state[index + 8] ^ cv[index]) & _mask,
  ];
}

void _round(List<int> s, List<int> m) {
  _g(s, 0, 4, 8, 12, m[0], m[1]);
  _g(s, 1, 5, 9, 13, m[2], m[3]);
  _g(s, 2, 6, 10, 14, m[4], m[5]);
  _g(s, 3, 7, 11, 15, m[6], m[7]);
  _g(s, 0, 5, 10, 15, m[8], m[9]);
  _g(s, 1, 6, 11, 12, m[10], m[11]);
  _g(s, 2, 7, 8, 13, m[12], m[13]);
  _g(s, 3, 4, 9, 14, m[14], m[15]);
}

void _g(List<int> s, int a, int b, int c, int d, int x, int y) {
  s[a] = (s[a] + s[b] + x) & _mask;
  s[d] = _rotr(s[d] ^ s[a], 16);
  s[c] = (s[c] + s[d]) & _mask;
  s[b] = _rotr(s[b] ^ s[c], 12);
  s[a] = (s[a] + s[b] + y) & _mask;
  s[d] = _rotr(s[d] ^ s[a], 8);
  s[c] = (s[c] + s[d]) & _mask;
  s[b] = _rotr(s[b] ^ s[c], 7);
}

int _rotr(int value, int amount) =>
    ((value >> amount) | (value << (32 - amount))) & _mask;

final class _Output {
  const _Output(this.chainingValueInput, this.blockWords, this.counter,
      this.blockLength, this.flags);
  final List<int> chainingValueInput;
  final List<int> blockWords;
  final int counter;
  final int blockLength;
  final int flags;

  List<int> chainingValue() =>
      _compress(chainingValueInput, blockWords, counter, blockLength, flags)
          .take(8)
          .toList(growable: false);
}
