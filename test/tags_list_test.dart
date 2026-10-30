/*
 * Copyright (c) 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>
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
 * SPDX-FileCopyrightText: 2021 Tarek Mohamed Abdalla <tarekkma@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Source-derived from TagsList.kt and TagsUtil.kt in AnkiDroid 2.25.3;
 * see ANKIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('tag hierarchy helpers', () {
    test(
      'preserves blank components and compares depth first ignoring case',
      () {
        expect(getTagParts('::first:::::second::'), [
          'blank',
          'first',
          'blank',
          ':second',
          'blank',
        ]);
        expect(getTagAncestors('foo::::aaa'), ['foo', 'foo::blank']);
        expect(getTagAncestors('::foo::aaa'), ['blank', 'blank::foo']);
        expect(getTagRoot('::careless'), 'blank');
        expect(compareTag('aaa::foo', 'aaa::foo::trailing'), lessThan(0));
        expect(compareTag('aaa::bbbz::foo', 'aaa::bbb::bar'), greaterThan(0));
        expect(compareTag('aAa::bbb', 'aaa::bBb'), 0);
        expect(compareTag('I::tag', 'ı::TAG'), 0);
        expect(TagsList(['I', 'ı'], []).copyOfAllTagList(), ['I']);
        expect(TagsList(['ß', 'ss'], []).copyOfAllTagList(), ['ß', 'ss']);
      },
    );
  });

  group('TagsList', () {
    test(
      'construction deduplicates by case and completes selected hierarchy',
      () {
        final tags = TagsList(
          ['cat2::aa', 'CAT2::AA', 'cat1'],
          ['Cat1::child', 'cat2::BB::leaf', 'CAT2::bb::LEAF'],
          ['cat1::CHILD'],
        );

        expect(tags.copyOfAllTagList(), [
          'cat2::aa',
          'cat1',
          'Cat1::child',
          'cat2::BB::leaf',
          'cat2',
          'cat2::BB',
        ]);
        expect(tags.copyOfCheckedTagList(), ['cat2::BB::leaf']);
        expect(tags.copyOfIndeterminateTagList(), [
          'Cat1',
          'Cat1::child',
          'cat2',
          'cat2::BB',
        ]);
        expect(tags.isPartiallySelected('CAT1::child'), isTrue);
        expect(tags.isIndeterminate('cat1::child'), isTrue);
        expect(tags.isChecked('cat2::bb::leaf'), isTrue);
        expect(tags.hasSelectedDescendants('CAT1'), isTrue);
        expect(tags.hasSelectedDescendants('cat'), isFalse);
      },
    );

    test('selection changes preserve source no-op and ancestor semantics', () {
      final tags = TagsList(['root::child', 'other'], ['root::child']);

      expect(tags.check('missing'), isFalse);
      expect(tags.check('ROOT::CHILD'), isFalse);
      expect(tags.add('root::new'), isTrue);
      expect(tags.copyOfAllTagList(), [
        'root::child',
        'other',
        'root',
        'root::new',
      ]);
      expect(tags.check('root::new'), isTrue);
      expect(tags.isIndeterminate('root'), isTrue);
      expect(tags.uncheck('root::new'), isTrue);
      expect(tags.uncheck('root::new'), isFalse);

      expect(tags.setIndeterminate('other'), isTrue);
      expect(tags.isChecked('other'), isFalse);
      expect(tags.uncheck('OTHER'), isTrue);
      expect(tags.isIndeterminate('other'), isFalse);

      final partiallySelected = TagsList(['root::child'], ['root::child'], [
        'root::child',
      ]);
      expect(partiallySelected.isPartiallySelected('root::child'), isTrue);
      expect(
        partiallySelected.check('ROOT::CHILD', processAncestors: false),
        isTrue,
      );
      expect(partiallySelected.isChecked('root::child'), isTrue);
      expect(partiallySelected.isIndeterminate('root::child'), isFalse);
      expect(partiallySelected.isPartiallySelected('root::child'), isFalse);
    });

    test(
      'toggle all clears partial states and sorts roots by selection priority',
      () {
        final tags = TagsList(
          ['z::child', 'a::child', 'b'],
          ['z::child', 'b'],
          ['b'],
        );

        expect(tags.copyOfPartiallySelectedTagList(), ['b']);
        tags.sort();
        expect(tags.copyOfAllTagList(), [
          'b',
          'z',
          'z::child',
          'a',
          'a::child',
        ]);
        expect(tags.toggleAllCheckedStatuses(), isTrue);
        expect(tags.copyOfCheckedTagList(), [
          'a',
          'a::child',
          'b',
          'z',
          'z::child',
        ]);
        expect(tags.copyOfIndeterminateTagList(), isEmpty);
        expect(tags.copyOfPartiallySelectedTagList(), isEmpty);
        expect(tags.toggleAllCheckedStatuses(), isTrue);
        expect(tags.copyOfCheckedTagList(), isEmpty);
        expect(TagsList([], []).toggleAllCheckedStatuses(), isTrue);
      },
    );

    test('lookup copies iteration and index bounds follow list behavior', () {
      final tags = TagsList(['b', 'a', 'B'], ['missing']);
      expect(tags.size(), 3);
      expect(tags.isEmpty, isFalse);
      expect(tags[0], 'b');
      expect(tags.isChecked(2), isTrue);
      expect(tags.toList(), ['b', 'a', 'missing']);
      final copy = tags.copyOfAllTagList();
      copy.clear();
      expect(tags.size(), 3);
      expect(() => tags[-1], throwsRangeError);
      expect(() => tags[3], throwsRangeError);
    });
  });
}
