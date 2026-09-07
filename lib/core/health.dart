/// The on-device health pipeline — the deterministic core of VitalSwarm. It takes a day's worth
/// of multi-signal samples (steps, resting heart rate, sleep hours, an HRV-based stress proxy),
/// extracts simple features, detects patterns/anomalies against personal baselines, and fuses
/// them into calm, non-alarmist insights. All local, all pure Dart — unit-testable and
/// reproducible. No raw data ever leaves this layer.
library;

import 'dart:math' as math;

/// One day's aggregated on-device signals. In a real build these come from HealthKit /
/// Health Connect and a wearable; here they are plain numbers so the pipeline is testable.
class DaySignals {
  const DaySignals({required this.day, required this.steps, required this.restingHr, required this.sleepHours, required this.stress});

  /// Days ago (0 = today).
  final int day;
  final int steps;
  final int restingHr; // bpm
  final double sleepHours;
  final double stress; // 0..1, higher = more strain (HRV proxy)
}

/// A detected pattern or anomaly.
class Signal {
  const Signal({required this.metric, required this.direction, required this.magnitude, required this.summary});

  final String metric;

  /// +1 = above baseline, -1 = below.
  final int direction;

  /// How many standard deviations from baseline (absolute).
  final double magnitude;

  final String summary;
}

/// Severity of an insight — deliberately gentle wording, never alarmist.
enum InsightLevel { positive, notice, gentleNudge }

/// A calm, fused insight surfaced to the user.
class Insight {
  const Insight({required this.title, required this.detail, required this.level});
  final String title;
  final String detail;
  final InsightLevel level;
}

double _mean(Iterable<double> xs) {
  final list = xs.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

double _std(Iterable<double> xs) {
  final list = xs.toList();
  if (list.length < 2) return 0;
  final m = _mean(list);
  final v = list.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / (list.length - 1);
  return math.sqrt(v);
}

/// Extracted features across the window.
class Features {
  const Features({required this.avgSteps, required this.avgSleep, required this.avgRestingHr, required this.avgStress});
  final double avgSteps;
  final double avgSleep;
  final double avgRestingHr;
  final double avgStress;
}

/// Extract simple aggregate features from a window of days.
Features extractFeatures(List<DaySignals> days) {
  return Features(
    avgSteps: _mean(days.map((d) => d.steps.toDouble())),
    avgSleep: _mean(days.map((d) => d.sleepHours)),
    avgRestingHr: _mean(days.map((d) => d.restingHr.toDouble())),
    avgStress: _mean(days.map((d) => d.stress)),
  );
}

/// Compare today (day 0) against the baseline of the preceding days and emit signals for any
/// metric that deviates by at least [threshold] standard deviations. Deterministic.
List<Signal> detect(List<DaySignals> days, {double threshold = 1.0}) {
  final today = days.firstWhere((d) => d.day == 0, orElse: () => days.first);
  final baseline = days.where((d) => d.day != 0).toList();
  if (baseline.length < 2) return const [];

  final signals = <Signal>[];

  void check(String metric, double todayVal, Iterable<double> hist, String upSummary, String downSummary) {
    final m = _mean(hist);
    final s = _std(hist);
    if (s == 0) return;
    final z = (todayVal - m) / s;
    if (z.abs() >= threshold) {
      signals.add(Signal(metric: metric, direction: z > 0 ? 1 : -1, magnitude: z.abs(), summary: z > 0 ? upSummary : downSummary));
    }
  }

  check('steps', today.steps.toDouble(), baseline.map((d) => d.steps.toDouble()), 'more active than usual', 'less active than usual');
  check('sleep', today.sleepHours, baseline.map((d) => d.sleepHours), 'slept longer than usual', 'slept less than usual');
  check('restingHr', today.restingHr.toDouble(), baseline.map((d) => d.restingHr.toDouble()), 'resting heart rate is up', 'resting heart rate is down');
  check('stress', today.stress, baseline.map((d) => d.stress), 'strain is higher than usual', 'strain is lower than usual');

  signals.sort((a, b) => b.magnitude.compareTo(a.magnitude));
  return signals;
}

/// Fuse detected signals into calm insights. Combines related signals (e.g. low sleep + high
/// strain) into a single gentle nudge. Never alarmist. Deterministic.
List<Insight> insightsFrom(List<Signal> signals) {
  if (signals.isEmpty) {
    return const [Insight(title: 'A steady day', detail: 'Everything looks close to your usual patterns.', level: InsightLevel.positive)];
  }

  final byMetric = {for (final s in signals) s.metric: s};
  final out = <Insight>[];

  // Multi-signal fusion: poor sleep + elevated strain.
  final sleep = byMetric['sleep'];
  final stress = byMetric['stress'];
  if (sleep != null && sleep.direction < 0 && stress != null && stress.direction > 0) {
    out.add(const Insight(
      title: 'A lighter day might help',
      detail: 'You slept less and your strain is up. Consider an easier pace and an earlier wind-down tonight.',
      level: InsightLevel.gentleNudge,
    ));
  }

  final steps = byMetric['steps'];
  if (steps != null && steps.direction > 0) {
    out.add(const Insight(title: 'Nicely active', detail: 'You moved more than usual today — a good sign.', level: InsightLevel.positive));
  } else if (steps != null && steps.direction < 0) {
    out.add(const Insight(title: 'A short walk?', detail: 'You\'ve been less active than usual; a brief walk could feel good.', level: InsightLevel.gentleNudge));
  }

  final hr = byMetric['restingHr'];
  if (hr != null && hr.direction > 0) {
    out.add(const Insight(title: 'Resting heart rate is up', detail: 'It\'s a little higher than your baseline. Often just tiredness — worth a gentle eye on.', level: InsightLevel.notice));
  }

  // Ensure we always say something if there were signals but no fusion matched.
  if (out.isEmpty) {
    final top = signals.first;
    out.add(Insight(title: 'A small change today', detail: 'Your ${top.metric} is ${top.summary}.', level: InsightLevel.notice));
  }
  return out;
}

/// Convenience: run the full pipeline on a window of days.
List<Insight> analyze(List<DaySignals> days, {double threshold = 1.0}) => insightsFrom(detect(days, threshold: threshold));
