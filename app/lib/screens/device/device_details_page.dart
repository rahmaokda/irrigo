import 'package:flutter/material.dart';

import '../../models/irrigation_zone.dart';
import '../../services/device_service.dart';
import '../../utils/format.dart';
import '../../widgets/moisture_card.dart';
import '../../widgets/moisture_chart.dart';
import '../../widgets/pump_card.dart';
import '../../widgets/status_indicator.dart';

/// Everything about one zone, with controls (spec §10.3).
class DeviceDetailsPage extends StatefulWidget {
  const DeviceDetailsPage({
    super.key,
    required this.devices,
    required this.deviceId,
    required this.zoneId,
  });

  final DeviceService devices;
  final String deviceId;
  final String zoneId;

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  late final Stream<IrrigationZone?> _zone = widget.devices.watchZone(
    widget.deviceId,
    widget.zoneId,
  );
  late final Stream<List<MoisturePoint>> _history = widget.devices.watchHistory(
    widget.deviceId,
    widget.zoneId,
  );

  /// Slider position while dragging; written to Firebase on release.
  double? _dragThreshold;

  /// Runs a Firebase write and shows a message if it fails.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _rename(IrrigationZone zone) async {
    final controller = TextEditingController(text: zone.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename garden'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await _write(() => widget.devices.rename(zone, name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<IrrigationZone?>(
      stream: _zone,
      builder: (context, snap) {
        final zone = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(zone?.name ?? ''),
            actions: [
              if (zone != null)
                IconButton(
                  tooltip: 'Rename',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _rename(zone),
                ),
            ],
          ),
          body: snap.hasError
              ? Center(child: Text('${snap.error}'))
              : !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : zone == null
              ? const Center(child: Text('This garden no longer exists.'))
              : _body(context, zone),
        );
      },
    );
  }

  Widget _body(BuildContext context, IrrigationZone zone) {
    final text = Theme.of(context).textTheme;
    final threshold = _dragThreshold ?? zone.threshold.toDouble();

    return LiveClock(
      builder: (context, now) {
        final online = zone.isOnlineAt(now);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatusIndicator(zone: zone),
            const SizedBox(height: 16),
            MoistureCard(zone: zone),
            const SizedBox(height: 16),
            PumpCard(
              zone: zone,
              online: online,
              onModeChanged: (auto) =>
                  _write(() => widget.devices.setAutoMode(zone, auto)),
              onPumpChanged: (on) =>
                  _write(() => widget.devices.setPumpCommand(zone, on)),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Watering threshold', style: text.titleMedium),
                        const Spacer(),
                        Text(
                          '${threshold.round()}%',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: threshold,
                      min: 0,
                      max: 90, // stop point = threshold + 10 must stay <= 100
                      divisions: 90,
                      label: '${threshold.round()}%',
                      onChanged: (v) => setState(() => _dragThreshold = v),
                      onChangeEnd: (v) async {
                        await _write(
                          () => widget.devices.setThreshold(zone, v.round()),
                        );
                        if (mounted) setState(() => _dragThreshold = null);
                      },
                    ),
                    Text(
                      'Starts watering below ${threshold.round()}%, '
                      'stops above ${threshold.round() + IrrigationZone.hysteresis}%.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text('Last 24 hours', style: text.titleMedium),
                    ),
                    StreamBuilder<List<MoisturePoint>>(
                      stream: _history,
                      builder: (context, snap) => snap.hasData
                          ? MoistureChart(
                              points: snap.data!,
                              threshold: zone.threshold,
                            )
                          : const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Last watered'),
                    trailing: Text(
                      zone.lastWatered == null
                          ? 'Never'
                          : shortDateTime(zone.lastWatered!, now),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.wifi),
                    title: const Text('Last update'),
                    trailing: Text(
                      zone.lastSeen == null
                          ? 'Never'
                          : timeAgo(zone.lastSeen!, now),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.memory),
                    title: const Text('Device'),
                    trailing: Text('${zone.deviceId} / ${zone.id}'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
