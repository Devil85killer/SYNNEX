import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chatify_auth_service.dart';
import '../../main.dart';
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
  String _statusMessage = "Please wait...";

  Future<void> _loginTeacher() async {
    setState(() { _loading = true; _error = null; _statusMessage = "🔐 Authenticating..."; });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) throw Exception("Fields required");

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) throw Exception("Login failed");

      setState(() => _statusMessage = "🔍 Checking Profile...");
      final doc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
      if (!doc.exists) throw Exception("No teacher data found");

      final data = doc.data()!;
      final profileCompleted = data['profileCompleted'] == true;
      final name = data['name'] ?? "Teacher";

      final chatifyData = await ChatifyAuthService.syncUser(
        firebaseUser: user, role: "teacher", name: name,
        onStatusChange: (msg) { if(mounted) setState(() => _statusMessage = msg); }
      );

      final token = chatifyData["token"];
      final myMongoId = chatifyData["chatifyUserId"];

      if (token != null && myMongoId != null) {
        if(mounted) setState(() => _statusMessage = "🔌 Connecting Socket...");
        connectSocket(token, myMongoId);
      }

      if (!mounted) return;
      if (profileCompleted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherUpdateProfile(userId: user.uid)));
      }
    } catch (e) {
      if(mounted) setState(() { _error = e.toString().replaceAll("Exception:", "").trim(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Teacher Login", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: _loading 
                ? Column(children: [const CircularProgressIndicator(), Text(_statusMessage)]) 
                : ElevatedButton(onPressed: _loginTeacher, child: const Text("Login"))),
            ],
          ),
        ),
      ),
    );
  }
}