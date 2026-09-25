import 'package:flutter_test/flutter_test.dart';
import 'package:irrigo/models/device.dart';
import 'package:irrigo/models/irrigation_zone.dart';

void main() {
  // Same shape as the spec §9 example / what the ESP32 writes.
  final map = {
    'name': 'Front Garden',
    'moisture': 42,
    'threshold': 35,
    'pumpState': false,
    'pumpCommand': false,
    'autoMode': true,
    'online': true,
    'lastSeen': 1789980000,
    'lastWatered': 1789976400,
  };

  test('parses a zone', () {
    final z = IrrigationZone.fromMap('esp32_01', 'zone1', map);
    expect(z.name, 'Front Garden');
    expect(z.moisture, 42);
    expect(z.threshold, 35);
    expect(z.stopAt, 45);
    expect(z.autoMode, isTrue);
    expect(z.isDry, isFalse);
    expect(z.lastSeen, DateTime.fromMillisecondsSinceEpoch(1789980000 * 1000));
  });

  test('handles missing fields and doubles', () {
    final z = IrrigationZone.fromMap('d', 'zone9', {'moisture': 28.6});
    expect(z.name, 'zone9');
    expect(z.moisture, 29);
    expect(z.threshold, 30);
    expect(z.autoMode, isTrue);
    expect(z.lastSeen, isNull);
    expect(z.lastWatered, isNull);
    expect(z.isDry, isTrue);
  });

  test('offline when lastSeen is too old', () {
    final z = IrrigationZone.fromMap('d', 'z', map);
    final seen = z.lastSeen!;
    expect(z.isOnlineAt(seen.add(const Duration(seconds: 10))), isTrue);
    expect(z.isOnlineAt(seen.add(const Duration(seconds: 31))), isFalse);
  });

  test('pumpPending only in manual mode', () {
    final manual = IrrigationZone.fromMap('d', 'z', {
      ...map,
      'autoMode': false,
      'pumpCommand': true,
    });
    expect(manual.pumpPending, isTrue);
    final auto = IrrigationZone.fromMap('d', 'z', {
      ...map,
      'pumpCommand': true,
    });
    expect(auto.pumpPending, isFalse);
  });

  test('device collects zones sorted', () {
    final d = Device.fromMap('esp32_01', {
      'zones': {'zone2': map, 'zone1': map, 'junk': 5},
    });
    expect(d.zones.map((z) => z.id), ['zone1', 'zone2']);
  });
}
