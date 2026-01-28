import 'package:flutter/material.dart';
import 'package:seekr/features/authentication/presentation/pages/auth_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_states.dart';
import 'package:seekr/features/chat/presentation/pages/chat_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const ChatPage();
        }

        if (state is Unauthenticated) {
          return const AuthPage();
        }

        // AuthInitial / AuthLoading / AuthError fall back to a simple loading screen.
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
