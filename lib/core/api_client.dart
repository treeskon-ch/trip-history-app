import 'package:dio/dio.dart';

class ApiClient {
  // Configurable base URL, pointing to localhost for iOS simulator by default
  static const String baseUrl = 'https://trip-history-api.onrender.com/';

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  // Singleton pattern for easy global access
  static final ApiClient _instance = ApiClient();
  static ApiClient get instance => _instance;
}
