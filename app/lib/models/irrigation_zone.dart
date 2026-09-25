/// One zone (sensor + pump) at `users/<uid>/devices/<deviceId>/zones/<zoneId>`.
///
/// Fields written by the app: name, threshold, autoMode, pumpCommand.
/// Fields written by the ESP32: moisture, pumpState, online, lastSeen, lastWatered.
class IrrigationZone {
  const IrrigationZone({
    required this.deviceId,
    required this.id,
    required this.name,
    required this.moisture,
    required this.threshold,
    required this.pumpState,
    required this.pumpCommand,
    required this.autoMode,
    required this.online,
    this.lastSeen,
    this.lastWatered,
  });

  /// The ESP32 reports every 5 s; after this long without an update it is
  /// considered offline.
  static const offlineAfter = Duration(seconds: 30);

  /// Must match HYSTERESIS_PERCENT in the ESP32 config.h.
  static const hysteresis = 10;

  final String deviceId;
  final String id;
  final String name;
  final int moisture;
  final int threshold;
  final bool pumpState;
  final bool pumpCommand;
  final bool autoMode;
  final bool online;
  final DateTime? lastSeen;
  final DateTime? lastWatered;

  factory IrrigationZone.fromMap(
    String deviceId,
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return IrrigationZone(
      deviceId: deviceId,
      id: id,
      name: (map['name'] as String?) ?? id,
      moisture: _int(map['moisture']),
      threshold: _int(map['threshold'], 30),
      pumpState: map['pumpState'] == true,
      pumpCommand: map['pumpCommand'] == true,
      autoMode: map['autoMode'] != false,
      online: map['online'] == true,
      lastSeen: _time(map['lastSeen']),
      lastWatered: _time(map['lastWatered']),
    );
  }

  /// Online only if the ESP32 says so AND it reported recently.
  bool isOnlineAt(DateTime now) =>
      online && lastSeen != null && now.difference(lastSeen!) < offlineAfter;

  bool get isDry => moisture < threshold;

  /// The pump turns off again above this value (auto mode).
  int get stopAt => threshold + hysteresis;

  /// Manual command sent but the ESP32 hasn't reported the new state yet.
  bool get pumpPending => !autoMode && pumpCommand != pumpState;

  static int _int(Object? v, [int fallback = 0]) =>
      v is num ? v.round() : fallback;

  /// Epoch seconds -> DateTime. 0 / missing means "never".
  static DateTime? _time(Object? v) => v is num && v > 0
      ? DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000)
      : null;
}

/// One entry of `users/<uid>/moistureHistory/<deviceId>/<zoneId>/<epoch>`: moisture.
class MoisturePoint {
  const MoisturePoint(this.time, this.moisture);

  final DateTime time;
  final int moisture;
}
