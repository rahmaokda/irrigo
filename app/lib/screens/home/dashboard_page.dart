import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../utils/format.dart';
import '../../widgets/device_card.dart';
import '../device/device_details_page.dart';

/// "Your gardens": one live card per zone across all devices (spec §10.2).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user, required this.devices});

  final User user;
  final DeviceService devices;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Created once so rebuilds don't re-subscribe.
  late final Stream<List<Device>> _stream = widget.devices.watchDevices();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = widget.user.displayName?.split(' ').first ?? '';

    return SafeArea(
      child: StreamBuilder<List<Device>>(
        stream: _stream,
        builder: (context, snap) {
          final Widget body;
          if (snap.hasError) {
            body = _message(
              context,
              Icons.error_outline,
              'Could not load your gardens',
              '${snap.error}',
            );
          } else if (!snap.hasData) {
            body = const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            final zones = [for (final d in snap.data!) ...d.zones];
            body = zones.isEmpty
                ? _message(
                    context,
                    Icons.sensors_off,
                    'No devices yet',
                    'Power on your ESP32 and sign it in with this account. '
                        'Its garden will appear here automatically.',
                  )
                : Column(
                    children: [
                      for (final zone in zones)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DeviceCard(
                            zone: zone,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DeviceDetailsPage(
                                  devices: widget.devices,
                                  deviceId: zone.deviceId,
                                  zoneId: zone.id,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${greeting(DateTime.now())}${name.isEmpty ? '' : ', $name'} 👋',
                style: text.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Your gardens',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              body,
            ],
          );
        },
      ),
    );
  }

  Widget _message(
    BuildContext context,
    IconData icon,
    String title,
    String detail,
  ) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: text.titleMedium),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: text.bodyMedium),
        ],
      ),
    );
  }
}
