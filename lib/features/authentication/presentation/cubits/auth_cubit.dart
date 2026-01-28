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

        //  GET TOKEN ONLY HERE
        _idToken = await authRepo.getIdToken();
        if (kDebugMode) {
          debugPrint('FIREBASE ID TOKEN: $_idToken');
        }

        emit(Authenticated(user: user));
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
      return await authRepo.sendPasswordResetEmail(email);
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
