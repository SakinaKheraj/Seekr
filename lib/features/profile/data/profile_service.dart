import 'package:dio/dio.dart';
import 'package:seekr/core/services/api_config.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';

/// Custom exception for profile-related errors
class ProfileException implements Exception {
  final String message;
  final String code;

  ProfileException(this.message, this.code);

  @override
  String toString() => message;
}

class ProfileService {
  final Dio _dio;
  final AuthRepo _authRepo;

  ProfileService({
    Dio? dio,
    required AuthRepo authRepo,
  })  : _dio = dio ?? Dio(),
        _authRepo = authRepo;

  /// Fetches user profile stats from backend
  Future<Map<String, dynamic>> getStats() async {
    try {
      //  Get Firebase ID token
      final token = await _authRepo.getIdToken();

      if (token == null) {
        throw ProfileException(
          'User not authenticated',
          'not-authenticated',
        );
      }

      //  Call FastAPI /stats endpoint
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/stats',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ProfileException(
        'Failed to fetch profile stats',
        'unknown-error',
      );
    }
  }

  /// Converts Dio errors into meaningful profile errors
  ProfileException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ProfileException(
          'Connection timeout. Please try again.',
          'timeout',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        if (statusCode == 401) {
          return ProfileException(
            'Authentication failed.',
            'unauthorized',
          );
        } else if (statusCode == 403) {
          return ProfileException(
            'Access denied.',
            'forbidden',
          );
        } else if (statusCode == 404) {
          return ProfileException(
            'Profile data not found.',
            'not-found',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ProfileException(
            'Server error. Please try again.',
            'server-error',
          );
        }
        return ProfileException(
          'Request failed.',
          'bad-response',
        );

      case DioExceptionType.connectionError:
        return ProfileException(
          'No internet connection.',
          'network-error',
        );

      case DioExceptionType.cancel:
        return ProfileException(
          'Request cancelled.',
          'cancelled',
        );

      default:
        return ProfileException(
          'Unexpected error occurred.',
          'unknown-error',
        );
    }
  }
}
