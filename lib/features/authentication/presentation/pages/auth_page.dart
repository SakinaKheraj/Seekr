import 'package:flutter/material.dart';
import 'package:seekr/features/authentication/presentation/pages/login_page.dart';
import 'package:seekr/features/authentication/presentation/pages/signup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if(showLoginPage) {
      return LoginPage(togglePages: togglePages);
    } else {
      return SignupPage(togglePages: togglePages);
    }
  }
}