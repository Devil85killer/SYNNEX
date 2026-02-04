import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_dashboard.dart';
import '../../widgets/common_textfield.dart';

class AccountLogin extends StatefulWidget {
  const AccountLogin({Key? key}) : super(key: key);
  @override
  State<AccountLogin> createState() => _AccountLoginState();
}

class _AccountLoginState extends State<AccountLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void loginAccount() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountDashboard()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildAuthPage(
      title: "Accounts Department Login",
      onPressed: loginAccount,
      isLoading: _isLoading,
      emailController: _emailController,
      passwordController: _passwordController,
      buttonText: "Login",
      linkText: "Don't have an account? Register",
      onLinkPressed: () => Navigator.pushNamed(context, '/account_register'),
    );
  }

  // ✅ Helper function (copy from teacher)
  Widget _buildAuthPage({
    required String title,
    required VoidCallback onPressed,
    required bool isLoading,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
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
