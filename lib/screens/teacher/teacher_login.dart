import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/chatify_auth_service.dart';
import '../../main.dart'; // ✅ IMPORTED for 'connectSocket'

import 'teacher_dashboard.dart';
import 'teacher_register.dart';
import 'teacher_update_profile.dart';

class TeacherLogin extends StatefulWidget {
  const TeacherLogin({super.key});

  @override
  State<TeacherLogin> createState() => _TeacherLoginState();
}

class _TeacherLoginState extends State<TeacherLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _loginTeacher() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email and password are required");
      }

      // 🔐 FIREBASE AUTH LOGIN
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Login failed");
      }

      final uid = user.uid;

      // 🔍 FETCH TEACHER PROFILE
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(uid)
          .get();

      if (!teacherDoc.exists) {
        throw Exception("No teacher data found");
      }

      final teacherData = teacherDoc.data()!;
      final profileCompleted = teacherData['profileCompleted'] == true;
      final teacherName = teacherData['name'] ?? "Teacher";

      // 🔥 CHATIFY SYNC
      final chatifyData = await ChatifyAuthService.syncUser(
        firebaseUser: user,
        role: "teacher",
        name: teacherName,
      );

      // 🔥 AUTO SAVE (Safety for Firestore)
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "role": "teacher",
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection("teachers").doc(uid).set({
        "chatifyUserId": chatifyData["chatifyUserId"],
        "chatifyJwt": chatifyData["token"],
      }, SetOptions(merge: true));

      // 🔌 CONNECT SOCKET IMMEDIATELY
      final token = chatifyData["token"];
      if (token != null) {
        print("🔌 Connecting Socket for Teacher...");
        connectSocket(token);
      }

      if (!mounted) return;

      // 🔁 REDIRECT
      if (profileCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherDashboard(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherUpdateProfile(userId: uid),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _error = "Account not found";
            break;
          case 'wrong-password':
            _error = "Wrong password";
            break;
          case 'invalid-email':
            _error = "Invalid email";
            break;
          case 'too-many-requests':
            _error = "Too many attempts. Try later";
            break;
          default:
            _error = e.message ?? "Login failed";
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception:", "").trim();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Teacher Login"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Teacher Login",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherRegister(),
                    ),
                  );
                },
                child: const Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}