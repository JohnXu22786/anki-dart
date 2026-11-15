/*
 * Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 3 of the License, or (at your option) any later
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
 * Behavioral reference: FieldFilterChainTest.kt in AnkiDroid 2.25.3; see
 * ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('FieldFilterChain.build and rendering', () {
    test('builds an empty valid chain with the default context', () {
      final chain = FieldFilterChain.build(
        const FieldName('Front'),
        isClozeNoteType: true,
      );

      expect(chain.fieldName, const FieldName('Front'));
      expect(chain.filters, isEmpty);
      expect(chain.context, const FilterContext(isClozeNoteType: true));
      expect(chain.isValid, isTrue);
      expect(chain.render(), '{{Front}}');
      expect(chain.toString(), chain.render());
    });

    test(
      'renders filters in reverse stored order without changing old chain',
      () {
        final empty = FieldFilterChain.build(
          const FieldName('Back'),
          isClozeNoteType: false,
        );
        final withText = empty.tryAdd(FieldFilters.text)!;
        final withKana = withText.tryAdd(FieldFilters.kana)!;

        expect(empty.filters, isEmpty);
        expect(withText.filters, [FieldFilters.text]);
        expect(withKana.filters, [FieldFilters.text, FieldFilters.kana]);
        expect(withKana, isNot(same(withText)));
        expect(withKana.filters, isNot(same(withText.filters)));
        expect(withKana.render(), '{{kana:text:Back}}');
        expect(withKana.toString(), '{{kana:text:Back}}');
      },
    );
  });

  group('FieldFilterChain.tryAdd ordering and validity', () {
    test(
      'rejects invalid filters before callbacks unless allowInvalid is set',
      () {
        final calls = <String>[];
        final invalid = _ProbeFilter(
          'invalid',
          calls: calls,
          valid: false,
          canApply: true,
        );
        final chain = FieldFilterChain.build(
          const FieldName('Front'),
          isClozeNoteType: false,
        );

        expect(chain.tryAdd(invalid), isNull);
        expect(calls, ['isValid']);

        final accepted = chain.tryAdd(invalid, allowInvalid: true)!;
        expect(calls, ['isValid', 'canApply', 'updateContext', 'isValid']);
        expect(accepted.isValid, isFalse);
        expect(accepted.filters, [invalid]);
        expect(chain.isValid, isTrue);
      },
    );

    test(
      'invalid current chain short-circuits before callbacks unless allowed',
      () {
        final calls = <String>[];
        final invalid = _ProbeFilter(
          'invalid',
          calls: <String>[],
          valid: false,
          canApply: true,
        );
        final chain = FieldFilterChain.build(
          const FieldName('Front'),
          isClozeNoteType: false,
        ).tryAdd(invalid, allowInvalid: true)!;
        final next = _ProbeFilter('next', calls: calls, canApply: true);

        expect(chain.tryAdd(next), isNull);
        expect(calls, ['isValid']);

        final continued = chain.tryAdd(next, allowInvalid: true)!;
        expect(calls, ['isValid', 'canApply', 'updateContext']);
        expect(continued.isValid, isFalse);
      },
    );

    test(
      'checks applicability before duplicate names and skips update on rejection',
      () {
        final calls = <String>[];
        final original = _ProbeFilter(
          'same',
          calls: <String>[],
          canApply: true,
        );
        final duplicate = _ProbeFilter('same', calls: calls, canApply: false);
        final chain = FieldFilterChain.build(
          const FieldName('Front'),
          isClozeNoteType: false,
        ).tryAdd(original)!;

        expect(chain.tryAdd(duplicate), isNull);
        expect(calls, ['isValid', 'canApply']);

        final applicableDuplicate = _ProbeFilter(
          'same',
          calls: calls,
          canApply: true,
        );
        expect(chain.tryAdd(applicableDuplicate), isNull);
        expect(calls, ['isValid', 'canApply', 'isValid', 'canApply']);
      },
    );

    test('reads every existing name before checking a duplicate', () {
      final nameReads = <String>[];
      final chain =
          FieldFilterChain.build(
                const FieldName('Front'),
                isClozeNoteType: false,
              )
              .tryAdd(_NameProbeFilter('duplicate', nameReads))!
              .tryAdd(_NameProbeFilter('later', nameReads))!;
      nameReads.clear();

      expect(chain.tryAdd(_NameProbeFilter('duplicate', nameReads)), isNull);
      expect(nameReads, ['duplicate', 'later', 'duplicate']);
    });

    test(
      'updates context only after checks and propagates callback failures',
      () {
        final calls = <String>[];
        final chain = FieldFilterChain.build(
          const FieldName('Front'),
          isClozeNoteType: false,
        );
        final success = _ProbeFilter(
          'success',
          calls: calls,
          canApply: true,
          update: (context) => context.copyWith(producesHtml: true),
        );

        final result = chain.tryAdd(success)!;
        expect(calls, ['isValid', 'canApply', 'updateContext', 'isValid']);
        expect(result.context.producesHtml, isTrue);

        final canApplyFailure = _ProbeFilter(
          'throws-can-apply',
          calls: calls,
          canApply: true,
          check: (_) => throw StateError('canApply failed'),
        );
        expect(
          () => result.tryAdd(canApplyFailure),
          throwsA(isA<StateError>()),
        );

        final updateFailure = _ProbeFilter(
          'throws-update',
          calls: calls,
          canApply: true,
          update: (_) => throw StateError('updateContext failed'),
        );
        expect(() => chain.tryAdd(updateFailure), throwsA(isA<StateError>()));
      },
    );
  });

  group('FieldFilterChain with mapped non-TTS filters', () {
    test('preserves HTML, cloze, and pronunciation constraints', () {
      final ordinary = FieldFilterChain.build(
        const FieldName('Front'),
        isClozeNoteType: false,
      );
      final cloze = FieldFilterChain.build(
        const FieldName('Front'),
        isClozeNoteType: true,
      );

      expect(ordinary.tryAdd(FieldFilters.cloze), isNull);
      expect(ordinary.tryAdd(FieldFilters.clozeOnly), isNull);
      expect(cloze.tryAdd(FieldFilters.cloze), isNotNull);
      expect(cloze.tryAdd(FieldFilters.clozeOnly), isNotNull);
      expect(
        ordinary.tryAdd(FieldFilters.hint)!.tryAdd(FieldFilters.text),
        isNull,
      );
      expect(
        ordinary.tryAdd(FieldFilters.furigana)!.tryAdd(FieldFilters.text),
        isNull,
      );
      expect(
        ordinary.tryAdd(FieldFilters.furigana)!.tryAdd(FieldFilters.kana),
        isNull,
      );
      expect(
        ordinary.tryAdd(FieldFilters.kana)!.tryAdd(FieldFilters.kanji),
        isNull,
      );
    });

    test('permits only nosuggest after terminal type filters', () {
      final chain = FieldFilterChain.build(
        const FieldName('Front'),
        isClozeNoteType: false,
      );

      for (final typeFilter in [
        FieldFilters.type,
        FieldFilters.typeNonCombining,
      ]) {
        final typed = chain.tryAdd(typeFilter)!;
        expect(typed.tryAdd(FieldFilters.text), isNull);
        expect(typed.tryAdd(FieldFilters.hint), isNull);
        expect(typed.tryAdd(FieldFilters.noSuggest), isNotNull);
      }
      expect(chain.tryAdd(FieldFilters.noSuggest), isNull);
    });
  });
}

final class _ProbeFilter extends FieldFilter {
  _ProbeFilter(
    this.name, {
    required this.calls,
    this.valid = true,
    required this.canApply,
    this.check,
    this.update,
  });

  @override
  final String name;
  final List<String> calls;
  final bool valid;
  final bool canApply;
  final void Function(FilterContext context)? check;
  final FilterContext Function(FilterContext context)? update;

  @override
  bool get isValid {
    calls.add('isValid');
    return valid;
  }

  @override
  bool canApplyTo(FilterContext context) {
    calls.add('canApply');
    check?.call(context);
    return canApply;
  }

  @override
  FilterContext updateContext(FilterContext input) {
    calls.add('updateContext');
    return update?.call(input) ?? input;
  }
}

final class _NameProbeFilter extends FieldFilter {
  _NameProbeFilter(this.value, this.nameReads);

  final String value;
  final List<String> nameReads;

  @override
  String get name {
    nameReads.add(value);
    return value;
  }
}
