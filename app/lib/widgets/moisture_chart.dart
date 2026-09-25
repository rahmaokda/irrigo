import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/irrigation_zone.dart';
import '../theme/app_theme.dart';

/// Moisture over time with the watering threshold as a dashed line.
class MoistureChart extends StatelessWidget {
  const MoistureChart({
    super.key,
    required this.points,
    required this.threshold,
  });

  final List<MoisturePoint> points;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    if (points.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Not enough data yet.\nThe device saves a reading every 10 minutes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    double x(DateTime t) => t.millisecondsSinceEpoch / 1000;
    final minX = x(points.first.time);
    final maxX = x(points.last.time);
    final span = maxX - minX;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: minX,
          maxX: maxX,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 40,
                getTitlesWidget: (v, _) =>
                    Text('${v.toInt()}%', style: labelStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: span > 0 ? span / 4 : 1,
                getTitlesWidget: (v, meta) {
                  // Skip the edge labels: the right one gets clipped.
                  if (v == meta.min || v == meta.max) {
                    return const SizedBox.shrink();
                  }
                  final t = DateTime.fromMillisecondsSinceEpoch(
                    (v * 1000).toInt(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat.Hm().format(t), style: labelStyle),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: threshold.toDouble(),
                color: AppTheme.dry,
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final t = DateTime.fromMillisecondsSinceEpoch(
                  (s.x * 1000).toInt(),
                );
                return LineTooltipItem(
                  '${s.y.toInt()}%\n${DateFormat.jm().format(t)}',
                  TextStyle(color: scheme.onInverseSurface),
                );
              }).toList(),
              getTooltipColor: (_) => scheme.inverseSurface,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final p in points)
                  FlSpot(x(p.time), p.moisture.toDouble()),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppTheme.wet,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.wet.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
