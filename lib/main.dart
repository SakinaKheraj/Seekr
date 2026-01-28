import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/authentication/data/firebase_auth_repo.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/authentication/presentation/pages/auth_gate.dart';
import 'package:seekr/features/chat/presentation/pages/chat_page.dart';
import 'package:seekr/features/history/presentation/pages/history_page.dart';
import 'package:seekr/features/profile/presentation/pages/profile_page.dart';
import 'package:seekr/firebase_options.dart';
import 'package:seekr/core/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FirebaseAuthRepo _firebaseAuthRepo = FirebaseAuthRepo();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepo>.value(
      value: _firebaseAuthRepo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) =>
                AuthCubit(authRepo: _firebaseAuthRepo)..listenToAuthChanges(),
          ),
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: const ColorScheme.light(),
          ),
          routes: {
            AppRoutes.chat: (context) => const ChatPage(),
            AppRoutes.history: (context) => const HistoryPage(),
            AppRoutes.profile: (context) => const ProfilePage(),
          },
          home: const AuthGate(),
        ),
      ),
    );
  }
}
