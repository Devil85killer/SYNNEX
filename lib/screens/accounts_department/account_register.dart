import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_textfield.dart';

class AccountRegisterPage extends StatefulWidget {
  const AccountRegisterPage({Key? key}) : super(key: key);
  @override
  State<AccountRegisterPage> createState() => _AccountRegisterPageState();
}

class _AccountRegisterPageState extends State<AccountRegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> registerAccount() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('accounts_department') // <-- fixed collection name
          .doc(uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'profileCompleted': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please log in.")),
      );

      Navigator.pushReplacementNamed(context, '/account_login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRegisterPage(
      title: "Accounts Department Registration",
      onPressed: registerAccount,
      isLoading: _isLoading,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      buttonText: "Register",
      linkText: "Already have an account? Login",
      onLinkPressed: () => Navigator.pushReplacementNamed(context, '/account_login'),
    );
  }

  Widget _buildRegisterPage({
    required String title,
    required VoidCallback onPressed,
    required bool isLoading,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required String buttonText,
    required String linkText,
    required VoidCallback onLinkPressed,
  }) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  CommonTextField(controller: nameController, label: "Full Name", icon: Icons.person),
                  const SizedBox(height: 12),
                  CommonTextField(controller: emailController, label: "Email", icon: Icons.email),
                  const SizedBox(height: 12),
                  CommonTextField(controller: passwordController, label: "Password", icon: Icons.lock, isPassword: true),
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(buttonText, style: const TextStyle(fontSize: 18)),
                        ),
                  TextButton(onPressed: onLinkPressed, child: Text(linkText)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
