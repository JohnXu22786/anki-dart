/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
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
 * Source-derived from JsonWriter.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

/// Streaming operations exposed by a host adapter for Android's `JsonWriter`.
///
/// This interface deliberately has no flush or close operation. The caller
/// owns the writer lifecycle, encoding, escaping, and output chunking.
abstract interface class JsonWriterSink {
  void beginObject();

  void endObject();

  void beginArray();

  void endArray();

  void name(String name);

  void nullValue();

  void valueBoolean(bool value);

  /// Receives the original host `Number` value without conversion.
  void valueNumber(Object value);

  void valueString(String value);
}

/// JSON object and array access supplied by the host.
///
/// An Android adapter maps these methods to `JSONObject.keys()`, `get()`,
/// `JSONObject.NULL`, `JSONArray.length()`, and `JSONArray.opt(index)`. It owns
/// key iteration and host container type checks; their failures pass through.
abstract interface class JsonWriterContainerAdapter<
  TObject extends Object,
  TArray extends Object
> {
  Iterable<String> keys(TObject object);

  Object? get(TObject object, String name);

  bool isJsonNull(Object value);

  bool isNumber(Object value);

  bool isObject(Object value);

  TObject asObject(Object value);

  bool isArray(Object value);

  TArray asArray(Object value);

  int arrayLength(TArray array);

  Object? arrayOpt(TArray array, int index);
}

/// Streams one host JSON object through [writer] in source operation order.
///
/// No complete JSON document is materialized. The host supplies object key
/// order and `get` behavior, array `opt` behavior, JSON null identity, and
/// Android `JsonWriter` callbacks through [containers] and [writer].
void writeJsonObject<TObject extends Object, TArray extends Object>(
  JsonWriterSink writer,
  TObject object,
  JsonWriterContainerAdapter<TObject, TArray> containers,
) {
  writer.beginObject();
  for (final key in containers.keys(object)) {
    writer.name(key);
    _writeJsonValue(writer, containers, containers.get(object, key));
  }
  writer.endObject();
}

void _writeJsonValue<TObject extends Object, TArray extends Object>(
  JsonWriterSink writer,
  JsonWriterContainerAdapter<TObject, TArray> containers,
  Object? value,
) {
  if (value == null || containers.isJsonNull(value)) {
    writer.nullValue();
  } else if (containers.isObject(value)) {
    writeJsonObject(writer, containers.asObject(value), containers);
  } else if (containers.isArray(value)) {
    final array = containers.asArray(value);
    writer.beginArray();
    final length = containers.arrayLength(array);
    for (var index = 0; index < length; index++) {
      _writeJsonValue(writer, containers, containers.arrayOpt(array, index));
    }
    writer.endArray();
  } else if (value is bool) {
    writer.valueBoolean(value);
  } else if (containers.isNumber(value)) {
    writer.valueNumber(value);
  } else {
    writer.valueString(value.toString());
  }
}
