// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  group('selectFsrsBestModel', () {
    test('selects candidate when its validation loss is lower', () {
      final current = FsrsBestModelSnapshot(
        validationLoss: 0.4,
        parameters: [1, 2, 3],
      );
      final candidate = FsrsBestModelSnapshot(
        validationLoss: 0.2,
        parameters: [4, 5, 6],
      );

      final result = selectFsrsBestModel(
        currentBest: current,
        candidate: candidate,
      );

      expect(result.validationLoss, 0.2);
      expect(result.parameters, [4, 5, 6]);
    });

    test('keeps current best for equal and worse validation losses', () {
      final current = FsrsBestModelSnapshot(
        validationLoss: 0.2,
        parameters: [1, 2, 3],
      );

      for (final candidateLoss in [0.2, 0.3]) {
        final result = selectFsrsBestModel(
          currentBest: current,
          candidate: FsrsBestModelSnapshot(
            validationLoss: candidateLoss,
            parameters: [4, 5, 6],
          ),
        );

        expect(result.validationLoss, 0.2);
        expect(result.parameters, [1, 2, 3]);
      }
    });

    test('uses strict floating-point comparison for NaN and infinities', () {
      final current = FsrsBestModelSnapshot(
        validationLoss: 0.2,
        parameters: [1],
      );
      final nanCandidate = selectFsrsBestModel(
        currentBest: current,
        candidate: FsrsBestModelSnapshot(
          validationLoss: double.nan,
          parameters: [2],
        ),
      );
      final finiteCandidate = selectFsrsBestModel(
        currentBest: FsrsBestModelSnapshot(
          validationLoss: double.infinity,
          parameters: [1],
        ),
        candidate: FsrsBestModelSnapshot(
          validationLoss: 0.2,
          parameters: [2],
        ),
      );
      final infiniteCandidate = selectFsrsBestModel(
        currentBest: FsrsBestModelSnapshot(
          validationLoss: double.infinity,
          parameters: [1],
        ),
        candidate: FsrsBestModelSnapshot(
          validationLoss: double.infinity,
          parameters: [2],
        ),
      );

      expect(nanCandidate.validationLoss, 0.2);
      expect(nanCandidate.parameters, [1]);
      expect(finiteCandidate.validationLoss, 0.2);
      expect(finiteCandidate.parameters, [2]);
      expect(infiniteCandidate.validationLoss, double.infinity);
      expect(infiniteCandidate.parameters, [1]);
    });

    test('snapshots ordered parameters immutably without mutating inputs', () {
      final source = [3.25, -1.5, 8.0];
      final sourceBefore = List<double>.of(source);
      final current = FsrsBestModelSnapshot(
        validationLoss: 1,
        parameters: source,
      );
      final candidate = FsrsBestModelSnapshot(
        validationLoss: 0,
        parameters: [8.0, 3.25, -1.5],
      );
      final result = selectFsrsBestModel(
        currentBest: current,
        candidate: candidate,
      );

      expect(current.parameters, [3.25, -1.5, 8.0]);
      expect(result.parameters, [8.0, 3.25, -1.5]);
      expect(source, sourceBefore);
      expect(result.parameters, isNot(same(candidate.parameters)));
      expect(() => result.parameters[0] = 42, throwsUnsupportedError);
      expect(() => current.parameters[0] = 42, throwsUnsupportedError);
    });
  });
}
