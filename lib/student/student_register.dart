import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_login.dart';

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _registerStudent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      final uid = userCred.user!.uid;

      final regNo = "REG${DateTime.now().year}${_rollController.text.substring(_rollController.text.length - 3)}";

      await FirebaseFirestore.instance.collection('students').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'rollNo': _rollController.text.trim(),
        'registrationNo': regNo,
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'approved': false,
        'createdAt': DateTime.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registered successfully! Wait for admin approval.")),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const StudentLoginPage()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade100, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Welcome to Students",
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
                Text("Synergy Institute of Engineering & Technology",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.black54)),
                const SizedBox(height: 20),
                TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Full Name")),
                const SizedBox(height: 10),
                TextField(
                    controller: _rollController,
                    decoration: const InputDecoration(labelText: "Roll No")),
                const SizedBox(height: 10),
                TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 10),
                TextField(
                    controller: _mobileController,
                    decoration: const InputDecoration(labelText: "Mobile No")),
                const SizedBox(height: 10),
                TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerStudent,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const StudentLoginPage())),
                  child: const Text("Already Registered? Login Here"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
