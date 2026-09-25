import 'package:flutter/material.dart';

import '../models/irrigation_zone.dart';
import '../theme/app_theme.dart';

/// Horizontal moisture bar, orange when below the threshold.
class MoistureBar extends StatelessWidget {
  const MoistureBar({super.key, required this.zone, this.height = 10});

  final IrrigationZone zone;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: zone.moisture / 100,
        minHeight: height,
        color: zone.isDry ? AppTheme.dry : AppTheme.wet,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Large moisture value for the details page.
class MoistureCard extends StatelessWidget {
  const MoistureCard({super.key, required this.zone});

  final IrrigationZone zone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soil moisture', style: text.titleMedium),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${zone.moisture}%',
                  style: text.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                if (zone.isDry)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '⚠️ Dry',
                      style: text.titleMedium?.copyWith(color: AppTheme.dry),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MoistureBar(zone: zone, height: 14),
          ],
        ),
      ),
    );
  }
}
