/*
 * IRRIGO - ESP32 smart irrigation controller
 *
 * Reads a capacitive soil moisture sensor, runs the pump through a relay
 * (auto mode with hysteresis, or manual mode from the app) and syncs state,
 * settings and commands with Firebase Realtime Database.
 *
 * Wiring (see README): sensor AOUT -> GPIO36, relay IN -> GPIO17.
 * Based on the esp32io.com automatic irrigation example.
 *
 * Libraries: "Firebase Arduino Client Library for ESP8266 and ESP32" by Mobizt
 * (Firebase_ESP_Client).
 */

#include "config.h"
#include "soil_moisture.h"
#include "pump.h"
#include "irrigation_controller.h"
#include "firebase_service.h"

// If Firebase can't be reached for this long, fall back to local auto mode so a
// stale manual command can't keep the pump on (or off) indefinitely.
#define CLOUD_STALE_MS (60UL * 1000UL)

SoilMoistureSensor soil(MOISTURE_PIN, SOIL_RAW_DRY, SOIL_RAW_WET);
Pump pump(RELAY_PIN, RELAY_ACTIVE_HIGH);
IrrigationController controller(HYSTERESIS_PERCENT, MAX_PUMP_RUN_MS, PUMP_COOLDOWN_MS);
FirebaseService cloud;

ZoneConfig cfg = {DEFAULT_THRESHOLD, true, false};
uint32_t lastWatered = 0;

unsigned long lastSensorMs = 0;
unsigned long lastFirebaseMs = 0;
unsigned long lastHistoryMs = 0;
unsigned long lastConfigOkMs = 0;
bool haveConfig = false;       // at least one successful config read
bool publishNow = false;       // pump changed -> report immediately
bool clearCommand = false;     // pumpCommand must be reset to false in Firebase

void setup() {
  Serial.begin(115200);
  pump.begin();  // relay OFF first thing
  soil.begin();
  cloud.begin();
}

bool cloudStale() {
  return !haveConfig || millis() - lastConfigOkMs > CLOUD_STALE_MS;
}

// readSoilMoisture -> runIrrigationController -> controlPump
void runControl() {
  soil.read();

  bool autoMode = cfg.autoMode || cloudStale();
  bool wasOn = pump.isOn();
  bool want = controller.update(soil.percent(), cfg.threshold, autoMode, cfg.pumpCommand,
                                wasOn, pump.onSinceMs());

  if (controller.safetyTripped()) {
    Serial.println("Safety: max pump run time reached, stopping pump");
    if (cfg.pumpCommand) {
      cfg.pumpCommand = false;
      clearCommand = true;
    }
  }

  if (want != wasOn) {
    pump.set(want);
    if (want) {
      uint32_t t = FirebaseService::now();
      if (t) lastWatered = t;
    }
    publishNow = true;
  }

  Serial.printf("Moisture %3d%% (raw %4d) | pump %-3s | %s%s | threshold %d%%\n",
                soil.percent(), soil.raw(), pump.isOn() ? "ON" : "OFF",
                autoMode ? "AUTO" : "MANUAL", cloudStale() ? " (offline)" : "",
                cfg.threshold);
}

// readFirebaseConfiguration / readFirebaseCommands -> publishCurrentState / updateLastSeen
void syncFirebase() {
  if (!cloud.ready()) return;

  bool prevAuto = cfg.autoMode;
  if (cloud.readConfig(cfg)) {
    haveConfig = true;
    lastConfigOkMs = millis();

    // Switching back to AUTO: drop any leftover manual command so it can't
    // take effect the next time manual mode is enabled.
    if (cfg.autoMode && !prevAuto && cfg.pumpCommand) clearCommand = true;
    if (clearCommand) {
      cfg.pumpCommand = false;
      if (cloud.writePumpCommand(false)) clearCommand = false;
    }
  }

  ZoneState state = {soil.percent(), pump.isOn(), lastWatered};
  if (cloud.publishState(state)) publishNow = false;
}

void loop() {
  unsigned long now = millis();

  if (now - lastSensorMs >= SENSOR_INTERVAL_MS) {
    lastSensorMs = now;
    runControl();
  }

  if (publishNow || now - lastFirebaseMs >= FIREBASE_INTERVAL_MS) {
    lastFirebaseMs = now;
    syncFirebase();
  }

  // Needs a real clock (history is keyed by epoch time).
  if (now - lastHistoryMs >= HISTORY_INTERVAL_MS && FirebaseService::now() && cloud.ready()) {
    lastHistoryMs = now;
    cloud.pushHistory(soil.percent());
  }
}
