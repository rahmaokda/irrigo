import 'package:flutter/material.dart';

import '../models/irrigation_zone.dart';
import '../theme/app_theme.dart';

/// Pump state, AUTO/MANUAL switch and manual start/stop.
///
/// Shows the *reported* pumpState, and "Starting…/Stopping…" while a manual
/// pumpCommand hasn't been confirmed by the ESP32 yet (spec §6).
class PumpCard extends StatelessWidget {
  const PumpCard({
    super.key,
    required this.zone,
    required this.online,
    required this.onModeChanged,
    required this.onPumpChanged,
  });

  final IrrigationZone zone;
  final bool online;
  final ValueChanged<bool> onModeChanged; // true = auto
  final ValueChanged<bool> onPumpChanged; // true = on

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final on = zone.pumpState;
    final String status;
    if (zone.pumpPending) {
      status = zone.pumpCommand ? 'Starting…' : 'Stopping…';
    } else {
      status = on ? 'ON' : 'OFF';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  on ? Icons.water_drop : Icons.water_drop_outlined,
                  size: 32,
                  color: on ? AppTheme.wet : null,
                ),
                const SizedBox(width: 12),
                Text('Pump', style: text.titleMedium),
                const Spacer(),
                Text(
                  status,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: on ? AppTheme.wet : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Auto'),
                    icon: Icon(Icons.auto_mode),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Manual'),
                    icon: Icon(Icons.touch_app),
                  ),
                ],
                selected: {zone.autoMode},
                onSelectionChanged: (s) => onModeChanged(s.first),
              ),
            ),
            const SizedBox(height: 12),
            if (zone.autoMode)
              Text(
                'The controller waters below ${zone.threshold}% and stops above ${zone.stopAt}%.',
                style: text.bodyMedium,
              )
            else ...[
              FilledButton.icon(
                onPressed: online
                    ? () => onPumpChanged(!zone.pumpCommand)
                    : null,
                icon: Icon(zone.pumpCommand ? Icons.stop : Icons.play_arrow),
                label: Text(zone.pumpCommand ? 'Stop pump' : 'Start pump'),
                style: zone.pumpCommand
                    ? FilledButton.styleFrom(backgroundColor: AppTheme.offline)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                online
                    ? 'For safety the device stops the pump after 5 minutes.'
                    : 'Device is offline. It waters automatically until it reconnects.',
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
