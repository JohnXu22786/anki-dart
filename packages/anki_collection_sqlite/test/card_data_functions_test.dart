// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/card_data_functions.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'extract_original_position follows CardData default-on-invalid behavior',
    () {
      expect(extractOriginalPosition('{"pos":0}'), 0);
      expect(extractOriginalPosition('{"pos":42}'), 42);
      expect(extractOriginalPosition('{"pos":4294967295}'), 4294967295);
      expect(extractOriginalPosition('[42]'), 42);
      expect(extractOriginalPosition('{"pos":-1}'), isNull);
      expect(extractOriginalPosition('{"pos":4294967296}'), isNull);
      expect(extractOriginalPosition('{"pos":3.0}'), isNull);
      expect(extractOriginalPosition('{"pos":"3"}'), isNull);
      expect(extractOriginalPosition('[]'), isNull);
      expect(extractOriginalPosition('{bad json'), isNull);
      expect(extractOriginalPosition(''), isNull);
      expect(extractOriginalPosition(null), isNull);
      expect(extractOriginalPosition(42), isNull);
    },
  );

  test('extract_custom_data mirrors Core JSON value handling and ordering', () {
    const cardData =
        '{"cd":"{\\"r\\":true,\\"n\\":null,\\"s\\":\\"text\\",'
        '\\"o\\":{\\"z\\":1,\\"a\\":2},\\"a\\":[1,{\\"y\\":1,\\"x\\":2}]}"}';

    expect(extractCustomData(cardData, 'r'), 'true');
    expect(extractCustomData(cardData, 'n'), 'null');
    expect(extractCustomData(cardData, 's'), 'text');
    expect(extractCustomData(cardData, 'o'), '{"a":2,"z":1}');
    expect(extractCustomData(cardData, 'a'), '[1,{"x":2,"y":1}]');
    expect(extractCustomData(cardData, 'missing'), isNull);
    expect(extractCustomData('{bad json', 'r'), isNull);
    expect(extractCustomData('{"cd":""}', 'r'), isNull);
    expect(extractCustomData('{"cd":"not json"}', 'r'), isNull);
    expect(extractCustomData('{"cd":42}', 'r'), isNull);
    expect(
      extractCustomData('[null,null,null,null,null,null,"{\\"x\\":1}"]', 'x'),
      '1',
    );
    expect(extractCustomData('{"cd":"[1,2]"}', '0'), isNull);
    expect(extractCustomData('', 'r'), isNull);
    expect(extractCustomData(cardData, null), isNull);
    expect(extractCustomData(null, 'r'), isNull);
  });

  test('registered card-data SQL functions return Core values and nulls', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.close);
    registerCardDataFunctions(database);

    expect(
      database
          .select("SELECT extract_original_position('{\"pos\":42}')")
          .single[0],
      42,
    );
    expect(
      database
          .select("SELECT extract_original_position('{bad json')")
          .single[0],
      isNull,
    );
    expect(
      database
          .select(
            "SELECT extract_custom_data('{\"cd\":\"{\\\"x\\\":true}\"}', 'x')",
          )
          .single[0],
      'true',
    );
    expect(
      database
          .select("SELECT extract_custom_data('{\"cd\":\"not json\"}', 'x')")
          .single[0],
      isNull,
    );
    expect(
      database.select('SELECT extract_custom_data(NULL, NULL)').single[0],
      isNull,
    );
  });
}
