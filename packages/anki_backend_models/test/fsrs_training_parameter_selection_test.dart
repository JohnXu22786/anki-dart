// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 John Tsui

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

void main() {
  final defaults = List<double>.generate(21, (index) => index.toDouble());
  final initialized = List<double>.generate(
    21,
    (index) => 100 + index.toDouble(),
  );

  FsrsTrainingParameterSelection select(int training, int initialization) =>
      selectFsrsTrainingParameters(
        trainingItemCount: training,
        initializationItemCount: initialization,
        defaultParameters: defaults,
        initializedParameters: initialized,
      );

  group('selectFsrsTrainingParameters', () {
    test('uses source thresholds around 8 and 64 retained items', () {
      for (final count in [0, 7]) {
        final selection = select(count, count);
        expect(selection.source, FsrsTrainingParameterSource.defaults);
        expect(selection.parameters, defaults);
      }

      for (final count in [8, 63]) {
        final selection = select(count, count - 1);
        expect(selection.source, FsrsTrainingParameterSource.initialized);
        expect(selection.parameters, initialized);
      }

      for (final count in [64, 65]) {
        final selection = select(count, count - 1);
        expect(selection.source, FsrsTrainingParameterSource.optimizer);
        expect(selection.parameters, isNull);
      }
    });

    test('uses initialized parameters for equal counts at and above 64', () {
      for (final count in [64, 65]) {
        final selection = select(count, count);
        expect(selection.source, FsrsTrainingParameterSource.initialized);
        expect(selection.parameters, initialized);
      }
      expect(select(64, 63).source, FsrsTrainingParameterSource.optimizer);
    });

    test('checks the fewer-than-eight branch before equal counts', () {
      final selection = select(7, 7);

      expect(selection.source, FsrsTrainingParameterSource.defaults);
      expect(selection.parameters, defaults);
    });

    test('returns immutable exact snapshots without changing inputs', () {
      final defaultsBefore = List<double>.of(defaults);
      final initializedBefore = List<double>.of(initialized);

      final defaultSelection = select(7, 0);
      final initializedSelection = select(8, 1);

      expect(defaultSelection.parameters, defaults);
      expect(initializedSelection.parameters, initialized);
      expect(
        () => defaultSelection.parameters![0] = -1,
        throwsUnsupportedError,
      );
      expect(
        () => initializedSelection.parameters![0] = -1,
        throwsUnsupportedError,
      );
      expect(defaults, defaultsBefore);
      expect(initialized, initializedBefore);
    });

    test('rejects negative counts, malformed vectors, and nonfinite weights',
        () {
      expect(() => select(-1, 0), throwsArgumentError);
      expect(() => select(8, -1), throwsArgumentError);

      void expectInvalidVectors({
        List<double>? defaultParameters,
        List<double>? initializedParameters,
      }) {
        expect(
          () => selectFsrsTrainingParameters(
            trainingItemCount: 8,
            initializationItemCount: 1,
            defaultParameters: defaultParameters ?? defaults,
            initializedParameters: initializedParameters ?? initialized,
          ),
          throwsArgumentError,
        );
      }

      expectInvalidVectors(defaultParameters: List<double>.filled(20, 0));
      expectInvalidVectors(initializedParameters: List<double>.filled(22, 0));
      expectInvalidVectors(
        defaultParameters: [...defaults]..[3] = double.nan,
      );
      expectInvalidVectors(
        initializedParameters: [...initialized]..[17] = double.infinity,
      );
    });
  });
}
