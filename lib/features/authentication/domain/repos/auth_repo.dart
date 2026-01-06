/*

AUTH REPOSITORY - Outlines the possible auth operations.

*/

import 'package:seekr/features/authentication/domain/entities/app_user.dart';

abstract class AuthRepo {
  Stream<AppUser?> get authStateChanges;
  
  Future<AppUser?> loginWithEmailPassword(String email, String password);
  Future<AppUser?> registerWithEmailPassword(String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<String> sendPasswordResetEmail(String email);
  Future<void> deleteAccount();
}
