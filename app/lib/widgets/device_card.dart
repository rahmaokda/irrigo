import 'package:flutter/material.dart';

import '../models/irrigation_zone.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'moisture_card.dart';
import 'status_indicator.dart';

/// Dashboard card for one zone (spec §10.2).
class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.zone, required this.onTap});

  final IrrigationZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      // Highlight zones that are currently being watered.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: zone.pumpState
            ? const BorderSide(color: AppTheme.wet, width: 2)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zone.name,
                      style: text.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusIndicator(zone: zone, showLastSeen: false),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Moisture', style: text.bodyLarge),
                  const Spacer(),
                  Text(
                    '${zone.moisture}%${zone.isDry ? ' ⚠️' : ''}',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: zone.isDry ? AppTheme.dry : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MoistureBar(zone: zone),
              const SizedBox(height: 16),
              _row(
                context,
                'Pump',
                zone.pumpState ? 'ON' : 'OFF',
                highlight: zone.pumpState,
              ),
              _row(context, 'Mode', zone.autoMode ? 'AUTO' : 'MANUAL'),
              const SizedBox(height: 8),
              LiveClock(
                interval: const Duration(minutes: 1),
                builder: (context, now) => Text(
                  zone.lastWatered == null
                      ? 'Not watered yet'
                      : 'Last watered: ${shortDateTime(zone.lastWatered!, now)}',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: text.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? AppTheme.wet : null,
            ),
          ),
        ],
      ),
    );
  }
}
