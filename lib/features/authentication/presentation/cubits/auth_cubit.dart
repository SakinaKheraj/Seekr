import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/authentication/domain/entities/app_user.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  StreamSubscription<AppUser?>? _authSub;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  AppUser? get currentUser => _currentUser;

  void listenToAuthChanges() {
    _authSub?.cancel();

    _authSub = authRepo.authStateChanges.listen((user) {
      if (user == null) {
        _currentUser = null;
        emit(Unauthenticated());
      } else {
        _currentUser = user;
        emit(Authenticated(user: user));
      }
    });
  }

  /// LOGIN
  Future<void> login(String email, String password) async {
    try {
      await authRepo.loginWithEmailPassword(email, password);
    } catch (e) {
      emit(AuthError(msg: e.toString()));
    }
  }

  /// REGISTER
  Future<void> register(String email, String password) async {
    try {
      await authRepo.registerWithEmailPassword(email, password);
    } catch (e) {
      emit(AuthError(msg: e.toString()));
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await authRepo.logout();
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
