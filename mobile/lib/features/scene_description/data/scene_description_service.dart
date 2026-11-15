import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class SceneDescriptionResult {
  const SceneDescriptionResult({
    required this.description,
    required this.isMock,
  });

  final String description;
  final bool isMock;
}

class SceneDescriptionService {
  SceneDescriptionService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<SceneDescriptionResult> describe({
    required String imagePath,
    required String language,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'scene.jpg'),
      'language': language,
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/scene/describe',
        data: formData,
      );

      final json = response.data;

      if (json == null) {
        throw const FormatException('Réponse vide.');
      }

      return SceneDescriptionResult(
        description: json['description'] as String,
        isMock: json['is_mock'] as bool,
      );
    } on DioException catch (error) {
      debugPrint('Dio error type: ${error.type}');
      debugPrint('Dio error message: ${error.message}');
      debugPrint('Dio error response: ${error.response?.statusCode}');
      debugPrint('Dio error details: ${error.error}');

      if (error.response != null) {
        throw Exception('Erreur serveur : HTTP ${error.response!.statusCode}');
      }

      throw Exception('Impossible de contacter FastAPI.');
      rethrow;
    }
  }
}
