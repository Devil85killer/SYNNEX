import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/chatify_auth_service.dart';

// PAGES
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

  Future<void> _login() async {
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
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception("Login failed");
      }

      final uid = user.uid;

      // 🔍 FETCH ALUMNI PROFILE
      final alumniDoc = await FirebaseFirestore.instance
          .collection('alumni_users')
          .doc(uid)
          .get();

      if (!alumniDoc.exists) {
        throw Exception("No alumni data found");
      }

      final alumniData = alumniDoc.data()!;
      final profileCompleted = alumniData['profileCompleted'] == true;
      final alumniName = alumniData['name'] ?? "Alumni";

      // 🔥 CHATIFY SYNC (AUTO + SAFE TO CALL EVERY LOGIN)
      // 👉 ye function:
      // - chatify user create/get karega
      // - JWT generate karega
      // - users/{uid} me role save karega
      // - alumni_users/{uid} me chatifyUserId + chatifyJwt save karega
      await ChatifyAuthService.syncUser(
        firebaseUser: user,
        role: "alumni",
        name: alumniName,
      );

      if (!mounted) return;

      // 🔁 REDIRECT
      if (profileCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AlumniDashboard(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AlumniUpdateProfilePage(userId: uid),
          ),
        );
      }
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Alumni Login",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlumniRegisterPage(),
                    ),
                  );
                },
                child: const Text("New Alumni? Register here"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
