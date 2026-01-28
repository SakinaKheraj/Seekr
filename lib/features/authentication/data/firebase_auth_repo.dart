import 'package:firebase_auth/firebase_auth.dart';
import 'package:seekr/features/authentication/domain/entities/app_user.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo{
  // access to firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<AppUser?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        email: user.email!,
      );
    });
  }

  @override
  Future<void> deleteAccount() async{
    try {
      final user = firebaseAuth.currentUser;

      if(user == null) throw Exception('No User Logged In!');
      await user.delete();
      await logout();
    } catch (e) {
      throw Exception('Failed to Delete Account: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if(firebaseUser == null) return null;
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }

  // Login user with email and password
@override
Future<AppUser?> loginWithEmailPassword(
    String email, String password) async {
  try {
    final userCredential =
        await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) return null;

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? email,
    );
  } catch (e) {
    throw Exception('Login failed: $e');
  }
}



  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> registerWithEmailPassword(String email, String password) async{
    try {
      UserCredential userCredential = await firebaseAuth.
        createUserWithEmailAndPassword(email: email, password: password);

      AppUser user = AppUser(
        uid: userCredential.user!.uid, email: email
        );

        return user;
    } catch (e) {
        throw Exception('Registration Failed: $e');
    }
  }

  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email sent! Check your inbox.";

    } catch (e) {
      throw Exception("An Error Occured: $e");
    }
  }
  
  @override
  Future<String?> getIdToken() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

}