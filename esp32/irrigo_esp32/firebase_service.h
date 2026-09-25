#pragma once
#include <Arduino.h>

// Settings/commands written by the Flutter app.
struct ZoneConfig {
  int threshold;
  bool autoMode;
  bool pumpCommand;
};

// State reported by the ESP32.
struct ZoneState {
  int moisture;
  bool pumpState;
  uint32_t lastWatered;  // epoch seconds, 0 = never
};

// Wraps Wi-Fi, NTP time and Firebase Realtime Database access.
// Paths: users/<uid>/devices/<deviceId>/zones/<zoneId>
//        users/<uid>/moistureHistory/<deviceId>/<zoneId>/<epoch>
class FirebaseService {
 public:
  void begin();
  bool ready();  // Wi-Fi connected and Firebase signed in

  // Reads threshold/autoMode/pumpCommand into `cfg`. Fields missing in the
  // database keep their current value. Creates the zone with `cfg` as
  // defaults if it doesn't exist yet. Returns false on error.
  bool readConfig(ZoneConfig &cfg);
  bool writePumpCommand(bool on);
  bool publishState(const ZoneState &state);
  bool pushHistory(int moisture);

  static uint32_t now();  // epoch seconds from NTP, 0 if not synced yet

 private:
  bool createZone(const ZoneConfig &defaults);
  String zonePath() const;
  String devicePath() const;
};
