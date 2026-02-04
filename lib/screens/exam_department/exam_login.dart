import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exam_dashboard.dart';
import '../../widgets/common_textfield.dart';

class ExamLogin extends StatefulWidget {
  const ExamLogin({Key? key}) : super(key: key);

  @override
  State<ExamLogin> createState() => _ExamLoginState();
}

class _ExamLoginState extends State<ExamLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> loginExam() async {
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ DIRECT DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExamDashboard()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Exam Department Login",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  CommonTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: loginExam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                          ),
                          child: const Text("Login",
                              style: TextStyle(fontSize: 18)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
