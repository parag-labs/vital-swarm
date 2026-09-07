import 'package:flutter_test/flutter_test.dart';
import 'package:vital_swarm/core/health.dart';
import 'package:vital_swarm/core/samples.dart';

void main() {
  group('feature extraction', () {
    test('computes plausible averages over the window', () {
      final f = extractFeatures(demoWindow());
      expect(f.avgSteps, greaterThan(0));
      expect(f.avgSleep, inInclusiveRange(4, 10));
      expect(f.avgRestingHr, inInclusiveRange(40, 100));
    });
  });

  group('detection', () {
    test('flags today when it deviates from baseline', () {
      final signals = detect(demoWindow());
      final metrics = signals.map((s) => s.metric).toSet();
      expect(metrics, contains('steps'));
      expect(metrics, contains('sleep'));
      expect(metrics, contains('stress'));
      // steps down, sleep down, stress up
      expect(signals.firstWhere((s) => s.metric == 'steps').direction, -1);
      expect(signals.firstWhere((s) => s.metric == 'stress').direction, 1);
    });

    test('a steady window produces no anomalies', () {
      expect(detect(steadyWindow()), isEmpty);
    });

    test('signals are ordered by magnitude', () {
      final signals = detect(demoWindow());
      for (var i = 1; i < signals.length; i++) {
        expect(signals[i - 1].magnitude, greaterThanOrEqualTo(signals[i].magnitude));
      }
    });

    test('needs at least a few baseline days', () {
      expect(detect([const DaySignals(day: 0, steps: 1, restingHr: 60, sleepHours: 7, stress: 0.3)]), isEmpty);
    });

    test('is deterministic', () {
      expect(detect(demoWindow()).map((s) => s.metric).toList(), detect(demoWindow()).map((s) => s.metric).toList());
    });
  });

  group('insight fusion', () {
    test('fuses low sleep + high strain into a single gentle nudge', () {
      final insights = analyze(demoWindow());
      expect(insights.any((i) => i.level == InsightLevel.gentleNudge && i.detail.toLowerCase().contains('pace')), isTrue);
    });

    test('a steady day yields a calm, positive insight', () {
      final insights = analyze(steadyWindow());
      expect(insights.single.level, InsightLevel.positive);
    });

    test('insights are non-empty and calm (never empty-handed)', () {
      final insights = analyze(demoWindow());
      expect(insights, isNotEmpty);
      for (final i in insights) {
        expect(i.title.isNotEmpty, isTrue);
        expect(i.detail.isNotEmpty, isTrue);
      }
    });

    test('is deterministic', () {
      expect(analyze(demoWindow()).map((i) => i.title).toList(), analyze(demoWindow()).map((i) => i.title).toList());
    });
  });
}
