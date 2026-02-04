import 'package:flutter/material.dart';

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon; // ✅ add this line
  final bool isPassword;

  const CommonTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon, // ✅ add this line
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null, // ✅ add icon support
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
