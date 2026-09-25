# IRRIGO – ESP32 firmware

Reads the soil moisture sensor, drives the pump relay and syncs with Firebase
Realtime Database so the Flutter app can monitor and control the zone.

## Wiring

| ESP32            | Connects to                     |
|------------------|---------------------------------|
| 3.3V             | Moisture sensor VCC             |
| GND              | Moisture sensor GND, relay GND  |
| GPIO36 (ADC0)    | Moisture sensor AOUT            |
| VIN (5V)         | Relay VCC                       |
| GPIO17           | Relay IN                        |

The pump is powered by the 12V adapter, switched through the relay's COM/NO contacts.

## Setup

1. Arduino IDE → Boards Manager → install **esp32** by Espressif.
2. Library Manager → install **Firebase Arduino Client Library for ESP8266 and ESP32** by Mobizt
   (header `Firebase_ESP_Client.h`).
3. Firebase console:
   - Authentication → enable **Email/Password**. The ESP32 signs in with the same
     account the user uses in the app, so its data lands under that user's `uid`.
   - Realtime Database → create a database and paste `../firebase/database.rules.json` into Rules.
4. Copy `irrigo_esp32/secrets.example.h` to `irrigo_esp32/secrets.h` and fill in Wi-Fi,
   API key, database URL and the account email/password. `secrets.h` is git-ignored.
5. Adjust `irrigo_esp32/config.h` (pins, relay polarity, calibration, device/zone id), then upload.
   Serial monitor runs at 115200 baud.

## Calibration

Open the serial monitor and note the `raw` value with the sensor in dry soil and in
well-watered soil. Put them in `SOIL_RAW_DRY` / `SOIL_RAW_WET` in `config.h`.

## Database layout

```
users/<uid>/devices/<DEVICE_ID>/
  zones/<ZONE_ID>/
    name          app      (created by ESP32 on first run)
    threshold     app      pump turns ON below this %, OFF above threshold + HYSTERESIS_PERCENT
    autoMode      app      true = ESP32 decides, false = follows pumpCommand
    pumpCommand   app      requested pump state in manual mode
    moisture      ESP32    0-100 %
    pumpState     ESP32    actual relay state
    online        ESP32    always true while reporting — use lastSeen for offline detection
    lastSeen      ESP32    epoch seconds, updated every 5 s
    lastWatered   ESP32    epoch seconds when the pump last started
  moistureHistory/<ZONE_ID>/<epoch seconds>: moisture %   (every 10 min)
```

History is kept outside `zones/` so the ESP32 (and the dashboard) never download it
when reading the current state.

The app should treat the device as offline when `lastSeen` is older than ~30 s.

## Behaviour

- **Auto mode:** ON below `threshold`, OFF above `threshold + 10` (hysteresis).
- **Manual mode:** pump follows `pumpCommand`.
- **Switching back to auto** resets `pumpCommand` to `false`, so an old manual command
  can't fire later.
- **Safety:** the pump never runs longer than 5 min in one go (either mode); it then
  stays off for a 2 min cooldown and `pumpCommand` is reset.
- **No network:** if Firebase hasn't been reachable for 60 s the ESP32 runs in local
  auto mode with the last known threshold.
