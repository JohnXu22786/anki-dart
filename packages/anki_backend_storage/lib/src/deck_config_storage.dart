// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:anki_backend_protocol/anki/deck_config.pb.dart' as proto;
import 'package:fixnum/fixnum.dart';

/// The portable SQL query surface required by [DeckConfigStorage].
abstract interface class DeckConfigStorageDatabase {
  /// Executes a query with integer-safe row values and column names.
  List<Map<String, Object?>> select(String sql, [List<Object?> parameters]);

  /// Executes a mutation and returns SQLite's changed-row count.
  int execute(String sql, [List<Object?> parameters]);
}

/// Reads and writes Anki Core `deck_config` rows without choosing a driver.
class DeckConfigStorage {
  DeckConfigStorage(this.db);

  final DeckConfigStorageDatabase db;

  /// Returns all configs in SQLite's natural query order, with Core's read
  /// validation applied to legacy out-of-range values.
  List<DeckConfig> allDeckConfigs() => _allDeckConfigs(fixInvalid: true);

  /// Returns configs without read validation for the schema-16 upgrade path.
  List<DeckConfig> allDeckConfigsForSchema16Upgrade() =>
      _allDeckConfigs(fixInvalid: false);

  /// Returns all configs keyed by ID in SQLite's natural query order.
  Map<Int64, DeckConfig> getDeckConfigMap() => {
        for (final config in allDeckConfigs()) config.id: config,
      };

  /// Returns a config by ID, or null when no row exists.
  DeckConfig? getDeckConfig(Int64 id) {
    final rows = db.select('$_getDeckConfigSql WHERE id = ?', [_sqlInt64(id)]);
    return rows.isEmpty ? null : _configFromRow(rows.single, fixInvalid: true);
  }

  /// Returns the ID for an exact config name, or null when it is absent.
  Int64? getDeckConfigIdByName(String name) {
    final rows = db.select('SELECT id FROM deck_config WHERE name = ?', [name]);
    return rows.isEmpty ? null : _int64(rows.single['id'], 'id');
  }

  /// Inserts [config], applying Core's collision allocation rule, and returns
  /// an immutable copy containing the allocated ID.
  DeckConfig addDeckConfig(DeckConfig config) {
    db.execute(_addDeckConfigSql, [
      _sqlInt64(config.id),
      config.name,
      _sqlInt64(config.mtimeSecs),
      config.usn,
      _configBytes(config),
    ]);
    final id = _int64(
      db.select('SELECT last_insert_rowid() AS id').single['id'],
      'last_insert_rowid',
    );
    return _withId(config, id);
  }

  /// Inserts [config] only when its ID is not already present.
  bool addDeckConfigIfUnique(DeckConfig config) =>
      db.execute(_addIfUniqueDeckConfigSql, [
        _sqlInt64(config.id),
        config.name,
        _sqlInt64(config.mtimeSecs),
        config.usn,
        _configBytes(config),
      ]) ==
      1;

  /// Updates [config]. As in Core, a missing row is not an error.
  void updateDeckConfig(DeckConfig config) {
    db.execute(_updateDeckConfigSql, [
      config.name,
      _sqlInt64(config.mtimeSecs),
      config.usn,
      _configBytes(config),
      _sqlInt64(config.id),
    ]);
  }

  /// Inserts or replaces [config] with its existing ID, as used by sync/undo.
  void addOrUpdateDeckConfigWithExistingId(DeckConfig config) {
    if (config.id == Int64.ZERO) throw StateError('deck config with id 0');
    db.execute(_addOrUpdateDeckConfigSql, [
      _sqlInt64(config.id),
      config.name,
      _sqlInt64(config.mtimeSecs),
      config.usn,
      _configBytes(config),
    ]);
  }

  /// Deletes [id] if present. Missing IDs are a successful no-op.
  void removeDeckConfig(Int64 id) {
    db.execute('DELETE FROM deck_config WHERE id = ?', [_sqlInt64(id)]);
  }

  /// Resets nonzero sync USNs, matching Core's collection helper.
  void clearDeckConfigUsns() {
    db.execute('UPDATE deck_config SET usn = 0 WHERE usn != 0');
  }

  List<DeckConfig> _allDeckConfigs({required bool fixInvalid}) => db
      .select(_getDeckConfigSql)
      .map((row) => _configFromRow(row, fixInvalid: fixInvalid))
      .toList(growable: false);

  DeckConfig _configFromRow(
    Map<String, Object?> row, {
    required bool fixInvalid,
  }) {
    final inner = proto.DeckConfig_Config.fromBuffer(_blob(row['config']));
    if (fixInvalid) _ensureValuesValid(inner);
    return DeckConfig(
      id: _int64(row['id'], 'id'),
      name: _string(row['name'], 'name'),
      mtimeSecs: _int64(row['mtime_secs'], 'mtime_secs'),
      usn: _int32(row['usn'], 'usn'),
      inner: inner,
    );
  }

  static List<int> _configBytes(DeckConfig config) =>
      Uint8List.fromList(config.inner.writeToBuffer());

  static DeckConfig _withId(DeckConfig config, Int64 id) => DeckConfig(
        id: id,
        name: config.name,
        mtimeSecs: config.mtimeSecs,
        usn: config.usn,
        inner: config.inner,
      );

