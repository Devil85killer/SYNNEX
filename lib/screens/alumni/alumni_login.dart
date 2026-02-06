import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chatify_auth_service.dart';
import '../../main.dart';
import 'alumni_dashboard.dart';
import 'alumni_update_profile.dart';
import 'alumni_register.dart';

class AlumniLoginPage extends StatefulWidget {
  const AlumniLoginPage({super.key});

  @override
  State<AlumniLoginPage> createState() => _AlumniLoginPageState();
}

class _AlumniLoginPageState extends State<AlumniLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String _statusMessage = "Please wait...";

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
      _statusMessage = "🔐 Authenticating...";
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) throw Exception("Email and password required");

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) throw Exception("Login failed");
      final uid = user.uid;

      setState(() => _statusMessage = "🔍 Checking Profile...");
      final alumniDoc = await FirebaseFirestore.instance.collection('alumni_users').doc(uid).get();
      if (!alumniDoc.exists) throw Exception("No alumni data found");

      final alumniData = alumniDoc.data()!;
      final profileCompleted = alumniData['profileCompleted'] == true;
      final name = alumniData['name'] ?? "Alumni";

      final chatifyData = await ChatifyAuthService.syncUser(
        firebaseUser: user,
        role: "alumni",
        name: name,
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlumniDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AlumniUpdateProfilePage(userId: uid)));
      }
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
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Alumni Login", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _loading 
                ? Column(children: [const CircularProgressIndicator(), Text(_statusMessage)]) 
                : ElevatedButton(onPressed: _login, child: const Text("Login"))),
              if (!_loading) TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlumniRegisterPage())), child: const Text("Register Here")),
            ],
          ),
        ),
      ),
    );
  }
}