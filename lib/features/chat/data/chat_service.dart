import 'package:dio/dio.dart';
import 'package:seekr/core/services/api_config.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';

//custom exception for chat errors
class ChatException implements Exception {
  final String message;
  final String code;

  ChatException(this.message, this.code);
  @override
  String toString() => message;
}

class ChatService {
  final Dio _dio;
  final AuthRepo _authRepo;

  ChatService({
    Dio? dio,
    required AuthRepo authRepo,
  }) : _dio = dio ?? Dio(),
        _authRepo = authRepo;

  // sends a chat query to the backend and returns the response
  Future<String> sendQuery(String query) async {
    try {
      // Get firebase id token
      final token = await _authRepo.getIdToken();
      if (token == null) {
        throw ChatException('User Not authenticated', 'not-authenticated');
      }
    
    // call chat endpoint
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/chat',
      data: {
        'query': query,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    final data = response.data as Map<String, dynamic>;
    return data['answer'] ?? 'No response from AI';
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ChatException(
        'Failed to send message',
        'unknown-error',
      );
    }
  }

  ChatException _handleDioError(DioException e) {
    switch(e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
          return ChatException(
            'Connection timeout. Pls try again',
            'timeout'
            );

      case DioExceptionType.receiveTimeout:
          return ChatException(
            'Server took too long to respond. Pls try again',
            'server-timeout'
            );
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        if(statusCode == 401) {
          return ChatException(
            'Unauthorized. Pls login again',
            'unauthorized'
            );
        } else if(statusCode == 429) {
          return ChatException(
            'Too many requests. Pls slow down',
            'too-many-requests'
            );
        } else if(statusCode != null && statusCode >= 500) {
          return ChatException(
            'Server error. Pls try again later',
            'server-error'
            );
        }
        return ChatException(
          'Request failed',
          'Bad Response',
        );

        case DioExceptionType.connectionError:
          return ChatException(
            'No internet connection. Pls check your connection',
            'no-internet'
            );

        case DioExceptionType.cancel:
          return ChatException(
            'Request was cancelled',
            'cancelled'
            );

        default:
          return ChatException(
            'An unexpected error occurred',
            'unknown-error'
            );
    }
  }
}