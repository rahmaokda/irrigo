#include "firebase_service.h"

#include <WiFi.h>
#include <time.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"  // token status callback

#include "config.h"
#include "secrets.h"

static FirebaseData fbdo;
static FirebaseAuth auth;
static FirebaseConfig fbConfig;

void FirebaseService::begin() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  // Don't block forever: irrigation must keep working without network.
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    Serial.print(".");
    delay(300);
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? " connected" : " timed out (will retry)");

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");  // UTC epoch for timestamps

  fbConfig.api_key = FIREBASE_API_KEY;
  fbConfig.database_url = FIREBASE_DATABASE_URL;
  auth.user.email = FIREBASE_USER_EMAIL;
  auth.user.password = FIREBASE_USER_PASSWORD;
  fbConfig.token_status_callback = tokenStatusCallback;
  fbConfig.timeout.serverResponse = 10 * 1000;

  Firebase.reconnectWiFi(true);
  fbdo.setResponseSize(2048);
  Firebase.begin(&fbConfig, &auth);
}

bool FirebaseService::ready() {
  return WiFi.status() == WL_CONNECTED && Firebase.ready() && auth.token.uid.length() > 0;
}

uint32_t FirebaseService::now() {
  time_t t = time(nullptr);
  return t > 1700000000 ? (uint32_t)t : 0;  // before sync the clock starts at 1970
}

String FirebaseService::devicePath() const {
  return String("users/") + auth.token.uid.c_str() + "/devices/" + DEVICE_ID;
}

String FirebaseService::zonePath() const {
  return devicePath() + "/zones/" + ZONE_ID;
}

// First run: create the zone with default settings so the app has something to show.
bool FirebaseService::createZone(const ZoneConfig &defaults) {
  FirebaseJson json;
  json.set("name", ZONE_NAME);
  json.set("threshold", defaults.threshold);
  json.set("autoMode", defaults.autoMode);
  json.set("pumpCommand", false);
  json.set("pumpState", false);
  json.set("lastWatered", 0);
  if (!Firebase.RTDB.updateNode(&fbdo, zonePath().c_str(), &json)) {
    Serial.printf("Zone init failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }
  Serial.println("Created zone in Firebase with default settings");
  return true;
}

bool FirebaseService::readConfig(ZoneConfig &cfg) {
  bool ok = Firebase.RTDB.get(&fbdo, zonePath().c_str());
  bool missing = (ok && fbdo.dataType() != "json") ||
                 (!ok && fbdo.httpCode() == FIREBASE_ERROR_PATH_NOT_EXIST);
  if (missing) return createZone(cfg);
  if (!ok) {
    Serial.printf("Read config failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }

  FirebaseJson &json = fbdo.jsonObject();
  FirebaseJsonData r;
  if (json.get(r, "threshold") && r.success) cfg.threshold = constrain(r.intValue, 0, 100);
  if (json.get(r, "autoMode") && r.success) cfg.autoMode = r.boolValue;
  if (json.get(r, "pumpCommand") && r.success) cfg.pumpCommand = r.boolValue;
  return true;
}

bool FirebaseService::writePumpCommand(bool on) {
  String path = zonePath() + "/pumpCommand";
  if (!Firebase.RTDB.setBool(&fbdo, path.c_str(), on)) {
    Serial.printf("Write pumpCommand failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }
  return true;
}

bool FirebaseService::publishState(const ZoneState &state) {
  FirebaseJson json;
  json.set("moisture", state.moisture);
  json.set("pumpState", state.pumpState);
  json.set("online", true);
  uint32_t t = now();
  if (t) json.set("lastSeen", (int)t);
  if (state.lastWatered) json.set("lastWatered", (int)state.lastWatered);

  // updateNode only touches these keys; app-owned fields are left alone.
  if (!Firebase.RTDB.updateNode(&fbdo, zonePath().c_str(), &json)) {
    Serial.printf("Publish failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }
  return true;
}

bool FirebaseService::pushHistory(int moisture) {
  uint32_t t = now();
  if (!t) return false;  // no valid timestamp yet
  // Stored outside zones/<zone> so reading the current state never downloads history.
  String path = devicePath() + "/moistureHistory/" + ZONE_ID + "/" + String(t);
  if (!Firebase.RTDB.setInt(&fbdo, path.c_str(), moisture)) {
    Serial.printf("History write failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }
  return true;
}
