import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Department imports
import '../library_department/library_dashboard.dart';
import '../library_department/library_register.dart';
import '../library_department/library_update_profile.dart';

import '../accounts_department/account_dashboard.dart';
import '../accounts_department/account_register.dart';
import '../accounts_department/accounts_update_profile.dart';

import '../exam_department/exam_dashboard.dart';
import '../exam_department/exam_register.dart';
import '../exam_department/exam_update_profile.dart';

class DepartmentLogin extends StatefulWidget {
  const DepartmentLogin({super.key});

  @override
  State<DepartmentLogin> createState() => _DepartmentLoginState();
}

class _DepartmentLoginState extends State<DepartmentLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedDepartment;
  bool _loading = false;

  // 🔥 FIX — correct collection names
  final List<String> departments = [
    'library_department',
    'accounts_department',
    'exam_department',
  ];

  Future<void> _login() async {
    if (_selectedDepartment == null ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = credential.user!.uid;

      // 🔥 FIX: correct Firestore collection read
      final snap = await FirebaseFirestore.instance
          .collection(_selectedDepartment!)
          .doc(userId)
          .get();

      if (!snap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No record found in Firestore")),
        );
        return;
      }

      final data = snap.data()!;
      final profileCompleted = data['profileCompleted'] == true;

      // ------------ REDIRECTS FIXED --------------

      if (_selectedDepartment == 'library_department') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                profileCompleted ? const LibraryDashboard() : const LibraryUpdateProfilePage(),
          ),
        );
      }

      else if (_selectedDepartment == 'accounts_department') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            profileCompleted ? const AccountDashboard() : const AccountsUpdateProfilePage(),
          ),
        );
      }

      else if (_selectedDepartment == 'exam_department') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            profileCompleted ? const ExamDashboard() : const ExamUpdateProfilePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _goToRegisterPage() {
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a department first")),
      );
      return;
    }

    if (_selectedDepartment == 'library_department') {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LibraryRegisterPage()));
    } else if (_selectedDepartment == 'accounts_department') {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AccountRegisterPage()));
    } else {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ExamRegisterPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Department Login"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Department Login",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: departments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDepartment = val),
                decoration: const InputDecoration(
                  labelText: "Select Department",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? "),
                  GestureDetector(
                    onTap: _goToRegisterPage,
                    child: const Text(
                      "Register here",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
