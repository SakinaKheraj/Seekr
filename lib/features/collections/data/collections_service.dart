import 'package:dio/dio.dart';
import 'package:seekr/core/services/api_config.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/collections/data/models/bookmark_model.dart';

class CollectionsService {
  final Dio _dio;
  final AuthRepo _authRepo;

  CollectionsService({Dio? dio, required AuthRepo authRepo})
      : _dio = dio ?? Dio(),
        _authRepo = authRepo;

  Future<Map<String, List<BookmarkItem>>> getCollections() async {
    try {
      final token = await _authRepo.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/collections',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final foldersObj = data['folders'] as Map<String, dynamic>? ?? {};

      final Map<String, List<BookmarkItem>> result = {};
      foldersObj.forEach((key, value) {
        if (value is List) {
          result[key] = (value as List).map((e) => BookmarkItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      });
      return result;
    } catch (e) {
      throw Exception('Failed to load collections: $e');
    }
  }

  Future<void> saveBookmark({
    required String folderName,
    required String query,
    required String answer,
    required List<Map<String, dynamic>> sources,
  }) async {
    try {
      final token = await _authRepo.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      await _dio.post(
        '${ApiConfig.baseUrl}/bookmarks',
        data: {
          'folder_name': folderName,
          'query': query,
          'answer': answer,
          'sources': sources,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to save bookmark: $e');
    }
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      final token = await _authRepo.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      await _dio.delete(
        '${ApiConfig.baseUrl}/bookmarks/$bookmarkId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to delete bookmark: $e');
    }
  }
}
