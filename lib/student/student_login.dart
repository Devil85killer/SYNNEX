import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chatify_auth_service.dart';
import '../../main.dart';
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
  String _statusMessage = "Please wait...";

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; _statusMessage = "🔍 Verifying Roll No..."; });

    try {
      final rollNo = _rollController.text.trim();
      final password = _passwordController.text.trim();
      if (rollNo.isEmpty || password.isEmpty) throw Exception("All fields required");

      final snap = await FirebaseFirestore.instance.collection("students").where("rollNo", isEqualTo: rollNo).limit(1).get();
      if (snap.docs.isEmpty) throw Exception("Invalid Roll Number");

      final data = snap.docs.first.data();
      final email = data["email"];
      final name = data["name"] ?? "Student";

      setState(() => _statusMessage = "🔐 Authenticating...");
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) throw Exception("Login failed");

      final chatifyData = await ChatifyAuthService.syncUser(
        firebaseUser: user, role: "student", name: name,
        onStatusChange: (msg) { if(mounted) setState(() => _statusMessage = msg); }
      );

      final token = chatifyData["token"];
      final myMongoId = chatifyData["chatifyUserId"];

      if (token != null && myMongoId != null) {
        if(mounted) setState(() => _statusMessage = "🔌 Connecting Socket...");
        connectSocket(token, myMongoId);
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentRedirectHandler()));

    } catch (e) {
      if(mounted) setState(() { _error = e.toString().replaceAll("Exception:", "").trim(); _loading = false; });
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Student Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _rollController, decoration: const InputDecoration(labelText: "Roll No")),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _loading 
                ? Column(children: [const CircularProgressIndicator(), Text(_statusMessage)]) 
                : ElevatedButton(onPressed: _login, child: const Text("Login"))),
            ],
          ),
        ),
      ),
    );
  }
}