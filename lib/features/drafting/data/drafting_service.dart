import 'package:dio/dio.dart';
import 'package:seekr/core/services/api_config.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';

class DraftingService {
  final AuthRepo _authRepo;
  final Dio _dio = Dio();

  DraftingService({required AuthRepo authRepo}) : _authRepo = authRepo;

  Future<String> generateDraft({required String text, required String format}) async {
    try {
      final token = await _authRepo.getIdToken();
      if (token == null) throw Exception('Unauthorized');

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/draft',
        data: {
          'text': text,
          'format': format,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['draft'] as String? ?? '';
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to generate draft');
    } catch (e) {
      throw Exception('Failed to generate draft: $e');
    }
  }
}
