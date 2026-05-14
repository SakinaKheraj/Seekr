import 'package:flutter/material.dart';
import 'package:seekr/core/theme/colors.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        //unselected
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        
        //unselected default
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        //selected
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: MyColors.gradient2,
            width: 2.0,
          ),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}