#pragma once
// Copy this file to secrets.h and fill in your values. secrets.h is git-ignored.

#define WIFI_SSID     "your-wifi"
#define WIFI_PASSWORD "your-wifi-password"

// Firebase console -> Project settings -> General -> Web API Key
#define FIREBASE_API_KEY      "AIza..."
// Firebase console -> Realtime Database (e.g. https://irrigo-default-rtdb.europe-west1.firebasedatabase.app)
#define FIREBASE_DATABASE_URL "https://your-project-default-rtdb.firebaseio.com"

// The ESP32 signs in as the owning user (same account used in the Flutter app),
// so the data lands under users/<that user's uid>/...
#define FIREBASE_USER_EMAIL    "you@example.com"
#define FIREBASE_USER_PASSWORD "your-password"
