import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentForgotPasswordPage extends StatefulWidget {
  const StudentForgotPasswordPage({super.key});

  @override
  State<StudentForgotPasswordPage> createState() => _StudentForgotPasswordPageState();
}

class _StudentForgotPasswordPageState extends State<StudentForgotPasswordPage> {
  final _emailController = TextEditingController();
  String? _message;

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() => _message = "Password reset link sent! Check your email.");
    } catch (e) {
      setState(() => _message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Reset Your Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Enter Registered Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: const Text("Send Reset Link"),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(_message!, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
