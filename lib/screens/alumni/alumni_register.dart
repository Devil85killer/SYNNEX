import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'alumni_login.dart';

class AlumniRegisterPage extends StatefulWidget {
  const AlumniRegisterPage({super.key});

  @override
  State<AlumniRegisterPage> createState() => _AlumniRegisterPageState();
}

class _AlumniRegisterPageState extends State<AlumniRegisterPage> {
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // create auth account
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      // create basic alumni doc with profileCompleted = false
      await FirebaseFirestore.instance.collection('alumni_users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'batch': _batchController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // sign out to force login flow, optional
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registered! Please login and complete profile.")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlumniLoginPage()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Registration failed");
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              children: [
                const Text("Alumni Register", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _batchController, decoration: const InputDecoration(labelText: "Batch (e.g. 2020)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                TextField(controller: _mobileController, decoration: const InputDecoration(labelText: "Mobile No", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Register"),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlumniLoginPage())),
                  child: const Text("Already registered? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
