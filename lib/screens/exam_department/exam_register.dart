import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_textfield.dart';
import 'exam_login.dart';

class ExamRegisterPage extends StatefulWidget {
  const ExamRegisterPage({Key? key}) : super(key: key);

  @override
  State<ExamRegisterPage> createState() => _ExamRegisterPageState();
}

class _ExamRegisterPageState extends State<ExamRegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> registerExam() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 🔒 DEFAULT: staff, HOD baad me admin mark karega
      await FirebaseFirestore.instance
          .collection('exam_department')
          .doc(uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'department': 'exam',
        'isHOD': false,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
      );

      // ✅ FIX: NO NAMED ROUTE
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExamLogin()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed')));
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
                    "Exam Department Registration",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  CommonTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: registerExam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                          ),
                          child: const Text("Register",
                              style: TextStyle(fontSize: 18)),
                        ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ExamLogin()),
                      );
                    },
                    child: const Text("Already have an account? Login"),
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
