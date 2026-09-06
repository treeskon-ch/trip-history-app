import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/location_model.dart';
import '../models/checkin_model.dart';
import '../models/plan_model.dart';

class ApiService {
  final Dio _dio = ApiClient.instance.dio;

  // --- 1. User Management ---

  Future<void> updateFCMToken(String userId, String token) async {
    try {
      await _dio.patch('/api/users/$userId/fcm-token', data: {
        'fcmToken': token,
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  Future<Map<String, dynamic>> registerUser(String email, String password, String name, String role) async {
    try {
      final response = await _dio.post('/api/users/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('/api/users/$userId');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.get('/api/users');
      final List data = response.data;
      return data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // --- 2. Trip Management ---

  Future<Map<String, dynamic>> startTrip(String userId, {String? planId}) async {
    try {
      final data = {'userId': userId};
      if (planId != null) {
        data['planId'] = planId;
      }
      final response = await _dio.post('/api/trips/start', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to start trip: $e');
    }
  }

  Future<void> endTrip(String tripId, double distance, String imageUrl) async {
    try {
      await _dio.post('/api/trips/$tripId/end', data: {
        'distance': distance,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to end trip: $e');
    }
  }

  Future<List<TripModel>> getTrips(String userId) async {
    try {
      final response = await _dio.get('/api/trips', queryParameters: {'userId': userId});
      final List data = response.data;
      return data.map((e) => TripModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }

  // --- 3. Tracking & Routes ---

  Future<void> updateLocation(String tripId, LocationModel location) async {
    try {
      await _dio.post('/api/trips/$tripId/locations', data: location.toJson());
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<List<LocationModel>> getTripRoute(String tripId) async {
    try {
      final response = await _dio.get('/api/trips/$tripId/route');
      final List data = response.data;
      return data.map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get trip route: $e');
    }
  }

  // --- 4. Events & Logs ---

  Future<void> checkIn(String tripId, CheckinModel checkin) async {
    try {
      await _dio.post('/api/trips/$tripId/checkin', data: checkin.toJson());
    } catch (e) {
      throw Exception('Failed to check-in: $e');
    }
  }

  Future<void> reportIssue(String tripId, String userId, String title, String description) async {
    try {
      await _dio.post('/api/trips/$tripId/issues', data: {
        'userId': userId,
        'title': title,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to report issue: $e');
    }
  }

  // --- 5. Job Plans ---

  Future<List<PlanModel>> getJobPlans(String userId) async {
    try {
      final response = await _dio.get('/api/plans', queryParameters: {'driverId': userId});
      final List data = response.data;
      return data.map((e) => PlanModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get job plans: $e');
    }
  }

  Future<void> saveLog(String userId, String eventType, String message) async {
    try {
      await _dio.post('/api/logs', data: {
        'userId': userId,
        'eventType': eventType,
        'message': message,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save log: $e');
    }
  }

  // --- 5. System Management ---

  Future<void> clearData() async {
    try {
      await _dio.post('/api/system/clear-data');
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}
