/// Deterministic seeded sample data so the demo looks alive and the tests are reproducible.
library;

import 'health.dart';

/// A 14-day window with a stable baseline and a distinctive "today" for the demo: fewer steps,
/// less sleep, and higher strain than usual — so the pipeline surfaces a gentle nudge.
List<DaySignals> demoWindow() {
  final days = <DaySignals>[];
  // Baseline days 13..1 — steady, healthy patterns.
  for (var d = 13; d >= 1; d--) {
    final wobble = (d % 3) - 1; // -1, 0, 1 cycle
    days.add(DaySignals(
      day: d,
      steps: 8600 + wobble * 400,
      restingHr: 58 + (d.isEven ? 1 : 0),
      sleepHours: 7.4 + wobble * 0.2,
      stress: 0.32 + wobble * 0.03,
    ));
  }
  // Today (day 0): a noticeably off day.
  days.add(const DaySignals(day: 0, steps: 4200, restingHr: 64, sleepHours: 5.6, stress: 0.62));
  return days;
}

/// A calm, steady window where nothing deviates — the pipeline should report "a steady day".
List<DaySignals> steadyWindow() {
  return [
    for (var d = 6; d >= 0; d--) DaySignals(day: d, steps: 8500, restingHr: 58, sleepHours: 7.4, stress: 0.33),
  ];
}
