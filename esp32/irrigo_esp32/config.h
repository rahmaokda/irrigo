#pragma once

// ---------------- Hardware pins ----------------
#define RELAY_PIN    17  // GPIO17 -> relay IN
#define MOISTURE_PIN 36  // GPIO36 (ADC0) -> sensor AOUT

// Most relay modules with a H/L jumper work either way. Set to false if your
// relay turns ON when the pin is LOW.
#define RELAY_ACTIVE_HIGH true

// ---------------- Sensor calibration ----------------
// Measure these on YOUR sensor (spec section 8): read the raw value in dry air /
// dry soil, then in well-watered soil, and put the numbers here.
// Capacitive sensors read HIGHER when dry. Defaults match the readings seen so
// far (~4095 dry, ~3600-3700 wet) - replace with your own measurements.
#define SOIL_RAW_DRY 4095
#define SOIL_RAW_WET 3600
#define SOIL_SAMPLES 10  // readings averaged per sample

// ---------------- Irrigation logic ----------------
// Pump turns ON below `threshold` % and OFF above `threshold + HYSTERESIS` %.
// `threshold` is read from Firebase; this is only the value used until then.
#define DEFAULT_THRESHOLD   30
#define HYSTERESIS_PERCENT  10
// Safety cut-off: never run the pump longer than this in one go (auto or manual).
#define MAX_PUMP_RUN_MS     (5UL * 60UL * 1000UL)
// Pause after a safety cut-off before auto mode may start the pump again.
#define PUMP_COOLDOWN_MS    (2UL * 60UL * 1000UL)

// ---------------- Timing ----------------
#define SENSOR_INTERVAL_MS   1000UL           // read sensor + run controller
#define FIREBASE_INTERVAL_MS 5000UL           // read config/commands + publish state
#define HISTORY_INTERVAL_MS  (10UL * 60UL * 1000UL)  // append to moistureHistory

// ---------------- Identity in the database ----------------
// Data lives under users/<uid>/devices/<DEVICE_ID>/zones/<ZONE_ID>
#define DEVICE_ID "esp32_01"
#define ZONE_ID   "zone1"
#define ZONE_NAME "Front Garden"  // only written when the zone is first created
