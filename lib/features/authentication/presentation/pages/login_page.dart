import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/authentication/presentation/components/my_button.dart';
import 'package:seekr/features/authentication/presentation/components/my_textfield.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/authentication/presentation/pages/forget_pass.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_states.dart';

class LoginPage extends StatefulWidget {
  final void Function()? togglePages;
  const LoginPage({super.key, required this.togglePages});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpassController = TextEditingController();

  @override
Widget build(BuildContext context) {
  return BlocListener<AuthCubit, AuthState>(
    listener: (context, state) {
      if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    },
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.backgroundStart,
              MyColors.backgroundMid,
              MyColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(color: MyColors.shadowLight, blurRadius: 40, offset: Offset(0, 15)),
                    ],
                  ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 48, color: MyColors.gradient2),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: MyColors.gradient3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to continue your research.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: MyColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 40),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              MyTextfield(
                controller: emailController,
                hintText: 'Enter your email',
                obscureText: false,
              ),

              const SizedBox(height: 15),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              MyTextfield(
                controller: passwordController,
                hintText: 'Enter your password',
                obscureText: true,
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgetPass(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MyColors.gradient2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// 🔥 BUTTON REACTS TO STATE
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return MyButton(
                    onTap: state is AuthLoading
                        ? null
                        : () {
                            final email =
                                emailController.text.trim();
                            final password =
                                passwordController.text.trim();

                            if (email.isEmpty || password.isEmpty) {
                              return;
                            }

                            context
                                .read<AuthCubit>()
                                .login(email, password);
                          },
                    text: state is AuthLoading
                        ? 'Signing In...'
                        : 'Sign In',
                  );
                },
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: widget.togglePages,
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: MyColors.gradient2,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
      ),
    ),
  );
}
}