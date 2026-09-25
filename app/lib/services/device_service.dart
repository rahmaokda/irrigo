import 'package:firebase_database/firebase_database.dart';

import '../models/device.dart';
import '../models/irrigation_zone.dart';
import 'firebase_service.dart';

/// Live device/zone data and the commands the app is allowed to send.
///
/// Uses real-time listeners (onValue), never polling: the UI rebuilds whenever
/// the ESP32 writes new values.
class DeviceService {
  DeviceService(this.uid);

  final String uid;

  /// All devices and their zones for the dashboard.
  Stream<List<Device>> watchDevices() {
    return FirebaseService.devices(uid).onValue.map((event) {
      final devices = <Device>[];
      for (final child in event.snapshot.children) {
        final value = child.value;
        if (child.key != null && value is Map) {
          devices.add(Device.fromMap(child.key!, value));
        }
      }
      devices.sort((a, b) => a.id.compareTo(b.id));
      return devices;
    });
  }

  /// A single zone for the details page. Emits null if it gets deleted.
  Stream<IrrigationZone?> watchZone(String deviceId, String zoneId) {
    return FirebaseService.zone(uid, deviceId, zoneId).onValue.map((event) {
      final value = event.snapshot.value;
      return value is Map
          ? IrrigationZone.fromMap(deviceId, zoneId, value)
          : null;
    });
  }

  /// Moisture readings from the last [window] (default 24 h), oldest first.
  Stream<List<MoisturePoint>> watchHistory(
    String deviceId,
    String zoneId, {
    Duration window = const Duration(hours: 24),
  }) {
    final since =
        DateTime.now().subtract(window).millisecondsSinceEpoch ~/ 1000;
    // Keys are epoch seconds (10 digits), so string order == time order.
    final query = FirebaseService.history(
      uid,
      deviceId,
      zoneId,
    ).orderByKey().startAt(since.toString());
    return query.onValue.map((event) {
      final points = <MoisturePoint>[];
      for (final child in event.snapshot.children) {
        final seconds = int.tryParse(child.key ?? '');
        final value = child.value;
        if (seconds != null && value is num) {
          points.add(
            MoisturePoint(
              DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
              value.round(),
            ),
          );
        }
      }
      return points;
    });
  }

  DatabaseReference _zone(IrrigationZone zone) =>
      FirebaseService.zone(uid, zone.deviceId, zone.id);

  /// Switching mode always resets pumpCommand in the same write, so an old
  /// manual command can never take effect after a mode change (spec §13).
  Future<void> setAutoMode(IrrigationZone zone, bool autoMode) =>
      _zone(zone).update({'autoMode': autoMode, 'pumpCommand': false});

  /// Only meaningful in manual mode; the ESP32 ignores it in auto mode.
  Future<void> setPumpCommand(IrrigationZone zone, bool on) =>
      _zone(zone).update({'pumpCommand': on});

  Future<void> setThreshold(IrrigationZone zone, int threshold) =>
      _zone(zone).update({'threshold': threshold.clamp(0, 100)});

  Future<void> rename(IrrigationZone zone, String name) =>
      _zone(zone).update({'name': name.trim()});
}
