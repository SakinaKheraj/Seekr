import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/authentication/domain/entities/app_user.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;

  StreamSubscription<AppUser?>? _authSub;
  AppUser? _currentUser;

  // 🔑 ADD THESE
  String? _idToken;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  AppUser? get currentUser => _currentUser;
  String? get idToken => _idToken;

  /// Listen to Firebase auth state
  void listenToAuthChanges() {
    _authSub?.cancel();

    _authSub = authRepo.authStateChanges.listen((user) async {
      if (user == null) { 
        _currentUser = null;
        _idToken = null;
        emit(Unauthenticated());
      } else {
        _currentUser = user;

        try {
          // Firebase might throw connection errors when fetching the token
          _idToken = await authRepo.getIdToken();
          if (kDebugMode) {
            debugPrint('FIREBASE ID TOKEN: $_idToken');
          }
          emit(Authenticated(user: user));
        } catch (e) {
          _currentUser = null;
          _idToken = null;
          emit(AuthError(message: 'Failed to complete secure login: ${e.toString()}'));
        }
      }
    });
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await authRepo.loginWithEmailPassword(email, password);
      // Authenticated will be emitted by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// REGISTER
  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      await authRepo.registerWithEmailPassword(email, password);
      // Authenticated will be emitted by authStateChanges listener
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await authRepo.logout();
    // Unauthenticated will be emitted by authStateChanges listener
  }

  /// FORGOT PASSWORD
  Future<String> forgotPassword(String email) async {
    try {
      await authRepo.sendPasswordResetEmail(email);
      return "SUCCESS: Password reset email sent! Check your inbox.";
    } catch (e) {
      return "ERROR: ${e.toString().replaceAll('Exception:', '').trim()}";
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
