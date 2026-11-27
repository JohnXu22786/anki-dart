// SPDX-License-Identifier: AGPL-3.0-or-later
import 'dart:typed_data';

import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:test/test.dart';

const _fixtureGradients = <double>[
  -0.095688485,
  -0.0051607806,
  -0.00080300873,
  0.007462064,
  0.03677408,
  -0.084962785,
  0.059571628,
  -2.1566951,
  0.5738574,
  -2.8749206,
  0.7123072,
  -0.028993709,
  0.0099172965,
  -0.2189217,
  -0.0017800558,
  -0.089381434,
  0.299141,
  0.0708902,
  -0.01219162,
  -0.25424173,
  0.27452517,
];

const _fixtureParameters = <double>[
  0.212,
  1.2931,
  2.3065,
  8.2956,
  6.4133,
  0.8334,
  3.0194,
  0.001,
  1.8722,
  0.1666,
  0.796,
  1.4835,
  0.0614,
  0.2629,
  1.6483,
  0.6014,
  1.8729,
  0.5425,
  0.0912,
  0.0658,
  0.1542,
];

const _fixtureUpdatedParameters = <double>[
  0.252,
  1.3331,
  2.3464994,
  8.2556,
  6.3733,
  0.87340003,
  2.9794,
  0.040999997,
  1.8322,
  0.20660001,
  0.756,
  1.5235,
  0.021400042,
  0.3029,
  1.6882998,
  0.64140004,
  1.8329,
  0.5025,
  0.13119997,
  0.1058,
  0.1142,
];

void main() {
  group('stepFsrsAdam', () {
    test('matches the pinned FSRS 5.2.0 first-step fixture', () {
      final result = stepFsrsAdam(
        _fixtureParameters,
        _fixtureGradients,
        learningRate: 0.04,
      );

      for (var index = 0; index < _fixtureUpdatedParameters.length; index++) {
        expect(result.parameters[index],
            closeTo(_fixtureUpdatedParameters[index], 1e-6));
      }
      expect(result.state.time, 1);
      final beta1Factor = _f32(1.0 - _f32(0.9));
      final beta2Factor = _f32(1.0 - _f32(0.999));
      expect(
        result.state.firstMoment,
        Float32List.fromList(
            _fixtureGradients.map((g) => _f32(_f32(g) * beta1Factor)).toList()),
      );
      expect(
        result.state.secondMoment,
        Float32List.fromList(
          _fixtureGradients
              .map((g) => _f32(_f32(_f32(g) * _f32(g)) * beta2Factor))
              .toList(),
        ),
      );
    });

    test('updates moments and bias-corrects first and second steps', () {
      final first = stepFsrsAdam([1], [2], learningRate: 0.1);
      expect(first.state.firstMoment.single, closeTo(0.2, 1e-7));
      expect(first.state.secondMoment.single, closeTo(0.004, 1e-7));
      expect(first.parameters.single, closeTo(0.9, 1e-6));

      final second = stepFsrsAdam(
        first.parameters,
        [4],
        learningRate: 0.1,
        state: first.state,
      );
      expect(second.state.time, 2);
      expect(second.state.firstMoment.single, closeTo(0.58, 3e-7));
      expect(second.state.secondMoment.single, closeTo(0.019996, 5e-7));
      expect(second.parameters.single, closeTo(0.8035, 2e-4));
    });

    test('continues an immutable prior snapshot without mutating inputs', () {
      final parameters = [1.25, -3.5];
      final firstGradients = [0.25, -2.0];
      final first =
          stepFsrsAdam(parameters, firstGradients, learningRate: 0.03);
      final parametersBefore = List<double>.of(parameters);
      final gradientsBefore = List<double>.of(firstGradients);
      final priorMoment1 = List<double>.of(first.state.firstMoment);
      final priorMoment2 = List<double>.of(first.state.secondMoment);

      final nextGradients = [-0.5, 1.0];
      final continued = stepFsrsAdam(
        first.parameters,
        nextGradients,
        learningRate: 0.03,
        state: first.state,
      );
      final restoredState = FsrsAdamState(
        time: first.state.time,
        firstMoment: first.state.firstMoment,
        secondMoment: first.state.secondMoment,
      );
      final resumed = stepFsrsAdam(
        first.parameters,
        nextGradients,
        learningRate: 0.03,
        state: restoredState,
      );

      expect(resumed.parameters, continued.parameters);
      expect(resumed.state.time, continued.state.time);
      expect(resumed.state.firstMoment, continued.state.firstMoment);
      expect(resumed.state.secondMoment, continued.state.secondMoment);
      expect(parameters, parametersBefore);
      expect(firstGradients, gradientsBefore);
      expect(first.state.firstMoment, priorMoment1);
      expect(first.state.secondMoment, priorMoment2);
      expect(nextGradients, [-0.5, 1.0]);
      expect(() => first.state.firstMoment[0] = 0, throwsUnsupportedError);
    });

    test('rejects invalid lengths, times, values, and learning rates', () {
      expect(
        () => stepFsrsAdam([1, 2], [1], learningRate: 0.1),
        throwsArgumentError,
      );
      expect(
        () => stepFsrsAdam([1], [1],
            learningRate: 0.1,
            state: FsrsAdamState(time: 1, firstMoment: [], secondMoment: [])),
        throwsArgumentError,
      );
      expect(
        () => FsrsAdamState(time: 0, firstMoment: [], secondMoment: []),
        throwsArgumentError,
      );
      expect(
        () => stepFsrsAdam([double.nan], [1], learningRate: 0.1),
        throwsArgumentError,
      );
      expect(
        () => stepFsrsAdam([1], [double.infinity], learningRate: 0.1),
        throwsArgumentError,
      );
      expect(
        () => FsrsAdamState(
            time: 1, firstMoment: [double.nan], secondMoment: [1]),
        throwsArgumentError,
      );
      for (final learningRate in [0.0, -0.1, double.nan, double.infinity]) {
        expect(
          () => stepFsrsAdam([1], [1], learningRate: learningRate),
          throwsArgumentError,
        );
      }
    });

    test('returns Float32 rounded immutable parameter and state snapshots', () {
      final parameters = [1.00000006];
      final gradients = [0.33333334];
      final result = stepFsrsAdam(parameters, gradients, learningRate: 0.01);

      expect(result.parameters, Float32List.fromList(result.parameters));
      expect(result.state.firstMoment,
          Float32List.fromList(result.state.firstMoment));
      expect(result.state.secondMoment,
          Float32List.fromList(result.state.secondMoment));
      expect(result.parameters, isNot(same(parameters)));
      expect(() => result.parameters[0] = 0, throwsUnsupportedError);
      expect(() => result.state.secondMoment[0] = 0, throwsUnsupportedError);
    });
  });
}

double _f32(double value) => (Float32List(1)..[0] = value)[0];
