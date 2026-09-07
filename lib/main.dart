import 'package:flutter/material.dart';
import 'core/health.dart';
import 'core/samples.dart';

void main() => runApp(const VitalSwarmApp());

class VitalSwarmApp extends StatelessWidget {
  const VitalSwarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSwarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF090C10)),
      home: const HealthScreen(),
    );
  }
}

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _offDay = true;

  List<DaySignals> get _window => _offDay ? demoWindow() : steadyWindow();

  @override
  Widget build(BuildContext context) {
    final days = _window;
    final today = days.firstWhere((d) => d.day == 0);
    final features = extractFeatures(days);
    final insights = analyze(days);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('VitalSwarm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _offDay = !_offDay),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0x2234D399), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x3334D399))),
                          child: Text(_offDay ? 'Today: off day' : 'Today: steady', style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const Text('A calm, private read on your day', style: TextStyle(color: Color(0xFF8891A6), fontSize: 12.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat('Steps', '${today.steps}', Icons.directions_walk_rounded, const Color(0xFF7C6CFF)),
                      _stat('Sleep', '${today.sleepHours.toStringAsFixed(1)}h', Icons.bedtime_outlined, const Color(0xFF34D9C8)),
                      _stat('Rest HR', '${today.restingHr}', Icons.favorite_border, const Color(0xFFF472B6)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF12151E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x22FFFFFF))),
                    child: Row(
                      children: [
                        _flow('Sensors', Icons.sensors),
                        _arrow(),
                        _flow('On-device', Icons.smartphone),
                        _arrow(),
                        _flow('Insights', Icons.lightbulb_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 13, color: Color(0xFF6B7488)),
                      SizedBox(width: 6),
                      Expanded(child: Text('Raw signals stay on your device. Only you see them.', style: TextStyle(color: Color(0xFF6B7488), fontSize: 11))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Insights', style: TextStyle(color: Color(0xFF98A2B8), fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: insights.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _InsightCard(insight: insights[i]),
                    ),
                  ),
                  Text('7-day averages: ${features.avgSteps.round()} steps · ${features.avgSleep.toStringAsFixed(1)}h sleep · ${features.avgRestingHr.round()} bpm',
                      style: const TextStyle(color: Color(0xFF6B7488), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF12151E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x22FFFFFF))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _flow(String label, IconData icon) {
    return Column(
      children: [
        CircleAvatar(radius: 16, backgroundColor: const Color(0x227C6CFF), child: Icon(icon, size: 16, color: const Color(0xFFB9A7FF))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 10.5)),
      ],
    );
  }

  Widget _arrow() => const Expanded(child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF3A4152)));
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.level) {
      InsightLevel.positive => (const Color(0xFF34D399), Icons.check_circle_outline),
      InsightLevel.notice => (const Color(0xFF7C6CFF), Icons.info_outline),
      InsightLevel.gentleNudge => (const Color(0xFF34D9C8), Icons.spa_outlined),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3), top: const BorderSide(color: Color(0x22FFFFFF)), right: const BorderSide(color: Color(0x22FFFFFF)), bottom: const BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(insight.detail, style: const TextStyle(color: Color(0xFFC7CEDB), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
