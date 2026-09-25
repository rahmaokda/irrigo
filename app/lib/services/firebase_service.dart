import 'package:firebase_database/firebase_database.dart';

/// Central place for Realtime Database paths, so they match the ESP32 firmware.
class FirebaseService {
  FirebaseService._();

  static DatabaseReference get _root => FirebaseDatabase.instance.ref();

  /// `users/<uid>`
  static DatabaseReference user(String uid) => _root.child('users/$uid');

  /// `users/<uid>/devices`
  static DatabaseReference devices(String uid) => user(uid).child('devices');

  /// `users/<uid>/devices/<deviceId>/zones/<zoneId>`
  static DatabaseReference zone(String uid, String deviceId, String zoneId) =>
      devices(uid).child('$deviceId/zones/$zoneId');

  /// `users/<uid>/moistureHistory/<deviceId>/<zoneId>`
  static DatabaseReference history(
    String uid,
    String deviceId,
    String zoneId,
  ) => user(uid).child('moistureHistory/$deviceId/$zoneId');
}
