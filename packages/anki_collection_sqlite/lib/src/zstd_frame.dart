// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'dart:typed_data';

/// Encodes a valid Zstandard frame using raw blocks.
///
/// Raw blocks keep the encoder portable to Dart's JavaScript target while
/// remaining readable by standard Zstandard decoders. Blocks are limited to
/// the format's maximum 128 KiB payload size.
Uint8List encodeZstandardFrame(Uint8List source) {
  final output = BytesBuilder(copy: false);
  output.add(const [0x28, 0xb5, 0x2f, 0xfd]);

  final size = BigInt.from(source.length);
  final int sizeFlag;
  final int sizeWidth;
  final BigInt encodedSize;
  if (source.length < 256) {
    sizeFlag = 0;
    sizeWidth = 1;
    encodedSize = size;
  } else if (source.length < 65792) {
    sizeFlag = 1;
    sizeWidth = 2;
    encodedSize = size - BigInt.from(256);
  } else if (source.length <= 0xffffffff) {
    sizeFlag = 2;
    sizeWidth = 4;
    encodedSize = size;
  } else {
    sizeFlag = 3;
    sizeWidth = 8;
    encodedSize = size;
  }

  // Single segment, no dictionary, no checksum, and an explicit content size.
  output.add([
    0x20 | (sizeFlag << 6),
    ..._littleEndian(encodedSize, sizeWidth),
  ]);

  var offset = 0;
  while (offset < source.length || (source.isEmpty && offset == 0)) {
    final blockLength = (source.length - offset).clamp(0, 128 * 1024);
    final isLast = offset + blockLength == source.length;
    final header = (blockLength << 3) | (isLast ? 1 : 0);
    output.add([header & 0xff, (header >> 8) & 0xff, (header >> 16) & 0xff]);
    if (blockLength > 0) {
      output.add(source.sublist(offset, offset + blockLength));
      offset += blockLength;
    }
    if (isLast) break;
  }

  return output.takeBytes();
}

List<int> _littleEndian(BigInt value, int width) => [
  for (var index = 0; index < width; index++)
    ((value >> (8 * index)) & BigInt.from(0xff)).toInt(),
];
