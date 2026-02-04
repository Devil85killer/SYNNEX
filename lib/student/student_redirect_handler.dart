import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_dashboard.dart';
import 'student_update_profile.dart';
import 'student_login.dart';

class StudentRedirectHandler extends StatefulWidget {
  const StudentRedirectHandler({super.key});

  @override
  State<StudentRedirectHandler> createState() =>
      _StudentRedirectHandlerState();
}

class _StudentRedirectHandlerState extends State<StudentRedirectHandler> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _go(const StudentLoginPage());
        return;
      }

      // 🔥 FIX: direct UID document read
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // first time login → force update profile
        _go(const StudentUpdateProfilePage());
        return;
      }

      final data = doc.data()!;

      // approval check
      if (data['approved'] != true) {
        setState(() {
          _error = "Your registration is pending admin approval.";
          _loading = false;
        });
        return;
      }

      final bool profileCompleted =
          data['profileCompleted'] == true;

      _go(
        profileCompleted
            ? const StudentDashboard()
            : const StudentUpdateProfilePage(),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _go(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 70, color: Colors.red),
                  const SizedBox(height: 15),
                  Text(
                    _error ?? "Something went wrong",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const StudentLoginPage()),
                      );
                    },
                    child: const Text("Go to Login Page"),
                  )
                ],
              ),
      ),
    );
  }
}
