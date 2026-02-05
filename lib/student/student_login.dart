import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/chatify_auth_service.dart';
import '../../main.dart'; // ✅ IMPORTED for 'connectSocket'

import 'student_redirect_handler.dart';
import 'student_forgot_password.dart';
import 'student_register.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rollNo = _rollController.text.trim();
      final password = _passwordController.text.trim();

      if (rollNo.isEmpty || password.isEmpty) {
        throw Exception("Roll No & Password required");
      }

      // 🔍 FETCH STUDENT BY ROLL NO (PRE-AUTH LOOKUP)
      final snap = await FirebaseFirestore.instance
          .collection("students")
          .where("rollNo", isEqualTo: rollNo)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw Exception("Invalid Roll Number");
      }

      final studentData = snap.docs.first.data();
      final email = studentData["email"];
      final name = studentData["name"] ?? "Student";

      // 🔐 FIREBASE AUTH LOGIN
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception("Login failed");
      }

      final uid = user.uid;

      // 🔥 CHATIFY SYNC (AUTO + SCALE SAFE)
      final chatifyData = await ChatifyAuthService.syncUser(
        firebaseUser: user,
        role: "student",
        name: name,
      );

      // 🔥 AUTO SAVE (Safety)
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "role": "student",
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection("students").doc(uid).set({
        "chatifyUserId": chatifyData["chatifyUserId"],
        "chatifyJwt": chatifyData["token"],
      }, SetOptions(merge: true));

      // 🔌 CONNECT SOCKET IMMEDIATELY
      final token = chatifyData["token"];
      if (token != null) {
        print("🔌 Connecting Socket for Student...");
        connectSocket(token);
      }

      if (!mounted) return;

      // 🔁 REDIRECT
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentRedirectHandler(),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception:", "").trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Student Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _rollController,
                decoration: const InputDecoration(labelText: "Roll No"),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 16),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text("Forgot Password?"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentRegisterPage(),
                    ),
                  );
                },
                child: const Text("New Student? Register Here"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}