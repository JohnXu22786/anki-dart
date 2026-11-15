// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_backend_protocol/anki/generic.pb.dart' as generic;
import 'package:anki_backend_protocol/anki/i18n.pb.dart' as i18n;
import 'package:anki_backend_protocol/anki/search.pb.dart' as search;
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:test/test.dart';

void main() {
  group('Anki backend protocol wire compatibility', () {
    test('preserves signed scalar boundary values', () {
      final original = generic.Int32(val: -2147483648);
      final decoded = generic.Int32.fromBuffer(original.writeToBuffer());

      expect(decoded.val, -2147483648);
    });

    test('preserves repeated values and nested message structure', () {
      final original = search.SearchNode(
        group: search.SearchNode_Group(
          nodes: [
            search.SearchNode(parsableText: 'deck:Default'),
            search.SearchNode(tag: 'marked'),
          ],
          joiner: search.SearchNode_Group_Joiner.OR,
        ),
      );
      final decoded = search.SearchNode.fromBuffer(original.writeToBuffer());

      expect(decoded.group.nodes.map((node) => node.whichFilter()), [
        search.SearchNode_Filter.parsableText,
        search.SearchNode_Filter.tag,
      ]);
      expect(decoded.group.nodes.map((node) => node.writeToJson()), [
        original.group.nodes[0].writeToJson(),
        original.group.nodes[1].writeToJson(),
      ]);
      expect(decoded.group.joiner, search.SearchNode_Group_Joiner.OR);
    });

    test('preserves map entries and oneof selection', () {
      final original = i18n.TranslateStringRequest(
        moduleIndex: 9,
        args: {
          'count': i18n.TranslateArgValue(number: 1.5),
          'name': i18n.TranslateArgValue(str: 'Ada'),
        },
      );
      final decoded = i18n.TranslateStringRequest.fromBuffer(
        original.writeToBuffer(),
      );

      expect(decoded.args['count']!.number, 1.5);
      expect(decoded.args['count']!.whichValue(),
          i18n.TranslateArgValue_Value.number);
      expect(decoded.args['name']!.str, 'Ada');
      expect(
          decoded.args['name']!.whichValue(), i18n.TranslateArgValue_Value.str);
    });

    test('retains explicitly selected default enum value', () {
      final original = i18n.FormatTimespanRequest(
        seconds: 0,
        context: i18n.FormatTimespanRequest_Context.PRECISE,
      );
      final decoded = i18n.FormatTimespanRequest.fromBuffer(
        original.writeToBuffer(),
      );

      expect(decoded.context, i18n.FormatTimespanRequest_Context.PRECISE);
    });

    test('retains unknown fields through decode and re-encode', () {
      final withUnknownField = [
        ...generic.Empty().writeToBuffer(),
        0xa0,
        0x06,
        0x7b
      ];
      final decoded = generic.Empty.fromBuffer(withUnknownField);

      expect(decoded.writeToBuffer(), withUnknownField);
    });

    test('preserves signed 64-bit boundary values', () {
      final minimum = fixnum.Int64.MIN_VALUE;
      final original = generic.Int64(val: minimum);
      final decoded = generic.Int64.fromBuffer(original.writeToBuffer());

      expect(decoded.val, minimum);
    });

    test('preserves bytes at binary boundary values', () {
      final original = generic.Json(json: [0, 127, 128, 255]);
      final decoded = generic.Json.fromBuffer(original.writeToBuffer());

      expect(decoded.json, [0, 127, 128, 255]);
    });
  });
}
