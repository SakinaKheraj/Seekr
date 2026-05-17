import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/authentication/presentation/components/my_button.dart';
import 'package:seekr/features/authentication/presentation/components/my_textfield.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';

class SignupPage extends StatefulWidget {
  final void Function()? togglePages;
  const SignupPage({super.key, required this.togglePages});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpassController = TextEditingController();

  //button pressed function
  void signUserUp() {
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmpassController.text;

    final authCubit = context.read<AuthCubit>();

    //fields are not empty
    if(email.isNotEmpty && password.isNotEmpty && confirmPassword.isNotEmpty) {
      //passwords match
      if(password == confirmPassword) {
        authCubit.register(email, password);
      } else {
        //show error - passwords do not match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'))
        );
      }
    } else {
      //show error - fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'))
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmpassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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
                            'Join Seekr',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: MyColors.gradient3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create an account to start exploring.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: MyColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 40),

              // Email textfield
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

              // Password textfield
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

              // Confirm Password textfield
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Confirm Password',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              MyTextfield(
                controller: confirmpassController,
                hintText: 'Confirm your password',
                obscureText: true,
              ),

              const SizedBox(height: 20),

              MyButton(
                onTap: signUserUp,
                text: 'Sign Up',
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: widget.togglePages,
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: 'Sign In',
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
    );
  }
}
