import 'irrigation_zone.dart';

/// One ESP32 at `users/<uid>/devices/<deviceId>`.
class Device {
  const Device({required this.id, required this.zones});

  final String id;
  final List<IrrigationZone> zones;

  factory Device.fromMap(String id, Map<dynamic, dynamic> map) {
    final zonesMap = map['zones'];
    final zones = <IrrigationZone>[];
    if (zonesMap is Map) {
      zonesMap.forEach((zoneId, value) {
        if (value is Map) {
          zones.add(IrrigationZone.fromMap(id, zoneId.toString(), value));
        }
      });
    }
    zones.sort((a, b) => a.id.compareTo(b.id));
    return Device(id: id, zones: zones);
  }
}
