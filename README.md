# IRRIGO – Smart Irrigation

ESP32 + soil moisture sensor + pump, synced through Firebase Realtime Database
to a Flutter app.

- [`esp32/`](esp32/) – firmware: reads the sensor, runs the pump, publishes to Firebase
- [`app/`](app/) – Flutter app: login, live dashboard, manual control, history chart
- [`firebase/database.rules.json`](firebase/database.rules.json) – security rules (each user only sees their own data)
