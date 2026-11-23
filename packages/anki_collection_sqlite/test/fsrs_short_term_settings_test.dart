// SPDX-License-Identifier: AGPL-3.0-or-later
import 'package:anki_collection_sqlite/src/fsrs_short_term_settings.dart';
import 'package:test/test.dart';

void main() {
  test(
    'matches Core FSRS short-term parameter length and positivity rules',
    () {
      expect(
        allowsFsrsShortTerm(fsrsEnabled: false, params: const []),
        isFalse,
      );
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: false,
          params: List<double>.filled(19, 0.25),
        ),
        isFalse,
      );
      expect(allowsFsrsShortTerm(fsrsEnabled: true, params: const []), isTrue);
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: true,
          params: List<double>.filled(18, 0.25),
        ),
        isFalse,
      );
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: true,
          params: List<double>.filled(19, 0.25),
        ),
        isTrue,
      );
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: true,
          params: [...List<double>.filled(17, 0.25), 0, 0.25],
        ),
        isFalse,
      );
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: true,
          params: [...List<double>.filled(17, 0.25), 0.25, 0],
        ),
        isFalse,
      );
      expect(
        allowsFsrsShortTerm(
          fsrsEnabled: true,
          params: [...List<double>.filled(17, 0.25), 0.25, -0.1],
        ),
        isFalse,
      );
    },
  );
}