  static void _ensureValuesValid(proto.DeckConfig_Config config) {
    final defaults = DeckConfig.defaults().inner;
    _ensureInt(
      config.newPerDay,
      defaults.newPerDay,
      0,
      9999,
      (value) => config.newPerDay = value,
    );
    _ensureInt(
      config.reviewsPerDay,
      defaults.reviewsPerDay,
      0,
      9999,
      (value) => config.reviewsPerDay = value,
    );
    _ensureInt(
      config.newPerDayMinimum,
      defaults.newPerDayMinimum,
      0,
      9999,
      (value) => config.newPerDayMinimum = value,
    );
    _ensureDouble(
      config.initialEase,
      defaults.initialEase,
      1.31,
      5,
      (value) => config.initialEase = value,
    );
    _ensureDouble(
      config.easyMultiplier,
      defaults.easyMultiplier,
      1,
      5,
      (value) => config.easyMultiplier = value,
    );
    _ensureDouble(
      config.hardMultiplier,
      defaults.hardMultiplier,
      0.5,
      1.3,
      (value) => config.hardMultiplier = value,
    );
    _ensureDouble(
      config.lapseMultiplier,
      defaults.lapseMultiplier,
      0,
      1,
      (value) => config.lapseMultiplier = value,
    );
    _ensureDouble(
      config.intervalMultiplier,
      defaults.intervalMultiplier,
      0.5,
      2,
      (value) => config.intervalMultiplier = value,
    );
    _ensureInt(
      config.maximumReviewInterval,
      defaults.maximumReviewInterval,
      1,
      36500,
      (value) => config.maximumReviewInterval = value,
    );
    _ensureInt(
      config.minimumLapseInterval,
      defaults.minimumLapseInterval,
      1,
      36500,
      (value) => config.minimumLapseInterval = value,
    );
    _ensureInt(
      config.graduatingIntervalGood,
      defaults.graduatingIntervalGood,
      1,
      36500,
      (value) => config.graduatingIntervalGood = value,
    );
    _ensureInt(
      config.graduatingIntervalEasy,
      defaults.graduatingIntervalEasy,
      1,
      36500,
      (value) => config.graduatingIntervalEasy = value,
    );
    _ensureInt(
      config.leechThreshold,
      defaults.leechThreshold,
      1,
      9999,
      (value) => config.leechThreshold = value,
    );
    _ensureInt(
      config.capAnswerTimeToSecs,
      defaults.capAnswerTimeToSecs,
      1,
      9999,
      (value) => config.capAnswerTimeToSecs = value,
    );
    _ensureDouble(
      config.desiredRetention,
      defaults.desiredRetention,
      0.7,
      0.99,
      (value) => config.desiredRetention = value,
    );
    _ensureDouble(
      config.historicalRetention,
      defaults.historicalRetention,
      0.7,
      0.97,
      (value) => config.historicalRetention = value,
    );
  }

  static void _ensureInt(
    int value,
    int defaultValue,
    int min,
    int max,
    void Function(int) set,
  ) {
    if (value < min || value > max) set(defaultValue);
  }

  static void _ensureDouble(
    double value,
    double defaultValue,
    double min,
    double max,
    void Function(double) set,
  ) {
    if (value.isNaN || value < min || value > max) set(defaultValue);
  }

  static Int64 _int64(Object? value, String field) {
    if (value is Int64) return value;
    if (value is BigInt) return Int64.parseInt(value.toString());
    if (value is int) return Int64(value);
    throw FormatException('invalid signed 64-bit deck config $field');
  }

  static int _int32(Object? value, String field) {
    final integer = switch (value) {
      int value => value,
      BigInt value
          when value >= BigInt.from(-0x80000000) &&
              value <= BigInt.from(0x7fffffff) =>
        value.toInt(),
      _ => throw FormatException('invalid signed 32-bit deck config $field'),
    };
    if (integer < -0x80000000 || integer > 0x7fffffff) {
      throw FormatException('invalid signed 32-bit deck config $field');
    }
    return integer;
  }

  static String _string(Object? value, String field) => value is String
      ? value
      : throw FormatException('invalid text deck config $field');

  static List<int> _blob(Object? value) => switch (value) {
        Uint8List bytes => bytes,
        List<int> bytes => bytes,
        _ => throw const FormatException('invalid blob deck config'),
      };

  static BigInt _sqlInt64(Int64 value) => BigInt.parse(value.toString());

  static const _getDeckConfigSql = '''
SELECT id, name, mtime_secs, usn, config
FROM deck_config''';

  static const _addDeckConfigSql = '''
INSERT INTO deck_config (id, name, mtime_secs, usn, config)
VALUES (
  CASE WHEN ?1 IN (SELECT id FROM deck_config)
    THEN (SELECT max(id) + 1 FROM deck_config)
    ELSE ?1
  END,
  ?, ?, ?, ?
)''';

  static const _addIfUniqueDeckConfigSql = '''
INSERT OR IGNORE INTO deck_config (id, name, mtime_secs, usn, config)
VALUES (?, ?, ?, ?, ?)''';

  static const _updateDeckConfigSql = '''
UPDATE deck_config
SET name = ?, mtime_secs = ?, usn = ?, config = ?
WHERE id = ?''';

  static const _addOrUpdateDeckConfigSql = '''
INSERT OR REPLACE INTO deck_config (id, name, mtime_secs, usn, config)
VALUES (?, ?, ?, ?, ?)''';
}
