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
 * Source-derived from NoteFieldDecorator.kt in AnkiDroid 2.25.3; see ANKIIDROID_UPSTREAM.md.
 */

import 'package:anki_dart/anki_dart.dart';
import 'package:test/test.dart';

void main() {
  group('aplicaHuevo', () {
    test(
      'recognizes ROT13 option names using host case-insensitive equality',
      () {
        final seen = <(String, String?)>[];
        var randomCalls = 0;

        final lower = aplicaHuevo(
          'dae',
          equalsIgnoreCase: (option, transformed) {
            seen.add((option, transformed));
            return option.toLowerCase() == transformed?.toLowerCase();
          },
          nextRandomIndex: (bound) {
            randomCalls++;
            expect(bound, 11);
            return 0;
          },
        );
        expect(lower, '💌💌 dae 💌💌');
        expect(seen, [('qnr', 'qnr')]);
        expect(randomCalls, 1);

        seen.clear();
        final mixedCase = aplicaHuevo(
          'DAE',
          equalsIgnoreCase: (option, transformed) {
            seen.add((option, transformed));
            return option.toLowerCase() == transformed?.toLowerCase();
          },
          nextRandomIndex: (_) => 10,
        );
        expect(mixedCase, '😍😍 DAE 😍😍');
        expect(seen, [('qnr', 'QNR')]);
      },
    );

    test(
      'preserves nonmatches, null, and empty text without random selection',
      () {
        var comparisons = 0;
        var randomCalls = 0;
        String? run(String? text) => aplicaHuevo(
          text,
          equalsIgnoreCase: (option, transformed) {
            comparisons++;
            return false;
          },
          nextRandomIndex: (_) {
            randomCalls++;
            return 0;
          },
        );

        expect(run('ordinary field'), 'ordinary field');
        expect(run(null), isNull);
        expect(run(''), '');
        expect(comparisons, 35 * 3);
        expect(randomCalls, 0);
      },
    );

    test(
      'rotates through the exact ordered option list and stops at first match',
      () {
        final compared = <String>[];
        final result = aplicaHuevo(
          'ZornHadNoChoice',
          equalsIgnoreCase: (option, transformed) {
            compared.add(option);
            return option == 'MbeaUnqAbPubvpr';
          },
          nextRandomIndex: (_) => 5,
        );

        expect(compared, [
          'qnr',
          'gvzenr',
          'aboantb',
          'avpbynf-enbhy',
          'Neguhe-Zvypuvbe',
          'zvxruneql',
          'qnivq-nyyvfba',
          'vavwh',
          'uffz',
          'syreqn',
          'rqh-mnzben',
          'ntehraroret',
          'bfcnyu',
          'znaqer',
          'qnavry-fineq',
          'vasvalgr7',
          'Oynvfbeoynqr',
          'genfuphggre',
          'qzvgel-gvzbsrri',
          'inabfgra',
          'unacvatpuvarfr',
          'jro5atnl',
          'FuevquneTbry',
          'Nxfunl0701',
          'ivpvbhfNrtvf',
          'gurqebvqqvi',
          'OenlnaQFB',
          'pevgvpnyNL',
          'fnawnlfnetnz',
          'krabaaa4j',
          'revpyv3690',
          'Unm3-wbyg',
          'fabjgvzrtynff',
          'hfre1823',
          'MbeaUnqAbPubvpr',
        ]);
        expect(result, '💞💞 ZornHadNoChoice 💞💞');
      },
    );

    test(
      'rotates accented text using ASCII-only ROT13 and preserves source text',
      () {
        final seen = <(String, String?)>[];
        var randomCalls = 0;
        final result = aplicaHuevo(
          'café dae!',
          equalsIgnoreCase: (option, transformed) {
            seen.add((option, transformed));
            return option == 'qnr';
          },
          nextRandomIndex: (_) {
            randomCalls++;
            return 3;
          },
        );

        expect(seen, [('qnr', 'pnsé qnr!')]);
        expect(result, '💗💗 café dae! 💗💗');
        expect(randomCalls, 1);
      },
    );

    test(
      'propagates comparison and random callback failures in source order',
      () {
        final comparisonFailure = StateError('comparison failed');
        final compared = <String>[];
        expect(
          () => aplicaHuevo(
            'ordinary',
            equalsIgnoreCase: (option, transformed) {
              compared.add(option);
              if (option == 'aboantb') throw comparisonFailure;
              return false;
            },
            nextRandomIndex: (_) => fail('random must not run'),
          ),
          throwsA(same(comparisonFailure)),
        );
        expect(compared, ['qnr', 'gvzenr', 'aboantb']);

        final randomFailure = StateError('random failed');
        compared.clear();
        expect(
          () => aplicaHuevo(
            'dae',
            equalsIgnoreCase: (option, transformed) {
              compared.add(option);
              return option == 'qnr';
            },
            nextRandomIndex: (bound) {
              expect(bound, 11);
              throw randomFailure;
            },
          ),
          throwsA(same(randomFailure)),
        );
        expect(compared, ['qnr']);
      },
    );
  });
}
