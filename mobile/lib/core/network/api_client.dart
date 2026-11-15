
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'SIGHTMATE_API_URL',
        defaultValue: 'http://127.0.0.1:8000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}
