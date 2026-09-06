import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyUserId = 'user_id';
  static const String _keyTripId = 'trip_id';

  // --- User ID ---
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  // --- Trip ID ---
  static Future<void> saveTripId(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTripId, tripId);
  }

  static Future<String?> getTripId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTripId);
  }

  static Future<void> removeTripId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTripId);
  }
}
