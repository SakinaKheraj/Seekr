import 'package:dio/dio.dart';
import 'package:seekr/core/services/api_config.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';

/// Custom exception for history-related errors
class HistoryException implements Exception {
  final String message;
  final String code;

  HistoryException(this.message, this.code);

  @override
  String toString() => message;
}

class HistoryService {
  final Dio _dio;
  final AuthRepo _authRepo;

  HistoryService({
    Dio? dio,
    required AuthRepo authRepo,
  })  : _dio = dio ?? Dio(),
        _authRepo = authRepo;

  /// Fetches chat history / sessions from backend
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      // 🔐 Get Firebase ID token
      final token = await _authRepo.getIdToken();

      if (token == null) {
        throw HistoryException(
          'User not authenticated',
          'not-authenticated',
        );
      }

      // 🌐 Call FastAPI /history endpoint
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = response.data;

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw HistoryException(
          'Invalid history response format',
          'invalid-response',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw HistoryException(
        'Failed to fetch chat history',
        'unknown-error',
      );
    }
  }

  /// Maps Dio errors to meaningful history errors
  HistoryException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HistoryException(
          'Connection timeout. Please try again.',
          'timeout',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        if (statusCode == 401) {
          return HistoryException(
            'Authentication failed.',
            'unauthorized',
          );
        } else if (statusCode == 403) {
          return HistoryException(
            'Access denied.',
            'forbidden',
          );
        } else if (statusCode == 404) {
          return HistoryException(
            'History not found.',
            'not-found',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return HistoryException(
            'Server error. Please try again.',
            'server-error',
          );
        }
        return HistoryException(
          'Request failed.',
          'bad-response',
        );

      case DioExceptionType.connectionError:
        return HistoryException(
          'No internet connection.',
          'network-error',
        );

      case DioExceptionType.cancel:
        return HistoryException(
          'Request cancelled.',
          'cancelled',
        );

      default:
        return HistoryException(
          'Unexpected error occurred.',
          'unknown-error',
        );
    }
  }
}
